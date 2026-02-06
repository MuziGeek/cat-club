import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cloudbase_service.dart';

/// 签到服务 Provider
final checkInServiceProvider = Provider<CheckInService>((ref) {
  final cloudbaseService = ref.watch(cloudbaseServiceProvider);
  return CheckInService(cloudbaseService);
});

/// 签到奖励配置
class CheckInReward {
  final int coins;
  final int diamonds;
  final Map<String, int> items;
  final String description;

  const CheckInReward({
    this.coins = 0,
    this.diamonds = 0,
    this.items = const {},
    this.description = '',
  });

  /// 是否有道具奖励
  bool get hasItems => items.isNotEmpty;
}

/// 签到结果
class CheckInResult {
  final bool success;
  final int consecutiveDays;
  final CheckInReward reward;
  final String? errorMessage;

  const CheckInResult({
    required this.success,
    required this.consecutiveDays,
    required this.reward,
    this.errorMessage,
  });

  factory CheckInResult.failure(String message) {
    return CheckInResult(
      success: false,
      consecutiveDays: 0,
      reward: const CheckInReward(),
      errorMessage: message,
    );
  }
}

/// 每日签到服务 (CloudBase 版本)
class CheckInService {
  final CloudbaseService _cloudbaseService;

  CheckInService(this._cloudbaseService);

  /// 签到奖励配置（按连续天数）
  static const Map<int, CheckInReward> _rewardConfig = {
    1: CheckInReward(coins: 50, description: '第1天'),
    2: CheckInReward(coins: 80, description: '第2天'),
    3: CheckInReward(coins: 100, items: {'food_fish': 2}, description: '第3天'),
    4: CheckInReward(coins: 120, description: '第4天'),
    5: CheckInReward(coins: 150, items: {'food_treat': 2}, description: '第5天'),
    6: CheckInReward(coins: 180, description: '第6天'),
    7: CheckInReward(
      coins: 300,
      diamonds: 10,
      items: {'food_premium_fish': 1, 'clean_brush': 1},
      description: '第7天 - 周奖励',
    ),
  };

  /// 获取指定天数的奖励
  CheckInReward getRewardForDay(int day) {
    // 循环 7 天奖励
    final dayInCycle = ((day - 1) % 7) + 1;
    return _rewardConfig[dayInCycle] ?? const CheckInReward(coins: 50);
  }

  /// 获取所有 7 天奖励配置
  List<CheckInReward> get weeklyRewards {
    return List.generate(7, (index) => _rewardConfig[index + 1]!);
  }

  /// 执行签到
  Future<CheckInResult> checkIn(String userId) async {
    debugPrint('[CHECK_IN_SERVICE] 开始签到, userId=$userId');

    try {
      // 获取用户数据
      final user = await _cloudbaseService.getUser(userId);
      if (user == null) {
        debugPrint('[CHECK_IN_SERVICE] 用户不存在');
        return CheckInResult.failure('用户不存在');
      }

      final lastSignInDate = user.lastSignInDate;
      final currentDays = user.consecutiveDays;
      final currentCoins = user.coins;
      debugPrint('[CHECK_IN_SERVICE] 当前状态: consecutiveDays=$currentDays, coins=$currentCoins');

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // 检查是否已签到
      if (lastSignInDate != null) {
        final lastDate = DateTime(
          lastSignInDate.year,
          lastSignInDate.month,
          lastSignInDate.day,
        );

        if (lastDate == today) {
          return CheckInResult.failure('今日已签到');
        }

        // 计算新的连续天数
        final yesterday = today.subtract(const Duration(days: 1));
        final isConsecutive = lastDate == yesterday;

        final newDays = isConsecutive ? currentDays + 1 : 1;
        final reward = getRewardForDay(newDays);
        debugPrint('[CHECK_IN_SERVICE] 计算奖励: newDays=$newDays, reward.coins=${reward.coins}');

        // 更新签到数据
        final updates = <String, dynamic>{
          'lastSignInDate': now.toIso8601String(),
          'consecutiveDays': newDays,
        };

        debugPrint('[CHECK_IN_SERVICE] 正在更新 CloudBase: $updates');
        await _cloudbaseService.updateUser(userId, updates);

        // 更新货币
        await _cloudbaseService.updateUserCurrency(
          userId,
          coins: reward.coins,
          diamonds: reward.diamonds > 0 ? reward.diamonds : null,
        );

        // 添加道具奖励
        for (final entry in reward.items.entries) {
          await _cloudbaseService.addInventoryItem(userId, entry.key, entry.value);
        }

        debugPrint('[CHECK_IN_SERVICE] CloudBase 更新完成');

        return CheckInResult(
          success: true,
          consecutiveDays: newDays,
          reward: reward,
        );
      } else {
        // 首次签到
        const reward = CheckInReward(coins: 100, description: '首次签到奖励');

        await _cloudbaseService.updateUser(userId, {
          'lastSignInDate': now.toIso8601String(),
          'consecutiveDays': 1,
        });

        await _cloudbaseService.updateUserCurrency(userId, coins: reward.coins);

        return const CheckInResult(
          success: true,
          consecutiveDays: 1,
          reward: reward,
        );
      }
    } catch (e) {
      debugPrint('[CHECK_IN_SERVICE] 签到失败: $e');
      return CheckInResult.failure('签到失败: $e');
    }
  }

  /// 检查今日是否已签到
  Future<bool> hasCheckedInToday(String userId) async {
    final user = await _cloudbaseService.getUser(userId);
    if (user == null) return false;

    final lastSignInDate = user.lastSignInDate;
    if (lastSignInDate == null) return false;

    final now = DateTime.now();
    return lastSignInDate.year == now.year &&
        lastSignInDate.month == now.month &&
        lastSignInDate.day == now.day;
  }

  /// 获取当前连续签到天数
  Future<int> getConsecutiveDays(String userId) async {
    final user = await _cloudbaseService.getUser(userId);
    if (user == null) return 0;
    return user.consecutiveDays;
  }

  /// [调试用] 重置签到状态
  Future<void> resetCheckIn(String userId) async {
    await _cloudbaseService.updateUser(userId, {
      'lastSignInDate': null,
      'consecutiveDays': 0,
    });
  }
}
