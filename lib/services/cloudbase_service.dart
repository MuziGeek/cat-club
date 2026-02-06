import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/cloudbase_config.dart';
import '../core/exceptions/cloudbase_exception.dart';
import '../data/datasources/cloudbase_rest_client.dart';
import '../data/mappers/user_mapper.dart';
import '../data/mappers/pet_mapper.dart';
import '../data/models/achievement_model.dart';
import '../data/models/pet_model.dart';
import '../data/models/user_model.dart';
import '../data/repositories/achievement_repository_impl.dart';
import '../data/repositories/pet_repository_impl.dart';
import '../data/repositories/user_repository_impl.dart';
import '../domain/repositories/achievement_repository.dart';
import '../domain/repositories/pet_repository.dart';
import '../domain/repositories/user_repository.dart';
import 'cloudbase_auth_http_service.dart';

/// CloudBase REST Client Provider
final cloudbaseRestClientProvider = Provider<CloudbaseRestClient>((ref) {
  final authService = ref.watch(cloudbaseAuthServiceProvider);
  return CloudbaseRestClient(authService);
});

/// User Repository Provider
final userRepositoryProvider = Provider<UserRepository>((ref) {
  final client = ref.watch(cloudbaseRestClientProvider);
  return UserRepositoryImpl(client);
});

/// Pet Repository Provider
final petRepositoryProvider = Provider<PetRepository>((ref) {
  final client = ref.watch(cloudbaseRestClientProvider);
  return PetRepositoryImpl(client);
});

/// Achievement Repository Provider
final achievementRepositoryProvider = Provider<AchievementRepository>((ref) {
  final client = ref.watch(cloudbaseRestClientProvider);
  final userRepo = ref.watch(userRepositoryProvider);
  return AchievementRepositoryImpl(client, userRepo);
});

/// CloudBase 数据库服务 Provider
final cloudbaseServiceProvider = Provider<CloudbaseService>((ref) {
  final userRepo = ref.watch(userRepositoryProvider);
  final petRepo = ref.watch(petRepositoryProvider);
  final achievementRepo = ref.watch(achievementRepositoryProvider);
  return CloudbaseService(userRepo, petRepo, achievementRepo);
});

/// CloudBase 数据库服务 Facade
///
/// 保持原有 API 兼容性，内部委托给 Repository 实现
/// 遵循 SOLID 原则重构后的统一入口
class CloudbaseService {
  final UserRepository _userRepo;
  final PetRepository _petRepo;
  final AchievementRepository _achievementRepo;

  CloudbaseService(this._userRepo, this._petRepo, this._achievementRepo);

  // ==================== 用户相关 ====================

  /// 创建用户
  Future<void> createUser(UserModel user) async {
    final result = await _userRepo.createUser(user);
    result.fold(
      onSuccess: (_) => debugPrint('[CloudBase DB] 用户创建成功: ${user.id}'),
      onFailure: (e) => throw e,
    );
  }

  /// 获取用户
  Future<UserModel?> getUser(String userId) async {
    final result = await _userRepo.getUser(userId);
    return result.fold(
      onSuccess: (user) {
        if (user != null) {
          debugPrint('[CloudBase DB] getUser 成功, coins=${user.coins}');
        }
        return user;
      },
      onFailure: (e) {
        debugPrint('[CloudBase DB] 获取用户失败: $e');
        return null;
      },
    );
  }

  /// 确保用户存在（不存在则创建）
  Future<UserModel> ensureUserExists(String userId) async {
    final result = await _userRepo.ensureUserExists(userId);
    return result.fold(
      onSuccess: (user) {
        debugPrint('[CloudBase DB] 用户已就绪: ${user.id}');
        return user;
      },
      onFailure: (e) {
        debugPrint('[CloudBase DB] ensureUserExists 失败: $e');
        throw e;
      },
    );
  }

  /// 更新用户
  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    final result = await _userRepo.updateUser(userId, data);
    result.fold(
      onSuccess: (_) => debugPrint('[CloudBase DB] 用户更新成功: $userId'),
      onFailure: (e) {
        debugPrint('[CloudBase DB] 更新用户失败: $e');
        throw e;
      },
    );
  }

  /// 用户数据流
  Stream<UserModel?> userStream(String userId) {
    return _userRepo.userStream(userId);
  }

  /// 更新用户货币
  Future<void> updateUserCurrency(
    String userId, {
    int? coins,
    int? diamonds,
  }) async {
    final result = await _userRepo.updateCurrency(
      userId,
      coinsChange: coins,
      diamondsChange: diamonds,
    );
    result.fold(
      onSuccess: (_) => debugPrint('[CloudBase DB] 用户货币更新成功: $userId'),
      onFailure: (e) {
        debugPrint('[CloudBase DB] 更新用户货币失败: $e');
        throw e;
      },
    );
  }

  // ==================== 宠物相关 ====================

  /// 创建宠物
  Future<String> createPet(PetModel pet) async {
    final result = await _petRepo.createPet(pet);
    return result.fold(
      onSuccess: (petId) {
        debugPrint('[CloudBase DB] 宠物创建成功: $petId');
        return petId;
      },
      onFailure: (e) {
        debugPrint('[CloudBase DB] 创建宠物失败: $e');
        throw e;
      },
    );
  }

  /// 获取宠物
  Future<PetModel?> getPet(String petId) async {
    final result = await _petRepo.getPet(petId);
    return result.fold(
      onSuccess: (pet) => pet,
      onFailure: (e) {
        debugPrint('[CloudBase DB] 获取宠物失败: $e');
        return null;
      },
    );
  }

  /// 更新宠物
  Future<void> updatePet(String petId, Map<String, dynamic> data) async {
    final result = await _petRepo.updatePet(petId, data);
    result.fold(
      onSuccess: (_) => debugPrint('[CloudBase DB] 宠物更新成功: $petId'),
      onFailure: (e) {
        debugPrint('[CloudBase DB] 更新宠物失败: $e');
        throw e;
      },
    );
  }

  /// 删除宠物
  Future<void> deletePet(String petId) async {
    final result = await _petRepo.deletePet(petId);
    result.fold(
      onSuccess: (_) => debugPrint('[CloudBase DB] 宠物删除成功: $petId'),
      onFailure: (e) {
        debugPrint('[CloudBase DB] 删除宠物失败: $e');
        throw e;
      },
    );
  }

  /// 用户宠物列表流
  Stream<List<PetModel>> userPetsStream(String userId) {
    return _petRepo.userPetsStream(userId);
  }

  /// 单个宠物数据流
  Stream<PetModel?> petStream(String petId) {
    return _petRepo.petStream(petId);
  }

  // ==================== 关联操作 ====================

  /// 添加宠物到用户
  Future<void> addPetToUser(String userId, String petId) async {
    final result = await _userRepo.addPetToUser(userId, petId);
    result.fold(
      onSuccess: (_) => debugPrint('[CloudBase DB] 添加宠物到用户成功'),
      onFailure: (e) {
        debugPrint('[CloudBase DB] 添加宠物到用户失败: $e');
        throw e;
      },
    );
  }

  /// 从用户移除宠物
  Future<void> removePetFromUser(String userId, String petId) async {
    final result = await _userRepo.removePetFromUser(userId, petId);
    result.fold(
      onSuccess: (_) => debugPrint('[CloudBase DB] 从用户移除宠物成功'),
      onFailure: (e) {
        debugPrint('[CloudBase DB] 从用户移除宠物失败: $e');
        throw e;
      },
    );
  }

  // ==================== 背包操作 ====================

  /// 获取用户背包
  Future<Map<String, int>> getUserInventory(String userId) async {
    final result = await _userRepo.getInventory(userId);
    return result.fold(
      onSuccess: (inventory) => inventory,
      onFailure: (e) {
        debugPrint('[CloudBase DB] 获取背包失败: $e');
        return {};
      },
    );
  }

  /// 使用道具
  Future<bool> useInventoryItem(String userId, String itemId) async {
    final result = await _userRepo.useItem(userId, itemId);
    return result.fold(
      onSuccess: (success) {
        if (success) debugPrint('[CloudBase DB] 使用道具成功: $itemId');
        return success;
      },
      onFailure: (e) {
        debugPrint('[CloudBase DB] 使用道具失败: $e');
        return false;
      },
    );
  }

  /// 添加道具
  Future<void> addInventoryItem(String userId, String itemId, int count) async {
    final result = await _userRepo.addItem(userId, itemId, count);
    result.fold(
      onSuccess: (_) => debugPrint('[CloudBase DB] 添加道具成功: $itemId x$count'),
      onFailure: (e) {
        debugPrint('[CloudBase DB] 添加道具失败: $e');
        throw e;
      },
    );
  }

  /// 设置初始背包
  Future<void> setInitialInventory(String userId, Map<String, int> inventory) async {
    final result = await _userRepo.setInitialInventory(userId, inventory);
    result.fold(
      onSuccess: (_) => debugPrint('[CloudBase DB] 设置初始背包成功'),
      onFailure: (e) {
        debugPrint('[CloudBase DB] 设置初始背包失败: $e');
        throw e;
      },
    );
  }

  // ==================== 宠物状态更新 ====================

  /// 更新宠物状态
  Future<void> updatePetStatus(
    String petId, {
    int? happiness,
    int? hunger,
    int? energy,
    int? health,
    int? cleanliness,
  }) async {
    final result = await _petRepo.updateStatus(
      petId,
      happiness: happiness,
      hunger: hunger,
      energy: energy,
      health: health,
      cleanliness: cleanliness,
    );
    result.fold(
      onSuccess: (_) => debugPrint('[CloudBase DB] 更新宠物状态成功'),
      onFailure: (e) {
        debugPrint('[CloudBase DB] 更新宠物状态失败: $e');
        throw e;
      },
    );
  }

  /// 更新宠物成长数据
  Future<void> updatePetStats(
    String petId, {
    int? experienceGain,
    int? intimacyGain,
    bool incrementFeedings = false,
    bool incrementInteractions = false,
  }) async {
    final result = await _petRepo.updateStats(
      petId,
      experienceGain: experienceGain,
      intimacyGain: intimacyGain,
      incrementFeedings: incrementFeedings,
      incrementInteractions: incrementInteractions,
    );
    result.fold(
      onSuccess: (_) => debugPrint('[CloudBase DB] 更新宠物成长成功'),
      onFailure: (e) {
        debugPrint('[CloudBase DB] 更新宠物成长失败: $e');
        throw e;
      },
    );
  }

  // ==================== 成就系统 ====================

  /// 获取用户成就进度流
  Stream<List<UserAchievement>> userAchievementsStream(String userId) {
    return _achievementRepo.userAchievementsStream(userId);
  }

  /// 获取用户所有成就进度
  Future<List<UserAchievement>> getUserAchievements(String userId) async {
    final result = await _achievementRepo.getUserAchievements(userId);
    return result.fold(
      onSuccess: (list) => list,
      onFailure: (e) {
        debugPrint('[CloudBase DB] 获取成就失败: $e');
        return [];
      },
    );
  }

  /// 解锁成就
  Future<void> unlockAchievement({
    required String userId,
    required String achievementId,
    required int currentValue,
  }) async {
    final result = await _achievementRepo.unlock(
      userId: userId,
      achievementId: achievementId,
      currentValue: currentValue,
    );
    result.fold(
      onSuccess: (_) => debugPrint('[CloudBase DB] 解锁成就成功: $achievementId'),
      onFailure: (e) {
        debugPrint('[CloudBase DB] 解锁成就失败: $e');
        throw e;
      },
    );
  }

  /// 更新成就进度
  Future<void> updateAchievementProgress({
    required String userId,
    required String achievementId,
    required int currentValue,
  }) async {
    final result = await _achievementRepo.updateProgress(
      userId: userId,
      achievementId: achievementId,
      currentValue: currentValue,
    );
    result.fold(
      onSuccess: (_) => debugPrint('[CloudBase DB] 更新成就进度成功: $achievementId = $currentValue'),
      onFailure: (e) {
        debugPrint('[CloudBase DB] 更新成就进度失败: $e');
        throw e;
      },
    );
  }

  /// 领取成就奖励
  Future<void> claimAchievementReward({
    required String userId,
    required String achievementId,
    required AchievementReward reward,
  }) async {
    final result = await _achievementRepo.claimReward(
      userId: userId,
      achievementId: achievementId,
      reward: reward,
    );
    result.fold(
      onSuccess: (_) => debugPrint('[CloudBase DB] 领取成就奖励成功: $achievementId'),
      onFailure: (e) {
        debugPrint('[CloudBase DB] 领取成就奖励失败: $e');
        throw e;
      },
    );
  }

  // ==================== 统计相关 ====================

  /// 获取用户统计数据
  Future<Map<String, int>?> getUserStats(String userId) async {
    final user = await getUser(userId);
    if (user == null) return null;

    return {
      'petCount': user.petIds.length,
      'consecutiveDays': user.consecutiveDays,
      'itemTypeCount': user.inventory.length,
      'petOwned': user.petIds.length,
    };
  }

  /// 增加用户统计计数
  Future<void> incrementUserStat(String userId, String statName, {int value = 1}) async {
    // 简化实现
    debugPrint('[CloudBase DB] incrementUserStat: $statName +$value (simplified)');
  }
}

/// CloudBase 认证服务 Provider
final cloudbaseAuthServiceProvider = Provider<CloudbaseAuthHttpService>((ref) {
  return CloudbaseAuthHttpService();
});
