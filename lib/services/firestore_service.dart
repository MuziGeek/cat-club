import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/models/achievement_model.dart';
import '../data/models/pet_model.dart';
import '../data/models/user_model.dart';

/// Firestore 服务 - 封装 Cloud Firestore 操作
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== 集合引用 ====================

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _petsCollection =>
      _firestore.collection('pets');

  // ==================== 用户操作 ====================

  /// 创建用户文档
  Future<void> createUser(UserModel user) async {
    await _usersCollection.doc(user.id).set(_userToFirestore(user));
  }

  /// 获取用户
  Future<UserModel?> getUser(String userId) async {
    print('[FIRESTORE_SERVICE] getUser 开始, userId=$userId');
    try {
      final doc = await _usersCollection.doc(userId).get();
      print('[FIRESTORE_SERVICE] getUser 文档获取完成, exists=${doc.exists}');
      if (!doc.exists || doc.data() == null) {
        print('[FIRESTORE_SERVICE] getUser 文档不存在或数据为空');
        return null;
      }
      final userData = _userFromFirestore(doc.data()!, doc.id);
      print('[FIRESTORE_SERVICE] getUser 转换完成, coins=${userData.coins}');
      return userData;
    } catch (e, st) {
      print('[FIRESTORE_SERVICE] getUser 异常: $e');
      print('[FIRESTORE_SERVICE] 堆栈: $st');
      rethrow;
    }
  }

  /// 更新用户
  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await _usersCollection.doc(userId).update(data);
  }

  /// 用户实时流
  Stream<UserModel?> userStream(String userId) {
    return _usersCollection.doc(userId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return _userFromFirestore(doc.data()!, doc.id);
    });
  }

  /// 更新用户货币
  Future<void> updateUserCurrency(
    String userId, {
    int? coins,
    int? diamonds,
  }) async {
    final updates = <String, dynamic>{};
    if (coins != null) updates['coins'] = FieldValue.increment(coins);
    if (diamonds != null) updates['diamonds'] = FieldValue.increment(diamonds);
    if (updates.isNotEmpty) {
      await _usersCollection.doc(userId).update(updates);
    }
  }

  // ==================== 宠物操作 ====================

  /// 创建宠物
  Future<String> createPet(PetModel pet) async {
    final docRef = _petsCollection.doc();
    final petWithId = pet.copyWith(id: docRef.id);
    await docRef.set(_petToFirestore(petWithId));
    return docRef.id;
  }

  /// 获取宠物
  Future<PetModel?> getPet(String petId) async {
    final doc = await _petsCollection.doc(petId).get();
    if (!doc.exists || doc.data() == null) return null;
    return _petFromFirestore(doc.data()!, doc.id);
  }

  /// 更新宠物
  Future<void> updatePet(String petId, Map<String, dynamic> data) async {
    await _petsCollection.doc(petId).update(data);
  }

  /// 删除宠物
  Future<void> deletePet(String petId) async {
    await _petsCollection.doc(petId).delete();
  }

  /// 宠物实时流
  Stream<PetModel?> petStream(String petId) {
    return _petsCollection.doc(petId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return _petFromFirestore(doc.data()!, doc.id);
    });
  }

  /// 用户所有宠物流
  Stream<List<PetModel>> userPetsStream(String userId) {
    return _petsCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => _petFromFirestore(doc.data(), doc.id))
            .toList());
  }

  // ==================== 关联操作 ====================

  /// 添加宠物到用户
  Future<void> addPetToUser(String userId, String petId) async {
    await _usersCollection.doc(userId).set({
      'petIds': FieldValue.arrayUnion([petId]),
    }, SetOptions(merge: true));
  }

  /// 从用户移除宠物
  Future<void> removePetFromUser(String userId, String petId) async {
    await _usersCollection.doc(userId).set({
      'petIds': FieldValue.arrayRemove([petId]),
    }, SetOptions(merge: true));
  }

  // ==================== 背包操作 ====================

  /// 获取用户背包
  Future<Map<String, int>> getUserInventory(String userId) async {
    final doc = await _usersCollection.doc(userId).get();
    final data = doc.data();
    if (data == null) return {};
    final inventory = data['inventory'];
    if (inventory == null) return {};
    return Map<String, int>.from(inventory as Map);
  }

  /// 使用道具（原子操作）
  /// 返回 true 表示使用成功，false 表示数量不足
  Future<bool> useInventoryItem(String userId, String itemId) async {
    final docRef = _usersCollection.doc(userId);
    return _firestore.runTransaction<bool>((tx) async {
      final doc = await tx.get(docRef);
      final data = doc.data();
      if (data == null) return false;

      final inventory = Map<String, int>.from((data['inventory'] ?? {}) as Map);
      final quantity = inventory[itemId] ?? 0;
      if (quantity <= 0) return false;

      inventory[itemId] = quantity - 1;
      if (inventory[itemId] == 0) {
        inventory.remove(itemId);
      }

      tx.update(docRef, {'inventory': inventory});
      return true;
    });
  }

  /// 添加道具（原子操作）
  Future<void> addInventoryItem(String userId, String itemId, int count) async {
    await _usersCollection.doc(userId).update({
      'inventory.$itemId': FieldValue.increment(count),
    });
  }

  /// 设置初始背包（用于新用户）
  Future<void> setInitialInventory(String userId, Map<String, int> inventory) async {
    await _usersCollection.doc(userId).set({
      'inventory': inventory,
    }, SetOptions(merge: true));
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
    final updates = <String, dynamic>{};
    if (happiness != null) updates['status.happiness'] = happiness;
    if (hunger != null) updates['status.hunger'] = hunger;
    if (energy != null) updates['status.energy'] = energy;
    if (health != null) updates['status.health'] = health;
    if (cleanliness != null) updates['status.cleanliness'] = cleanliness;
    updates['lastInteractionAt'] = FieldValue.serverTimestamp();
    updates['updatedAt'] = FieldValue.serverTimestamp();

    if (updates.isNotEmpty) {
      await _petsCollection.doc(petId).update(updates);
    }
  }

  /// 更新宠物成长数据
  Future<void> updatePetStats(
    String petId, {
    int? experienceGain,
    int? intimacyGain,
    bool? incrementFeedings,
    bool? incrementInteractions,
  }) async {
    final updates = <String, dynamic>{};
    if (experienceGain != null) {
      updates['stats.experience'] = FieldValue.increment(experienceGain);
    }
    if (intimacyGain != null) {
      updates['stats.intimacy'] = FieldValue.increment(intimacyGain);
    }
    if (incrementFeedings == true) {
      updates['stats.totalFeedings'] = FieldValue.increment(1);
    }
    if (incrementInteractions == true) {
      updates['stats.totalInteractions'] = FieldValue.increment(1);
    }
    updates['lastInteractionAt'] = FieldValue.serverTimestamp();
    updates['updatedAt'] = FieldValue.serverTimestamp();

    if (updates.isNotEmpty) {
      await _petsCollection.doc(petId).update(updates);
    }
  }

  // ==================== 数据转换 ====================

  /// UserModel 转 Firestore 数据
  Map<String, dynamic> _userToFirestore(UserModel user) {
    final json = user.toJson();
    // DateTime 转 Timestamp
    json['createdAt'] = Timestamp.fromDate(user.createdAt);
    if (user.lastSignInDate != null) {
      json['lastSignInDate'] = Timestamp.fromDate(user.lastSignInDate!);
    }
    return json;
  }

  /// Firestore 数据转 UserModel
  UserModel _userFromFirestore(Map<String, dynamic> data, String id) {
    final json = Map<String, dynamic>.from(data);
    json['id'] = id;

    // 处理 createdAt - 确保转换为有效的 ISO8601 字符串
    final createdAt = json['createdAt'];
    if (createdAt is Timestamp) {
      json['createdAt'] = createdAt.toDate().toIso8601String();
    } else if (createdAt is String && createdAt.isNotEmpty) {
      // 已经是有效字符串，保持不变
      json['createdAt'] = createdAt;
    } else {
      // null、空字符串或其他类型，使用当前时间
      json['createdAt'] = DateTime.now().toIso8601String();
    }

    // 处理 lastSignInDate
    final lastSignInDate = json['lastSignInDate'];
    if (lastSignInDate is Timestamp) {
      json['lastSignInDate'] = lastSignInDate.toDate().toIso8601String();
    } else if (lastSignInDate != null && lastSignInDate is! String) {
      // 非 String 非 null 类型，设为 null 让 fromJson 处理
      json['lastSignInDate'] = null;
    }

    return UserModel.fromJson(json);
  }

  /// PetModel 转 Firestore 数据
  Map<String, dynamic> _petToFirestore(PetModel pet) {
    final json = <String, dynamic>{
      'id': pet.id,
      'userId': pet.userId,
      'name': pet.name,
      'species': pet.species.name,
      'breed': pet.breed,
      'appearance': {
        'furColor': pet.appearance.furColor,
        'furPattern': pet.appearance.furPattern,
        'eyeColor': pet.appearance.eyeColor,
        'specialMarks': pet.appearance.specialMarks,
      },
      'originalPhotoUrl': pet.originalPhotoUrl,
      'cartoonAvatarUrl': pet.cartoonAvatarUrl,
      'generatedAvatars': pet.generatedAvatars,
      'status': {
        'happiness': pet.status.happiness,
        'hunger': pet.status.hunger,
        'energy': pet.status.energy,
        'health': pet.status.health,
        'cleanliness': pet.status.cleanliness,
      },
      'stats': {
        'level': pet.stats.level,
        'experience': pet.stats.experience,
        'intimacy': pet.stats.intimacy,
        'totalFeedings': pet.stats.totalFeedings,
        'totalInteractions': pet.stats.totalInteractions,
      },
      'equippedItems': pet.equippedItems,
      'ownedItems': pet.ownedItems,
      'isMemorial': pet.isMemorial,
      'memorialNote': pet.memorialNote,
      'createdAt': Timestamp.fromDate(pet.createdAt),
      'updatedAt': Timestamp.fromDate(pet.updatedAt),
      'lastInteractionAt': Timestamp.fromDate(pet.lastInteractionAt),
    };
    if (pet.memorialDate != null) {
      json['memorialDate'] = Timestamp.fromDate(pet.memorialDate!);
    }
    return json;
  }

  /// Firestore 数据转 PetModel
  PetModel _petFromFirestore(Map<String, dynamic> data, String id) {
    // 处理 Timestamp 转 DateTime
    String? getDateTimeString(dynamic value) {
      if (value is Timestamp) {
        return value.toDate().toIso8601String();
      } else if (value is String) {
        return value;
      }
      return DateTime.now().toIso8601String();
    }

    // 处理 species 枚举
    PetSpecies parseSpecies(dynamic value) {
      if (value is String) {
        return PetSpecies.values.firstWhere(
          (e) => e.name == value,
          orElse: () => PetSpecies.cat,
        );
      }
      return PetSpecies.cat;
    }

    // 处理嵌套 Map
    final appearanceData = data['appearance'] as Map<String, dynamic>? ?? {};
    final statusData = data['status'] as Map<String, dynamic>? ?? {};
    final statsData = data['stats'] as Map<String, dynamic>? ?? {};

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
      generatedAvatars: List<String>.from((data['generatedAvatars'] ?? []) as List),
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
      equippedItems: List<String>.from((data['equippedItems'] ?? []) as List),
      ownedItems: List<String>.from((data['ownedItems'] ?? []) as List),
      isMemorial: data['isMemorial'] as bool? ?? false,
      memorialNote: data['memorialNote'] as String?,
      memorialDate: data['memorialDate'] != null
          ? (data['memorialDate'] is Timestamp
              ? (data['memorialDate'] as Timestamp).toDate()
              : DateTime.parse(data['memorialDate'] as String))
          : null,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.parse(getDateTimeString(data['createdAt'])!),
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(getDateTimeString(data['updatedAt'])!),
      lastInteractionAt: data['lastInteractionAt'] is Timestamp
          ? (data['lastInteractionAt'] as Timestamp).toDate()
          : DateTime.parse(getDateTimeString(data['lastInteractionAt'])!),
    );
  }

  // ==================== 成就系统 ====================

  /// 成就子集合引用
  CollectionReference<Map<String, dynamic>> _userAchievementsCollection(String userId) =>
      _usersCollection.doc(userId).collection('achievements');

  /// 获取用户成就进度流
  Stream<List<UserAchievement>> userAchievementsStream(String userId) {
    return _userAchievementsCollection(userId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return _userAchievementFromFirestore(doc.data(), doc.id);
      }).toList();
    });
  }

  /// 获取用户所有成就进度
  Future<List<UserAchievement>> getUserAchievements(String userId) async {
    final snapshot = await _userAchievementsCollection(userId).get();
    return snapshot.docs.map((doc) {
      return _userAchievementFromFirestore(doc.data(), doc.id);
    }).toList();
  }

  /// 解锁成就
  Future<void> unlockAchievement({
    required String userId,
    required String achievementId,
    required int currentValue,
  }) async {
    await _userAchievementsCollection(userId).doc(achievementId).set({
      'achievementId': achievementId,
      'currentValue': currentValue,
      'isUnlocked': true,
      'unlockedAt': FieldValue.serverTimestamp(),
      'isRewardClaimed': false,
      'claimedAt': null,
    }, SetOptions(merge: true));
  }

  /// 更新成就进度
  Future<void> updateAchievementProgress({
    required String userId,
    required String achievementId,
    required int currentValue,
  }) async {
    final docRef = _userAchievementsCollection(userId).doc(achievementId);
    final doc = await docRef.get();

    if (!doc.exists) {
      // 创建新进度记录
      await docRef.set({
        'achievementId': achievementId,
        'currentValue': currentValue,
        'isUnlocked': false,
        'unlockedAt': null,
        'isRewardClaimed': false,
        'claimedAt': null,
      });
    } else {
      // 只更新进度值（不覆盖已解锁状态）
      final data = doc.data();
      if (data != null && data['isUnlocked'] != true) {
        await docRef.update({'currentValue': currentValue});
      }
    }
  }

  /// 领取成就奖励（事务操作）
  Future<void> claimAchievementReward({
    required String userId,
    required String achievementId,
    required AchievementReward reward,
  }) async {
    final userDocRef = _usersCollection.doc(userId);
    final achievementDocRef = _userAchievementsCollection(userId).doc(achievementId);

    await _firestore.runTransaction((tx) async {
      // 检查成就状态
      final achievementDoc = await tx.get(achievementDocRef);
      if (!achievementDoc.exists) {
        throw Exception('成就不存在');
      }

      final data = achievementDoc.data();
      if (data == null || data['isUnlocked'] != true) {
        throw Exception('成就尚未解锁');
      }
      if (data['isRewardClaimed'] == true) {
        throw Exception('奖励已领取');
      }

      // 发放货币奖励
      final userUpdates = <String, dynamic>{};
      if (reward.coins > 0) {
        userUpdates['coins'] = FieldValue.increment(reward.coins);
      }
      if (reward.diamonds > 0) {
        userUpdates['diamonds'] = FieldValue.increment(reward.diamonds);
      }

      // 发放道具奖励
      for (final entry in reward.items.entries) {
        userUpdates['inventory.${entry.key}'] = FieldValue.increment(entry.value);
      }

      if (userUpdates.isNotEmpty) {
        tx.update(userDocRef, userUpdates);
      }

      // 标记奖励已领取
      tx.update(achievementDocRef, {
        'isRewardClaimed': true,
        'claimedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// 获取用户统计数据（用于成就检查）
  Future<Map<String, int>?> getUserStats(String userId) async {
    try {
      final userDoc = await _usersCollection.doc(userId).get();
      final userData = userDoc.data();
      if (userData == null) return null;

      final stats = userData['stats'] as Map<String, dynamic>? ?? {};
      final inventory = userData['inventory'] as Map<String, dynamic>? ?? {};
      final petIds = (userData['petIds'] as List?)?.length ?? 0;

      return {
        'petCount': stats['petCount'] as int? ?? 0,
        'feedCount': stats['feedCount'] as int? ?? 0,
        'playCount': stats['playCount'] as int? ?? 0,
        'cleanCount': stats['cleanCount'] as int? ?? 0,
        'maxLevel': stats['maxLevel'] as int? ?? 1,
        'maxIntimacy': stats['maxIntimacy'] as int? ?? 0,
        'checkInStreak': stats['checkInStreak'] as int? ?? 0,
        'checkInTotal': stats['checkInTotal'] as int? ?? 0,
        'itemTypeCount': inventory.length,
        'petOwned': petIds,
      };
    } catch (e) {
      print('[FIRESTORE] 获取用户统计失败: $e');
      return null;
    }
  }

  /// 增加用户统计计数
  Future<void> incrementUserStat(String userId, String statName, {int value = 1}) async {
    await _usersCollection.doc(userId).set({
      'stats': {
        statName: FieldValue.increment(value),
      },
    }, SetOptions(merge: true));
  }

  /// UserAchievement 从 Firestore 转换
  UserAchievement _userAchievementFromFirestore(Map<String, dynamic> data, String id) {
    return UserAchievement(
      achievementId: data['achievementId'] as String? ?? id,
      currentValue: data['currentValue'] as int? ?? 0,
      isUnlocked: data['isUnlocked'] as bool? ?? false,
      unlockedAt: data['unlockedAt'] is Timestamp
          ? (data['unlockedAt'] as Timestamp).toDate()
          : null,
      isRewardClaimed: data['isRewardClaimed'] as bool? ?? false,
      claimedAt: data['claimedAt'] is Timestamp
          ? (data['claimedAt'] as Timestamp).toDate()
          : null,
    );
  }
}
