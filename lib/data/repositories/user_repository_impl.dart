import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/exceptions/cloudbase_exception.dart';
import '../../data/datasources/cloudbase_rest_client.dart';
import '../../data/mappers/user_mapper.dart';
import '../../data/models/user_model.dart';
import '../../domain/repositories/user_repository.dart';

/// 用户仓库实现
///
/// 使用 CloudBase REST Client 实现用户数据操作
class UserRepositoryImpl implements UserRepository {
  final CloudbaseRestClient _client;

  UserRepositoryImpl(this._client);

  static const String _table = 'users';

  @override
  Future<Result<UserModel?>> getUser(String userId) async {
    debugPrint('[UserRepo] getUser: $userId');
    final result = await _client.getOne(_table, userId);
    return result.map((data) {
      if (data == null) return null;
      return UserMapper.fromCloudbase(data, userId);
    });
  }

  @override
  Future<Result<UserModel>> createUser(UserModel user) async {
    debugPrint('[UserRepo] createUser: ${user.id}');
    final data = UserMapper.toCloudbase(user);
    final result = await _client.create(_table, data);
    return result.map((_) => user);
  }

  @override
  Future<Result<void>> updateUser(
    String userId,
    Map<String, dynamic> data,
  ) async {
    debugPrint('[UserRepo] updateUser: $userId');
    return _client.update(_table, userId, data);
  }

  @override
  Future<Result<UserModel>> ensureUserExists(String userId) async {
    debugPrint('[UserRepo] ensureUserExists: $userId');

    // 1. 先尝试获取用户
    final getResult = await getUser(userId);
    if (getResult.isFailure) {
      return Failure(getResult.exceptionOrNull!);
    }

    final existingUser = getResult.dataOrNull;
    if (existingUser != null) {
      debugPrint('[UserRepo] User exists: $userId');
      return Success(existingUser);
    }

    // 2. 用户不存在，创建新用户
    debugPrint('[UserRepo] Creating new user: $userId');
    final newUser = UserMapper.createDefault(userId);
    return createUser(newUser);
  }

  @override
  Stream<UserModel?> userStream(String userId) {
    late StreamController<UserModel?> controller;
    Timer? pollTimer;

    controller = StreamController<UserModel?>(
      onListen: () {
        // 立即获取一次
        getUser(userId).then((result) {
          if (!controller.isClosed) {
            controller.add(result.dataOrNull);
          }
        });
        // 每 5 秒轮询一次
        pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
          getUser(userId).then((result) {
            if (!controller.isClosed) {
              controller.add(result.dataOrNull);
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
  Future<Result<void>> updateCurrency(
    String userId, {
    int? coinsChange,
    int? diamondsChange,
  }) async {
    debugPrint('[UserRepo] updateCurrency: $userId, coins=$coinsChange, diamonds=$diamondsChange');

    // 获取当前值
    final getResult = await getUser(userId);
    if (getResult.isFailure) return Failure(getResult.exceptionOrNull!);

    final user = getResult.dataOrNull;
    if (user == null) {
      return const Failure(NotFoundException('User not found'));
    }

    final updates = <String, dynamic>{};
    if (coinsChange != null) {
      updates['coins'] = user.coins + coinsChange;
    }
    if (diamondsChange != null) {
      updates['diamonds'] = user.diamonds + diamondsChange;
    }

    if (updates.isEmpty) return const Success(null);
    return updateUser(userId, updates);
  }

  @override
  Future<Result<Map<String, int>>> getInventory(String userId) async {
    final getResult = await getUser(userId);
    return getResult.map((user) {
      if (user == null) return <String, int>{};
      return Map<String, int>.from(user.inventory);
    });
  }

  @override
  Future<Result<bool>> useItem(String userId, String itemId) async {
    debugPrint('[UserRepo] useItem: $userId, item=$itemId');

    final inventoryResult = await getInventory(userId);
    if (inventoryResult.isFailure) {
      return Failure(inventoryResult.exceptionOrNull!);
    }

    final inventory = inventoryResult.dataOrNull!;
    final quantity = inventory[itemId] ?? 0;
    if (quantity <= 0) {
      return const Success(false);
    }

    if (quantity == 1) {
      inventory.remove(itemId);
    } else {
      inventory[itemId] = quantity - 1;
    }

    final updateResult = await updateUser(userId, {
      'inventory': jsonEncode(inventory),
    });

    return updateResult.map((_) => true);
  }

  @override
  Future<Result<void>> addItem(
    String userId,
    String itemId,
    int count,
  ) async {
    debugPrint('[UserRepo] addItem: $userId, item=$itemId, count=$count');

    final inventoryResult = await getInventory(userId);
    if (inventoryResult.isFailure) {
      return Failure(inventoryResult.exceptionOrNull!);
    }

    final inventory = inventoryResult.dataOrNull!;
    inventory[itemId] = (inventory[itemId] ?? 0) + count;

    return updateUser(userId, {'inventory': jsonEncode(inventory)});
  }

  @override
  Future<Result<void>> setInitialInventory(
    String userId,
    Map<String, int> inventory,
  ) async {
    debugPrint('[UserRepo] setInitialInventory: $userId');
    return updateUser(userId, {'inventory': jsonEncode(inventory)});
  }

  @override
  Future<Result<void>> addPetToUser(String userId, String petId) async {
    debugPrint('[UserRepo] addPetToUser: $userId, pet=$petId');

    final getResult = await getUser(userId);
    if (getResult.isFailure) return Failure(getResult.exceptionOrNull!);

    final user = getResult.dataOrNull;
    if (user == null) {
      return const Failure(NotFoundException('User not found'));
    }

    final petIds = List<String>.from(user.petIds);
    if (petIds.contains(petId)) {
      return const Success(null); // Already added
    }

    petIds.add(petId);
    return updateUser(userId, {'petIds': jsonEncode(petIds)});
  }

  @override
  Future<Result<void>> removePetFromUser(String userId, String petId) async {
    debugPrint('[UserRepo] removePetFromUser: $userId, pet=$petId');

    final getResult = await getUser(userId);
    if (getResult.isFailure) return Failure(getResult.exceptionOrNull!);

    final user = getResult.dataOrNull;
    if (user == null) {
      return const Failure(NotFoundException('User not found'));
    }

    final petIds = List<String>.from(user.petIds);
    petIds.remove(petId);
    return updateUser(userId, {'petIds': jsonEncode(petIds)});
  }
}
