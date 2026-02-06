import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../config/cloudbase_config.dart';
import '../data/models/achievement_model.dart';
import '../data/models/pet_model.dart';
import '../data/models/user_model.dart';
import 'cloudbase_auth_http_service.dart';

/// CloudBase 数据库服务 Provider
final cloudbaseServiceProvider = Provider<CloudbaseService>((ref) {
  final authService = ref.watch(cloudbaseAuthServiceProvider);
  return CloudbaseService(authService);
});

/// CloudBase 数据库服务 (HTTP API 版本)
///
/// 使用 CloudBase HTTP API 进行数据库操作，兼容 AGP 8.0+
class CloudbaseService {
  final CloudbaseAuthHttpService _authService;

  CloudbaseService(this._authService);

  /// 获取 API 基础 URL
  String get _baseUrl => CloudbaseConfig.apiBaseUrl;

  /// 获取认证 Token
  Future<String> _getAuthToken() async {
    final token = await _authService.getAccessToken();
    if (token == null) {
      // 使用 Publishable Key 作为后备
      return CloudbaseConfig.publishableKey;
    }
    return token;
  }

  /// 通用 HTTP 请求方法
  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
  }) async {
    final token = await _getAuthToken();
    var uri = Uri.parse('$_baseUrl$path');
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    http.Response response;
    switch (method.toUpperCase()) {
      case 'GET':
        response = await http.get(uri, headers: headers);
        break;
      case 'POST':
        response = await http.post(uri, headers: headers, body: jsonEncode(body));
        break;
      case 'PATCH':
        response = await http.patch(uri, headers: headers, body: jsonEncode(body));
        break;
      case 'DELETE':
        response = await http.delete(uri, headers: headers);
        break;
      default:
        throw Exception('Unsupported HTTP method: $method');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      debugPrint('[CloudBase HTTP] Error ${response.statusCode}: ${response.body}');
      throw Exception('CloudBase API error: ${response.statusCode}');
    }
  }

  /// REST API 请求 (用于 MySQL/NoSQL REST 接口)
  Future<List<Map<String, dynamic>>> _restGet(
    String table, {
    Map<String, String>? filters,
    String? select,
    int? limit,
    int? offset,
    String? orderBy,
  }) async {
    final token = await _getAuthToken();
    final queryParams = <String, String>{};
    if (select != null) queryParams['select'] = select;
    if (limit != null) queryParams['limit'] = limit.toString();
    if (offset != null) queryParams['offset'] = offset.toString();
    if (orderBy != null) queryParams['order'] = orderBy;
    if (filters != null) queryParams.addAll(filters);

    var uri = Uri.parse('$_baseUrl/v1/rdb/rest/$table');
    if (queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return [];
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } else {
      debugPrint('[CloudBase REST] GET Error ${response.statusCode}: ${response.body}');
      return [];
    }
  }

  Future<Map<String, dynamic>?> _restGetOne(String table, String id) async {
    final results = await _restGet(table, filters: {'id': 'eq.$id'}, limit: 1);
    return results.isNotEmpty ? results.first : null;
  }

  Future<String?> _restPost(String table, Map<String, dynamic> data) async {
    final token = await _getAuthToken();
    final uri = Uri.parse('$_baseUrl/v1/rdb/rest/$table');

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Prefer': 'return=representation',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isNotEmpty) {
        final result = jsonDecode(response.body);
        if (result is List && result.isNotEmpty) {
          return result.first['id']?.toString();
        }
      }
      return data['id']?.toString();
    } else {
      debugPrint('[CloudBase REST] POST Error ${response.statusCode}: ${response.body}');
      throw Exception('Failed to create record');
    }
  }

  Future<void> _restPatch(String table, String id, Map<String, dynamic> data) async {
    final token = await _getAuthToken();
    final uri = Uri.parse('$_baseUrl/v1/rdb/rest/$table?id=eq.$id');

    final response = await http.patch(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Prefer': 'return=minimal',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      debugPrint('[CloudBase REST] PATCH Error ${response.statusCode}: ${response.body}');
      throw Exception('Failed to update record');
    }
  }

  Future<void> _restDelete(String table, String id) async {
    final token = await _getAuthToken();
    final uri = Uri.parse('$_baseUrl/v1/rdb/rest/$table?id=eq.$id');

    final response = await http.delete(uri, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });

    if (response.statusCode < 200 || response.statusCode >= 300) {
      debugPrint('[CloudBase REST] DELETE Error ${response.statusCode}: ${response.body}');
      throw Exception('Failed to delete record');
    }
  }

  // ==================== 用户相关 ====================

  /// 创建用户
  Future<void> createUser(UserModel user) async {
    try {
      final data = _userToCloudbase(user);
      await _restPost('users', data);
      debugPrint('[CloudBase DB] 用户创建成功: ${user.id}');
    } catch (e) {
      debugPrint('[CloudBase DB] 创建用户失败: $e');
      rethrow;
    }
  }

  /// 获取用户
  Future<UserModel?> getUser(String userId) async {
    try {
      debugPrint('[CloudBase DB] getUser 开始, userId=$userId');
      final data = await _restGetOne('users', userId);
      if (data == null) {
        debugPrint('[CloudBase DB] 用户不存在: $userId');
        return null;
      }
      debugPrint('[CloudBase DB] getUser 成功, coins=${data['coins']}');
      return _userFromCloudbase(data, userId);
    } catch (e) {
      debugPrint('[CloudBase DB] 获取用户失败: $e');
      return null;
    }
  }

  /// 更新用户
  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      await _restPatch('users', userId, data);
      debugPrint('[CloudBase DB] 用户更新成功: $userId');
    } catch (e) {
      debugPrint('[CloudBase DB] 更新用户失败: $e');
      rethrow;
    }
  }

  /// 用户数据流 (使用轮询模拟)
  Stream<UserModel?> userStream(String userId) {
    late StreamController<UserModel?> controller;
    Timer? pollTimer;

    controller = StreamController<UserModel?>(
      onListen: () {
        // 立即获取一次
        getUser(userId).then((user) {
          if (!controller.isClosed) controller.add(user);
        });
        // 每 5 秒轮询一次
        pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
          getUser(userId).then((user) {
            if (!controller.isClosed) controller.add(user);
          });
        });
      },
      onCancel: () {
        pollTimer?.cancel();
      },
    );

    return controller.stream;
  }

  /// 更新用户货币
  Future<void> updateUserCurrency(
    String userId, {
    int? coins,
    int? diamonds,
  }) async {
    try {
      // 获取当前值
      final user = await getUser(userId);
      if (user == null) throw Exception('User not found');

      final updates = <String, dynamic>{};
      if (coins != null) updates['coins'] = user.coins + coins;
      if (diamonds != null) updates['diamonds'] = user.diamonds + diamonds;

      if (updates.isNotEmpty) {
        await _restPatch('users', userId, updates);
        debugPrint('[CloudBase DB] 用户货币更新成功: $userId');
      }
    } catch (e) {
      debugPrint('[CloudBase DB] 更新用户货币失败: $e');
      rethrow;
    }
  }

  // ==================== 宠物相关 ====================

  /// 创建宠物
  Future<String> createPet(PetModel pet) async {
    try {
      final data = _petToCloudbase(pet);
      final petId = await _restPost('pets', data);
      debugPrint('[CloudBase DB] 宠物创建成功: $petId');
      return petId ?? pet.id;
    } catch (e) {
      debugPrint('[CloudBase DB] 创建宠物失败: $e');
      rethrow;
    }
  }

  /// 获取宠物
  Future<PetModel?> getPet(String petId) async {
    try {
      final data = await _restGetOne('pets', petId);
      if (data == null) return null;
      return _petFromCloudbase(data, petId);
    } catch (e) {
      debugPrint('[CloudBase DB] 获取宠物失败: $e');
      return null;
    }
  }

  /// 更新宠物
  Future<void> updatePet(String petId, Map<String, dynamic> data) async {
    try {
      await _restPatch('pets', petId, data);
      debugPrint('[CloudBase DB] 宠物更新成功: $petId');
    } catch (e) {
      debugPrint('[CloudBase DB] 更新宠物失败: $e');
      rethrow;
    }
  }

  /// 删除宠物
  Future<void> deletePet(String petId) async {
    try {
      await _restDelete('pets', petId);
      debugPrint('[CloudBase DB] 宠物删除成功: $petId');
    } catch (e) {
      debugPrint('[CloudBase DB] 删除宠物失败: $e');
      rethrow;
    }
  }

  /// 用户宠物列表流 (使用轮询模拟)
  Stream<List<PetModel>> userPetsStream(String userId) {
    late StreamController<List<PetModel>> controller;
    Timer? pollTimer;

    Future<List<PetModel>> fetchPets() async {
      final results = await _restGet('pets', filters: {'userId': 'eq.$userId'});
      return results.map((data) => _petFromCloudbase(data, data['id'] as String)).toList();
    }

    controller = StreamController<List<PetModel>>(
      onListen: () {
        fetchPets().then((pets) {
          if (!controller.isClosed) controller.add(pets);
        });
        pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
          fetchPets().then((pets) {
            if (!controller.isClosed) controller.add(pets);
          });
        });
      },
      onCancel: () {
        pollTimer?.cancel();
      },
    );

    return controller.stream;
  }

  /// 单个宠物数据流 (使用轮询模拟)
  Stream<PetModel?> petStream(String petId) {
    late StreamController<PetModel?> controller;
    Timer? pollTimer;

    controller = StreamController<PetModel?>(
      onListen: () {
        getPet(petId).then((pet) {
          if (!controller.isClosed) controller.add(pet);
        });
        pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
          getPet(petId).then((pet) {
            if (!controller.isClosed) controller.add(pet);
          });
        });
      },
      onCancel: () {
        pollTimer?.cancel();
      },
    );

    return controller.stream;
  }

  // ==================== 关联操作 ====================

  /// 添加宠物到用户
  Future<void> addPetToUser(String userId, String petId) async {
    try {
      final user = await getUser(userId);
      if (user == null) throw Exception('User not found');

      final petIds = List<String>.from(user.petIds);
      if (!petIds.contains(petId)) {
        petIds.add(petId);
        await _restPatch('users', userId, {'petIds': petIds});
      }
      debugPrint('[CloudBase DB] 添加宠物到用户成功');
    } catch (e) {
      debugPrint('[CloudBase DB] 添加宠物到用户失败: $e');
      rethrow;
    }
  }

  /// 从用户移除宠物
  Future<void> removePetFromUser(String userId, String petId) async {
    try {
      final user = await getUser(userId);
      if (user == null) throw Exception('User not found');

      final petIds = List<String>.from(user.petIds);
      petIds.remove(petId);
      await _restPatch('users', userId, {'petIds': petIds});
      debugPrint('[CloudBase DB] 从用户移除宠物成功');
    } catch (e) {
      debugPrint('[CloudBase DB] 从用户移除宠物失败: $e');
      rethrow;
    }
  }

  // ==================== 背包操作 ====================

  /// 获取用户背包
  Future<Map<String, int>> getUserInventory(String userId) async {
    try {
      final user = await getUser(userId);
      if (user == null) return {};
      return Map<String, int>.from(user.inventory);
    } catch (e) {
      debugPrint('[CloudBase DB] 获取背包失败: $e');
      return {};
    }
  }

  /// 使用道具
  Future<bool> useInventoryItem(String userId, String itemId) async {
    try {
      final inventory = await getUserInventory(userId);
      final quantity = inventory[itemId] ?? 0;
      if (quantity <= 0) return false;

      if (quantity == 1) {
        inventory.remove(itemId);
      } else {
        inventory[itemId] = quantity - 1;
      }

      await _restPatch('users', userId, {'inventory': inventory});
      debugPrint('[CloudBase DB] 使用道具成功: $itemId');
      return true;
    } catch (e) {
      debugPrint('[CloudBase DB] 使用道具失败: $e');
      return false;
    }
  }

  /// 添加道具
  Future<void> addInventoryItem(String userId, String itemId, int count) async {
    try {
      final inventory = await getUserInventory(userId);
      inventory[itemId] = (inventory[itemId] ?? 0) + count;
      await _restPatch('users', userId, {'inventory': inventory});
      debugPrint('[CloudBase DB] 添加道具成功: $itemId x$count');
    } catch (e) {
      debugPrint('[CloudBase DB] 添加道具失败: $e');
      rethrow;
    }
  }

  /// 设置初始背包
  Future<void> setInitialInventory(String userId, Map<String, int> inventory) async {
    try {
      await _restPatch('users', userId, {'inventory': inventory});
      debugPrint('[CloudBase DB] 设置初始背包成功');
    } catch (e) {
      debugPrint('[CloudBase DB] 设置初始背包失败: $e');
      rethrow;
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
    final pet = await getPet(petId);
    if (pet == null) throw Exception('Pet not found');

    final updates = <String, dynamic>{
      'updatedAt': DateTime.now().toIso8601String(),
      'lastInteractionAt': DateTime.now().toIso8601String(),
    };

    final status = {
      'happiness': happiness ?? pet.status.happiness,
      'hunger': hunger ?? pet.status.hunger,
      'energy': energy ?? pet.status.energy,
      'health': health ?? pet.status.health,
      'cleanliness': cleanliness ?? pet.status.cleanliness,
    };
    updates['status'] = status;

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
    try {
      final pet = await getPet(petId);
      if (pet == null) throw Exception('Pet not found');

      final stats = {
        'level': pet.stats.level,
        'experience': pet.stats.experience + (experienceGain ?? 0),
        'intimacy': pet.stats.intimacy + (intimacyGain ?? 0),
        'totalFeedings': pet.stats.totalFeedings + (incrementFeedings ? 1 : 0),
        'totalInteractions': pet.stats.totalInteractions + (incrementInteractions ? 1 : 0),
      };

      await _restPatch('pets', petId, {
        'stats': stats,
        'updatedAt': DateTime.now().toIso8601String(),
        'lastInteractionAt': DateTime.now().toIso8601String(),
      });
      debugPrint('[CloudBase DB] 更新宠物成长成功');
    } catch (e) {
      debugPrint('[CloudBase DB] 更新宠物成长失败: $e');
      rethrow;
    }
  }

  // ==================== 成就系统 ====================

  /// 获取用户成就进度流 (使用轮询模拟)
  Stream<List<UserAchievement>> userAchievementsStream(String userId) {
    late StreamController<List<UserAchievement>> controller;
    Timer? pollTimer;

    controller = StreamController<List<UserAchievement>>(
      onListen: () {
        getUserAchievements(userId).then((achievements) {
          if (!controller.isClosed) controller.add(achievements);
        });
        pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
          getUserAchievements(userId).then((achievements) {
            if (!controller.isClosed) controller.add(achievements);
          });
        });
      },
      onCancel: () {
        pollTimer?.cancel();
      },
    );

    return controller.stream;
  }

  /// 获取用户所有成就进度
  Future<List<UserAchievement>> getUserAchievements(String userId) async {
    try {
      final results = await _restGet('user_achievements', filters: {'userId': 'eq.$userId'});
      return results.map((data) => _userAchievementFromCloudbase(data, data['id'] as String? ?? '')).toList();
    } catch (e) {
      debugPrint('[CloudBase DB] 获取成就失败: $e');
      return [];
    }
  }

  /// 解锁成就
  Future<void> unlockAchievement({
    required String userId,
    required String achievementId,
    required int currentValue,
  }) async {
    try {
      final docId = '${userId}_$achievementId';
      await _restPost('user_achievements', {
        'id': docId,
        'userId': userId,
        'achievementId': achievementId,
        'currentValue': currentValue,
        'isUnlocked': true,
        'unlockedAt': DateTime.now().toIso8601String(),
        'isRewardClaimed': false,
        'claimedAt': null,
      });
      debugPrint('[CloudBase DB] 解锁成就成功: $achievementId');
    } catch (e) {
      debugPrint('[CloudBase DB] 解锁成就失败: $e');
      rethrow;
    }
  }

  /// 更新成就进度
  Future<void> updateAchievementProgress({
    required String userId,
    required String achievementId,
    required int currentValue,
  }) async {
    try {
      final docId = '${userId}_$achievementId';
      final existing = await _restGetOne('user_achievements', docId);

      if (existing == null) {
        await _restPost('user_achievements', {
          'id': docId,
          'userId': userId,
          'achievementId': achievementId,
          'currentValue': currentValue,
          'isUnlocked': false,
          'unlockedAt': null,
          'isRewardClaimed': false,
          'claimedAt': null,
        });
      } else if (existing['isUnlocked'] != true) {
        await _restPatch('user_achievements', docId, {'currentValue': currentValue});
      }
      debugPrint('[CloudBase DB] 更新成就进度成功: $achievementId = $currentValue');
    } catch (e) {
      debugPrint('[CloudBase DB] 更新成就进度失败: $e');
      rethrow;
    }
  }

  /// 领取成就奖励
  Future<void> claimAchievementReward({
    required String userId,
    required String achievementId,
    required AchievementReward reward,
  }) async {
    try {
      final docId = '${userId}_$achievementId';
      final data = await _restGetOne('user_achievements', docId);

      if (data == null) throw Exception('成就不存在');
      if (data['isUnlocked'] != true) throw Exception('成就尚未解锁');
      if (data['isRewardClaimed'] == true) throw Exception('奖励已领取');

      // 获取用户当前数据
      final user = await getUser(userId);
      if (user == null) throw Exception('User not found');

      // 计算新的货币和背包
      final newCoins = user.coins + reward.coins;
      final newDiamonds = user.diamonds + reward.diamonds;
      final newInventory = Map<String, int>.from(user.inventory);
      for (final entry in reward.items.entries) {
        newInventory[entry.key] = (newInventory[entry.key] ?? 0) + entry.value;
      }

      // 更新用户数据
      await _restPatch('users', userId, {
        'coins': newCoins,
        'diamonds': newDiamonds,
        'inventory': newInventory,
      });

      // 标记奖励已领取
      await _restPatch('user_achievements', docId, {
        'isRewardClaimed': true,
        'claimedAt': DateTime.now().toIso8601String(),
      });

      debugPrint('[CloudBase DB] 领取成就奖励成功: $achievementId');
    } catch (e) {
      debugPrint('[CloudBase DB] 领取成就奖励失败: $e');
      rethrow;
    }
  }

  // ==================== 统计相关 ====================

  /// 获取用户统计数据
  Future<Map<String, int>?> getUserStats(String userId) async {
    try {
      final user = await getUser(userId);
      if (user == null) return null;

      // 从用户数据中提取统计信息
      return {
        'petCount': user.petIds.length,
        'consecutiveDays': user.consecutiveDays,
        'itemTypeCount': user.inventory.length,
        'petOwned': user.petIds.length,
      };
    } catch (e) {
      debugPrint('[CloudBase DB] 获取用户统计失败: $e');
      return null;
    }
  }

  /// 增加用户统计计数
  Future<void> incrementUserStat(String userId, String statName, {int value = 1}) async {
    // HTTP API 版本暂不支持复杂的统计增量，使用简化实现
    debugPrint('[CloudBase DB] incrementUserStat: $statName +$value (simplified)');
  }

  // ==================== 数据转换 ====================

  /// UserModel 转 CloudBase 数据
  /// 注意：CloudBase MySQL REST API 需要 JSON 字段为字符串格式
  Map<String, dynamic> _userToCloudbase(UserModel user) {
    return {
      'id': user.id,
      'email': user.email,
      'phone': user.phone,
      'displayName': user.displayName,
      'avatarUrl': user.avatarUrl,
      'coins': user.coins,
      'diamonds': user.diamonds,
      'petIds': jsonEncode(user.petIds),
      'maxPets': user.maxPets,
      'inventory': jsonEncode(user.inventory),
      'achievements': jsonEncode(user.achievements),
      'following': jsonEncode(user.following),
      'followers': jsonEncode(user.followers),
      'consecutiveDays': user.consecutiveDays,
      'lastSignInDate': user.lastSignInDate?.toIso8601String(),
      'createdAt': user.createdAt.toIso8601String(),
    };
  }

  /// CloudBase 数据转 UserModel
  /// 注意：JSON 字段从数据库读取时可能是字符串或已解析的对象
  UserModel _userFromCloudbase(Map<String, dynamic> data, String id) {
    DateTime parseDateTime(dynamic value) {
      if (value is String && value.isNotEmpty) {
        return DateTime.parse(value);
      }
      return DateTime.now();
    }

    DateTime? parseDateTimeNullable(dynamic value) {
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    // 解析可能是字符串或对象的 JSON 字段
    List<String> parseStringList(dynamic value) {
      if (value == null) return [];
      if (value is String) {
        try {
          final parsed = jsonDecode(value);
          if (parsed is List) return List<String>.from(parsed);
        } catch (_) {}
        return [];
      }
      if (value is List) return List<String>.from(value);
      return [];
    }

    Map<String, int> parseIntMap(dynamic value) {
      if (value == null) return {};
      if (value is String) {
        try {
          final parsed = jsonDecode(value);
          if (parsed is Map) return Map<String, int>.from(parsed.map((k, v) => MapEntry(k.toString(), (v as num).toInt())));
        } catch (_) {}
        return {};
      }
      if (value is Map) return Map<String, int>.from(value.map((k, v) => MapEntry(k.toString(), (v as num).toInt())));
      return {};
    }

    return UserModel(
      id: id,
      email: data['email'] as String?,
      phone: data['phone'] as String?,
      displayName: data['displayName'] as String?,
      avatarUrl: data['avatarUrl'] as String?,
      coins: data['coins'] as int? ?? 0,
      diamonds: data['diamonds'] as int? ?? 0,
      petIds: parseStringList(data['petIds']),
      maxPets: data['maxPets'] as int? ?? 4,
      inventory: parseIntMap(data['inventory']),
      achievements: parseStringList(data['achievements']),
      following: parseStringList(data['following']),
      followers: parseStringList(data['followers']),
      consecutiveDays: data['consecutiveDays'] as int? ?? 0,
      lastSignInDate: parseDateTimeNullable(data['lastSignInDate']),
      createdAt: parseDateTime(data['createdAt']),
    );
  }

  /// PetModel 转 CloudBase 数据
  /// 注意：CloudBase MySQL REST API 需要 JSON 字段为字符串格式
  Map<String, dynamic> _petToCloudbase(PetModel pet) {
    return {
      'id': pet.id,
      'userId': pet.userId,
      'name': pet.name,
      'species': pet.species.name,
      'breed': pet.breed,
      'appearance': jsonEncode({
        'furColor': pet.appearance.furColor,
        'furPattern': pet.appearance.furPattern,
        'eyeColor': pet.appearance.eyeColor,
        'specialMarks': pet.appearance.specialMarks,
      }),
      'originalPhotoUrl': pet.originalPhotoUrl,
      'cartoonAvatarUrl': pet.cartoonAvatarUrl,
      'generatedAvatars': jsonEncode(pet.generatedAvatars),
      'status': jsonEncode({
        'happiness': pet.status.happiness,
        'hunger': pet.status.hunger,
        'energy': pet.status.energy,
        'health': pet.status.health,
        'cleanliness': pet.status.cleanliness,
      }),
      'stats': jsonEncode({
        'level': pet.stats.level,
        'experience': pet.stats.experience,
        'intimacy': pet.stats.intimacy,
        'totalFeedings': pet.stats.totalFeedings,
        'totalInteractions': pet.stats.totalInteractions,
      }),
      'equippedItems': jsonEncode(pet.equippedItems),
      'ownedItems': jsonEncode(pet.ownedItems),
      'isMemorial': pet.isMemorial,
      'memorialNote': pet.memorialNote,
      'memorialDate': pet.memorialDate?.toIso8601String(),
      'createdAt': pet.createdAt.toIso8601String(),
      'updatedAt': pet.updatedAt.toIso8601String(),
      'lastInteractionAt': pet.lastInteractionAt.toIso8601String(),
    };
  }

  /// CloudBase 数据转 PetModel
  PetModel _petFromCloudbase(Map<String, dynamic> data, String id) {
    PetSpecies parseSpecies(dynamic value) {
      if (value is String) {
        return PetSpecies.values.firstWhere(
          (e) => e.name == value,
          orElse: () => PetSpecies.cat,
        );
      }
      return PetSpecies.cat;
    }

    DateTime parseDateTime(dynamic value) {
      if (value is String && value.isNotEmpty) {
        return DateTime.parse(value);
      }
      return DateTime.now();
    }

    DateTime? parseDateTimeNullable(dynamic value) {
      if (value is String && value.isNotEmpty) {
        return DateTime.parse(value);
      }
      return null;
    }

    // 解析可能是字符串或对象的 JSON 字段
    Map<String, dynamic> parseJsonMap(dynamic value) {
      if (value == null) return {};
      if (value is String) {
        try {
          final parsed = jsonDecode(value);
          if (parsed is Map) return Map<String, dynamic>.from(parsed);
        } catch (_) {}
        return {};
      }
      if (value is Map) return Map<String, dynamic>.from(value);
      return {};
    }

    List<String> parseStringList(dynamic value) {
      if (value == null) return [];
      if (value is String) {
        try {
          final parsed = jsonDecode(value);
          if (parsed is List) return List<String>.from(parsed);
        } catch (_) {}
        return [];
      }
      if (value is List) return List<String>.from(value);
      return [];
    }

    final appearanceData = parseJsonMap(data['appearance']);
    final statusData = parseJsonMap(data['status']);
    final statsData = parseJsonMap(data['stats']);

    return PetModel(
      id: id,
      userId: data['userId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      species: parseSpecies(data['species']),
      breed: data['breed'] as String?,
      appearance: PetAppearance(
        furColor: appearanceData['furColor'] as String? ?? 'orange',
        furPattern: appearanceData['furPattern'] as String?,
        eyeColor: appearanceData['eyeColor'] as String? ?? 'yellow',
        specialMarks: appearanceData['specialMarks'] as String?,
      ),
      originalPhotoUrl: data['originalPhotoUrl'] as String?,
      cartoonAvatarUrl: data['cartoonAvatarUrl'] as String?,
      generatedAvatars: parseStringList(data['generatedAvatars']),
      status: PetStatus(
        happiness: statusData['happiness'] as int? ?? 100,
        hunger: statusData['hunger'] as int? ?? 100,
        energy: statusData['energy'] as int? ?? 100,
        health: statusData['health'] as int? ?? 100,
        cleanliness: statusData['cleanliness'] as int? ?? 100,
      ),
      stats: PetStats(
        level: statsData['level'] as int? ?? 1,
        experience: statsData['experience'] as int? ?? 0,
        intimacy: statsData['intimacy'] as int? ?? 0,
        totalFeedings: statsData['totalFeedings'] as int? ?? 0,
        totalInteractions: statsData['totalInteractions'] as int? ?? 0,
      ),
      equippedItems: parseStringList(data['equippedItems']),
      ownedItems: parseStringList(data['ownedItems']),
      isMemorial: data['isMemorial'] as bool? ?? false,
      memorialNote: data['memorialNote'] as String?,
      memorialDate: parseDateTimeNullable(data['memorialDate']),
      createdAt: parseDateTime(data['createdAt']),
      updatedAt: parseDateTime(data['updatedAt']),
      lastInteractionAt: parseDateTime(data['lastInteractionAt']),
    );
  }

  /// CloudBase 数据转 UserAchievement
  UserAchievement _userAchievementFromCloudbase(Map<String, dynamic> data, String id) {
    DateTime? parseDateTime(dynamic value) {
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    return UserAchievement(
      achievementId: data['achievementId'] as String? ?? id,
      currentValue: data['currentValue'] as int? ?? 0,
      isUnlocked: data['isUnlocked'] as bool? ?? false,
      unlockedAt: parseDateTime(data['unlockedAt']),
      isRewardClaimed: data['isRewardClaimed'] as bool? ?? false,
      claimedAt: parseDateTime(data['claimedAt']),
    );
  }
}

/// CloudBase 认证服务 Provider (用于依赖注入)
final cloudbaseAuthServiceProvider = Provider<CloudbaseAuthHttpService>((ref) {
  return CloudbaseAuthHttpService();
});
