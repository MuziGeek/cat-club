import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/achievement_definitions.dart';
import '../data/models/achievement_model.dart';
import '../services/cloudbase_service.dart';
import 'auth_provider.dart';
import 'user_provider.dart';

/// 用户成就进度流 Provider
final userAchievementsProvider = StreamProvider<List<UserAchievement>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);

  final cloudbaseService = ref.watch(cloudbaseServiceProvider);
  return cloudbaseService.userAchievementsStream(userId);
});

/// 成就统计信息 Provider
final achievementStatsProvider = Provider<AchievementStats>((ref) {
  final userAchievements = ref.watch(userAchievementsProvider).valueOrNull ?? [];
  final totalCount = AchievementDefinitions.totalCount;
  final unlockedCount = userAchievements.where((a) => a.isUnlocked).length;
  final claimableCount = userAchievements.where((a) => a.canClaimReward).length;

  return AchievementStats(
    totalCount: totalCount,
    unlockedCount: unlockedCount,
    claimableCount: claimableCount,
  );
});

/// 成就统计数据
class AchievementStats {
  final int totalCount;
  final int unlockedCount;
  final int claimableCount;

  const AchievementStats({
    required this.totalCount,
    required this.unlockedCount,
    required this.claimableCount,
  });

  double get progressPercent =>
      totalCount > 0 ? unlockedCount / totalCount : 0;
}

/// 成就状态管理 Notifier Provider
final achievementNotifierProvider =
    StateNotifierProvider<AchievementNotifier, AsyncValue<void>>((ref) {
  return AchievementNotifier(ref);
});

/// 成就状态管理 Notifier
class AchievementNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  AchievementNotifier(this._ref) : super(const AsyncValue.data(null));

  CloudbaseService get _cloudbaseService =>
      _ref.read(cloudbaseServiceProvider);

  /// 检查并更新成就进度
  ///
  /// 根据触发类型和当前值检查是否有新成就解锁
  /// 返回新解锁的成就列表
  Future<List<AchievementModel>> checkAndUpdateProgress({
    required String userId,
    required AchievementType type,
    required int currentValue,
  }) async {
    final unlockedAchievements = <AchievementModel>[];

    try {
      // 获取该类型的所有成就
      final achievements = AchievementDefinitions.getByType(type);

      // 获取用户当前成就进度
      final userAchievements =
          await _cloudbaseService.getUserAchievements(userId);
      final userAchievementMap = {
        for (final ua in userAchievements) ua.achievementId: ua
      };

      for (final achievement in achievements) {
        final userAchievement = userAchievementMap[achievement.id];

        // 如果已解锁，跳过
        if (userAchievement?.isUnlocked == true) continue;

        // 检查是否达成目标
        if (currentValue >= achievement.targetValue) {
          // 解锁成就
          await _cloudbaseService.unlockAchievement(
            userId: userId,
            achievementId: achievement.id,
            currentValue: currentValue,
          );
          unlockedAchievements.add(achievement);
        } else {
          // 更新进度
          await _cloudbaseService.updateAchievementProgress(
            userId: userId,
            achievementId: achievement.id,
            currentValue: currentValue,
          );
        }
      }

      // 刷新用户成就数据
      _ref.invalidate(userAchievementsProvider);

      return unlockedAchievements;
    } catch (e) {
      print('[ACHIEVEMENT] 检查成就失败: $e');
      return [];
    }
  }

  /// 领取成就奖励
  Future<bool> claimReward({
    required String userId,
    required String achievementId,
  }) async {
    state = const AsyncValue.loading();

    try {
      final achievement = AchievementDefinitions.getById(achievementId);
      if (achievement == null) {
        state = AsyncValue.error('成就不存在', StackTrace.current);
        return false;
      }

      // 检查是否已解锁且未领取
      final userAchievements =
          await _cloudbaseService.getUserAchievements(userId);
      final userAchievement = userAchievements.firstWhere(
        (ua) => ua.achievementId == achievementId,
        orElse: () => UserAchievement(achievementId: achievementId),
      );

      if (!userAchievement.isUnlocked) {
        state = AsyncValue.error('成就尚未解锁', StackTrace.current);
        return false;
      }

      if (userAchievement.isRewardClaimed) {
        state = AsyncValue.error('奖励已领取', StackTrace.current);
        return false;
      }

      // 发放奖励
      await _cloudbaseService.claimAchievementReward(
        userId: userId,
        achievementId: achievementId,
        reward: achievement.reward,
      );

      // 刷新相关数据
      _ref.invalidate(userAchievementsProvider);
      _ref.invalidate(currentUserProvider);

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// 批量检查所有类型的成就
  ///
  /// 用于应用启动时同步检查
  Future<List<AchievementModel>> checkAllAchievements(String userId) async {
    final allUnlocked = <AchievementModel>[];

    try {
      // 获取用户统计数据
      final stats = await _cloudbaseService.getUserStats(userId);
      if (stats == null) return [];

      // 检查各类型成就
      final checks = [
        (AchievementType.petCount, stats['petCount'] ?? 0),
        (AchievementType.feedCount, stats['feedCount'] ?? 0),
        (AchievementType.playCount, stats['playCount'] ?? 0),
        (AchievementType.cleanCount, stats['cleanCount'] ?? 0),
        (AchievementType.level, stats['maxLevel'] ?? 1),
        (AchievementType.intimacy, stats['maxIntimacy'] ?? 0),
        (AchievementType.checkInStreak, stats['checkInStreak'] ?? 0),
        (AchievementType.checkInTotal, stats['checkInTotal'] ?? 0),
        (AchievementType.itemTypeCount, stats['itemTypeCount'] ?? 0),
        (AchievementType.petOwned, stats['petOwned'] ?? 0),
      ];

      for (final (type, value) in checks) {
        final unlocked = await checkAndUpdateProgress(
          userId: userId,
          type: type,
          currentValue: value,
        );
        allUnlocked.addAll(unlocked);
      }

      return allUnlocked;
    } catch (e) {
      print('[ACHIEVEMENT] 批量检查成就失败: $e');
      return [];
    }
  }
}

/// 成就详情 Provider（带用户进度）
final achievementWithProgressProvider =
    Provider.family<AchievementWithProgress?, String>((ref, achievementId) {
  final achievement = AchievementDefinitions.getById(achievementId);
  if (achievement == null) return null;

  final userAchievements = ref.watch(userAchievementsProvider).valueOrNull ?? [];
  final userProgress = userAchievements.firstWhere(
    (ua) => ua.achievementId == achievementId,
    orElse: () => UserAchievement(achievementId: achievementId),
  );

  return AchievementWithProgress(
    achievement: achievement,
    userProgress: userProgress,
  );
});

/// 成就与用户进度组合
class AchievementWithProgress {
  final AchievementModel achievement;
  final UserAchievement userProgress;

  const AchievementWithProgress({
    required this.achievement,
    required this.userProgress,
  });

  bool get isUnlocked => userProgress.isUnlocked;
  bool get canClaimReward => userProgress.canClaimReward;
  int get currentValue => userProgress.currentValue;
  int get targetValue => achievement.targetValue;

  double get progressPercent =>
      targetValue > 0 ? (currentValue / targetValue).clamp(0.0, 1.0) : 0;
}
