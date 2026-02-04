import 'package:cloudbase_ce/cloudbase_ce.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/cloudbase_config.dart';
import '../data/models/pet_model.dart';
import '../data/models/user_model.dart';

/// CloudBase 数据库服务 Provider
final cloudbaseServiceProvider = Provider<CloudbaseService>((ref) {
  return CloudbaseService();
});

/// CloudBase 数据库服务
///
/// 封装腾讯云 CloudBase 数据库操作
class CloudbaseService {
  CloudBaseCore? _core;
  CloudBaseDatabase? _db;
  bool _isInitialized = false;

  /// 确保已初始化
  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;

    try {
      _core = CloudBaseCore.init({
        'env': CloudbaseConfig.envId,
        'timeout': CloudbaseConfig.timeout,
      });
      _db = CloudBaseDatabase(_core!);
      _isInitialized = true;
      debugPrint('[CloudBase DB] 初始化成功');
    } catch (e) {
      debugPrint('[CloudBase DB] 初始化失败: $e');
      rethrow;
    }
  }

  /// 获取数据库实例
  Future<CloudBaseDatabase> get database async {
    await _ensureInitialized();
    return _db!;
  }

  // ==================== 用户相关 ====================

  /// 创建用户
  Future<void> createUser(UserModel user) async {
    await _ensureInitialized();
    try {
      final data = user.toJson();
      await _db!.collection('users').doc(user.id).set(data);
      debugPrint('[CloudBase DB] 用户创建成功: ${user.id}');
    } catch (e) {
      debugPrint('[CloudBase DB] 创建用户失败: $e');
      rethrow;
    }
  }

  /// 获取用户
  Future<UserModel?> getUser(String userId) async {
    await _ensureInitialized();
    try {
      debugPrint('[CloudBase DB] getUser 开始, userId=$userId');
      final res = await _db!.collection('users').doc(userId).get();
      if (res.data == null || (res.data as List).isEmpty) {
        debugPrint('[CloudBase DB] 用户不存在: $userId');
        return null;
      }
      final data = (res.data as List).first as Map<String, dynamic>;
      debugPrint('[CloudBase DB] getUser 成功, coins=${data['coins']}');
      return UserModel.fromJson(data);
    } catch (e) {
      debugPrint('[CloudBase DB] 获取用户失败: $e');
      return null;
    }
  }

  /// 更新用户
  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await _ensureInitialized();
    try {
      await _db!.collection('users').doc(userId).update(data);
      debugPrint('[CloudBase DB] 用户更新成功: $userId');
    } catch (e) {
      debugPrint('[CloudBase DB] 更新用户失败: $e');
      rethrow;
    }
  }

  /// 用户数据流
  Stream<UserModel?> userStream(String userId) async* {
    await _ensureInitialized();
    // CloudBase watch 实现
    final watcher = _db!.collection('users').doc(userId).watch();
    await for (final snapshot in watcher) {
      if (snapshot.docs.isEmpty) {
        yield null;
      } else {
        final data = snapshot.docs.first.data as Map<String, dynamic>;
        yield UserModel.fromJson(data);
      }
    }
  }

  // ==================== 宠物相关 ====================

  /// 创建宠物
  Future<String> createPet(PetModel pet) async {
    await _ensureInitialized();
    try {
      final res = await _db!.collection('pets').add(pet.toJson());
      final petId = res.id;
      debugPrint('[CloudBase DB] 宠物创建成功: $petId');
      return petId;
    } catch (e) {
      debugPrint('[CloudBase DB] 创建宠物失败: $e');
      rethrow;
    }
  }

  /// 获取宠物
  Future<PetModel?> getPet(String petId) async {
    await _ensureInitialized();
    try {
      final res = await _db!.collection('pets').doc(petId).get();
      if (res.data == null || (res.data as List).isEmpty) {
        return null;
      }
      final data = (res.data as List).first as Map<String, dynamic>;
      return PetModel.fromJson({...data, 'id': petId});
    } catch (e) {
      debugPrint('[CloudBase DB] 获取宠物失败: $e');
      return null;
    }
  }

  /// 更新宠物
  Future<void> updatePet(String petId, Map<String, dynamic> data) async {
    await _ensureInitialized();
    try {
      await _db!.collection('pets').doc(petId).update(data);
      debugPrint('[CloudBase DB] 宠物更新成功: $petId');
    } catch (e) {
      debugPrint('[CloudBase DB] 更新宠物失败: $e');
      rethrow;
    }
  }

  /// 删除宠物
  Future<void> deletePet(String petId) async {
    await _ensureInitialized();
    try {
      await _db!.collection('pets').doc(petId).remove();
      debugPrint('[CloudBase DB] 宠物删除成功: $petId');
    } catch (e) {
      debugPrint('[CloudBase DB] 删除宠物失败: $e');
      rethrow;
    }
  }

  /// 用户宠物列表流
  Stream<List<PetModel>> userPetsStream(String userId) async* {
    await _ensureInitialized();
    final watcher = _db!
        .collection('pets')
        .where({'userId': userId})
        .watch();

    await for (final snapshot in watcher) {
      final pets = snapshot.docs.map((doc) {
        final data = doc.data as Map<String, dynamic>;
        return PetModel.fromJson({...data, 'id': doc.id});
      }).toList();
      yield pets;
    }
  }

  /// 单个宠物数据流
  Stream<PetModel?> petStream(String petId) async* {
    await _ensureInitialized();
    final watcher = _db!.collection('pets').doc(petId).watch();

    await for (final snapshot in watcher) {
      if (snapshot.docs.isEmpty) {
        yield null;
      } else {
        final data = snapshot.docs.first.data as Map<String, dynamic>;
        yield PetModel.fromJson({...data, 'id': petId});
      }
    }
  }

  // ==================== 背包相关 ====================

  /// 获取用户背包
  Future<Map<String, int>> getUserInventory(String userId) async {
    await _ensureInitialized();
    try {
      final res = await _db!
          .collection('users')
          .doc(userId)
          .collection('inventory')
          .get();

      final inventory = <String, int>{};
      for (final doc in res.data) {
        final data = doc as Map<String, dynamic>;
        inventory[data['itemId'] as String] = data['quantity'] as int;
      }
      return inventory;
    } catch (e) {
      debugPrint('[CloudBase DB] 获取背包失败: $e');
      return {};
    }
  }

  /// 更新背包道具
  Future<void> updateInventoryItem(
    String userId,
    String itemId,
    int quantity,
  ) async {
    await _ensureInitialized();
    try {
      if (quantity <= 0) {
        await _db!
            .collection('users')
            .doc(userId)
            .collection('inventory')
            .doc(itemId)
            .remove();
      } else {
        await _db!
            .collection('users')
            .doc(userId)
            .collection('inventory')
            .doc(itemId)
            .set({
          'itemId': itemId,
          'quantity': quantity,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('[CloudBase DB] 更新背包失败: $e');
      rethrow;
    }
  }

  // ==================== 成就相关 ====================

  /// 获取用户成就进度
  Future<Map<String, dynamic>> getUserAchievements(String userId) async {
    await _ensureInitialized();
    try {
      final res = await _db!
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .get();

      final achievements = <String, dynamic>{};
      for (final doc in res.data) {
        final data = doc as Map<String, dynamic>;
        achievements[data['achievementId'] as String] = data;
      }
      return achievements;
    } catch (e) {
      debugPrint('[CloudBase DB] 获取成就失败: $e');
      return {};
    }
  }

  /// 更新成就进度
  Future<void> updateAchievementProgress(
    String userId,
    String achievementId,
    Map<String, dynamic> data,
  ) async {
    await _ensureInitialized();
    try {
      await _db!
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .doc(achievementId)
          .set({
        'achievementId': achievementId,
        ...data,
      });
    } catch (e) {
      debugPrint('[CloudBase DB] 更新成就失败: $e');
      rethrow;
    }
  }

  // ==================== 统计相关 ====================

  /// 获取用户统计
  Future<Map<String, int>> getUserStats(String userId) async {
    await _ensureInitialized();
    try {
      final res = await _db!.collection('user_stats').doc(userId).get();
      if (res.data == null || (res.data as List).isEmpty) {
        return {};
      }
      final data = (res.data as List).first as Map<String, dynamic>;
      return data.map((k, v) => MapEntry(k, v as int? ?? 0));
    } catch (e) {
      debugPrint('[CloudBase DB] 获取统计失败: $e');
      return {};
    }
  }

  /// 增加用户统计
  Future<void> incrementUserStat(String userId, String statName) async {
    await _ensureInitialized();
    try {
      final db = _db!;
      final _ = db.command;
      await db.collection('user_stats').doc(userId).update({
        statName: _.inc(1),
      });
    } catch (e) {
      // 如果文档不存在，创建新文档
      try {
        await _db!.collection('user_stats').doc(userId).set({
          statName: 1,
        });
      } catch (e2) {
        debugPrint('[CloudBase DB] 增加统计失败: $e2');
      }
    }
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
    final updates = <String, dynamic>{
      'updatedAt': DateTime.now().toIso8601String(),
      'lastInteractionAt': DateTime.now().toIso8601String(),
    };

    if (happiness != null) updates['status.happiness'] = happiness;
    if (hunger != null) updates['status.hunger'] = hunger;
    if (energy != null) updates['status.energy'] = energy;
    if (health != null) updates['status.health'] = health;
    if (cleanliness != null) updates['status.cleanliness'] = cleanliness;

    await updatePet(petId, updates);
  }

  /// 更新宠物成长数据
  Future<void> updatePetStats(
    String petId, {
    int? experienceGain,
    int? intimacyGain,
    bool incrementFeedings = false,
    bool incrementInteractions = false,
  }) async {
    await _ensureInitialized();
    try {
      final db = _db!;
      final _ = db.command;
      final updates = <String, dynamic>{
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (experienceGain != null && experienceGain > 0) {
        updates['stats.experience'] = _.inc(experienceGain);
      }
      if (intimacyGain != null && intimacyGain > 0) {
        updates['stats.intimacy'] = _.inc(intimacyGain);
      }
      if (incrementFeedings) {
        updates['stats.totalFeedings'] = _.inc(1);
      }
      if (incrementInteractions) {
        updates['stats.totalInteractions'] = _.inc(1);
      }

      await db.collection('pets').doc(petId).update(updates);
    } catch (e) {
      debugPrint('[CloudBase DB] 更新宠物成长失败: $e');
      rethrow;
    }
  }

  /// 添加宠物到用户
  Future<void> addPetToUser(String userId, String petId) async {
    await _ensureInitialized();
    try {
      final _ = _db!.command;
      await _db!.collection('users').doc(userId).update({
        'petIds': _.push([petId]),
      });
    } catch (e) {
      debugPrint('[CloudBase DB] 添加宠物到用户失败: $e');
      rethrow;
    }
  }

  /// 从用户移除宠物
  Future<void> removePetFromUser(String userId, String petId) async {
    await _ensureInitialized();
    try {
      final _ = _db!.command;
      await _db!.collection('users').doc(userId).update({
        'petIds': _.pull(petId),
      });
    } catch (e) {
      debugPrint('[CloudBase DB] 从用户移除宠物失败: $e');
      rethrow;
    }
  }
}
