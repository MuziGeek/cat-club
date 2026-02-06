import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/exceptions/cloudbase_exception.dart';
import '../../data/datasources/cloudbase_rest_client.dart';
import '../../data/mappers/achievement_mapper.dart';
import '../../data/models/achievement_model.dart';
import '../../domain/repositories/achievement_repository.dart';
import '../../domain/repositories/user_repository.dart';

/// 成就仓库实现
///
/// 使用 CloudBase REST Client 实现成就数据操作
class AchievementRepositoryImpl implements AchievementRepository {
  final CloudbaseRestClient _client;
  final UserRepository _userRepo;

  AchievementRepositoryImpl(this._client, this._userRepo);

  static const String _table = 'user_achievements';

  @override
  Future<Result<List<UserAchievement>>> getUserAchievements(
    String userId,
  ) async {
    debugPrint('[AchievementRepo] getUserAchievements: $userId');

    final result = await _client.getList(
      _table,
      filters: {'userId': 'eq.$userId'},
    );

    return result.map((list) {
      return list.map((data) {
        final id = data['id'] as String? ?? '';
        return AchievementMapper.fromCloudbase(data, id);
      }).toList();
    });
  }

  @override
  Stream<List<UserAchievement>> userAchievementsStream(String userId) {
    late StreamController<List<UserAchievement>> controller;
    Timer? pollTimer;

    controller = StreamController<List<UserAchievement>>(
      onListen: () {
        getUserAchievements(userId).then((result) {
          if (!controller.isClosed) {
            controller.add(result.dataOrNull ?? []);
          }
        });
        pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
          getUserAchievements(userId).then((result) {
            if (!controller.isClosed) {
              controller.add(result.dataOrNull ?? []);
            }
          });
        });
      },
      onCancel: () {
        pollTimer?.cancel();
      },
    );

    return controller.stream;
  }

  @override
  Future<Result<void>> updateProgress({
    required String userId,
    required String achievementId,
    required int currentValue,
  }) async {
    debugPrint('[AchievementRepo] updateProgress: $achievementId = $currentValue');

    final docId = '${userId}_$achievementId';

    // 检查是否已存在
    final existingResult = await _client.getOne(_table, docId);
    if (existingResult.isFailure) {
      return Failure(existingResult.exceptionOrNull!);
    }

    final existing = existingResult.dataOrNull;

    if (existing == null) {
      // 创建新记录
      final data = AchievementMapper.toCloudbase(
        odId: docId,
        oderId: userId,
        achievementId: achievementId,
        currentValue: currentValue,
        isUnlocked: false,
      );
      final createResult = await _client.create(_table, data);
      return createResult.map((_) {});
    } else if (existing['isUnlocked'] != true &&
        existing['isUnlocked'] != 1) {
      // 更新进度（仅未解锁时）
      return _client.update(
        _table,
        docId,
        AchievementMapper.toProgressUpdate(currentValue),
      );
    }

    return const Success(null);
  }

  @override
  Future<Result<void>> unlock({
    required String userId,
    required String achievementId,
    required int currentValue,
  }) async {
    debugPrint('[AchievementRepo] unlock: $achievementId');

    final docId = '${userId}_$achievementId';

    // 检查是否已存在
    final existingResult = await _client.getOne(_table, docId);
    if (existingResult.isFailure) {
      return Failure(existingResult.exceptionOrNull!);
    }

    final existing = existingResult.dataOrNull;

    if (existing == null) {
      // 创建新记录（已解锁状态）
      final data = AchievementMapper.toCloudbase(
        odId: docId,
        oderId: userId,
        achievementId: achievementId,
        currentValue: currentValue,
        isUnlocked: true,
        unlockedAt: DateTime.now(),
      );
      final createResult = await _client.create(_table, data);
      return createResult.map((_) {});
    } else {
      // 更新为已解锁
      return _client.update(
        _table,
        docId,
        AchievementMapper.toUnlockUpdate(currentValue),
      );
    }
  }

  @override
  Future<Result<void>> claimReward({
    required String userId,
    required String achievementId,
    required AchievementReward reward,
  }) async {
    debugPrint('[AchievementRepo] claimReward: $achievementId');

    final docId = '${userId}_$achievementId';

    // 验证成就状态
    final existingResult = await _client.getOne(_table, docId);
    if (existingResult.isFailure) {
      return Failure(existingResult.exceptionOrNull!);
    }

    final existing = existingResult.dataOrNull;
    if (existing == null) {
      return const Failure(NotFoundException('Achievement not found'));
    }

    final isUnlocked = existing['isUnlocked'] == true || existing['isUnlocked'] == 1;
    final isClaimed = existing['isRewardClaimed'] == true || existing['isRewardClaimed'] == 1;

    if (!isUnlocked) {
      return const Failure(ValidationException('Achievement not unlocked'));
    }
    if (isClaimed) {
      return const Failure(ValidationException('Reward already claimed'));
    }

    // 更新用户货币和背包
    final userResult = await _userRepo.getUser(userId);
    if (userResult.isFailure) {
      return Failure(userResult.exceptionOrNull!);
    }

    final user = userResult.dataOrNull;
    if (user == null) {
      return const Failure(NotFoundException('User not found'));
    }

    // 计算新值
    final newCoins = user.coins + reward.coins;
    final newDiamonds = user.diamonds + reward.diamonds;
    final newInventory = Map<String, int>.from(user.inventory);
    for (final entry in reward.items.entries) {
      newInventory[entry.key] = (newInventory[entry.key] ?? 0) + entry.value;
    }

    // 更新用户
    final updateUserResult = await _userRepo.updateUser(userId, {
      'coins': newCoins,
      'diamonds': newDiamonds,
      'inventory': jsonEncode(newInventory),
    });
    if (updateUserResult.isFailure) {
      return updateUserResult;
    }

    // 标记奖励已领取
    return _client.update(_table, docId, AchievementMapper.toClaimUpdate());
  }
}
