import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/item_definitions.dart';
import '../data/models/item_model.dart';
import '../services/cloudbase_service.dart';
import 'auth_provider.dart';
import 'user_provider.dart';

/// 背包状态管理 Provider
///
/// 管理用户拥有的道具及其数量
/// 数据从 CloudBase 加载，使用 ItemDefinitions 转换

/// 背包道具 Provider（从 CloudBase 加载）
/// 返回 Map<ItemModel, int>，表示道具及其数量
final inventoryProvider = FutureProvider<Map<ItemModel, int>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return {};

  final cloudbaseService = ref.watch(cloudbaseServiceProvider);
  final rawInventory = await cloudbaseService.getUserInventory(userId);

  // 如果背包为空，初始化默认背包
  if (rawInventory.isEmpty) {
    await cloudbaseService.setInitialInventory(
      userId,
      ItemDefinitions.initialInventory,
    );
    return _convertToItemModelMap(ItemDefinitions.initialInventory);
  }

  return _convertToItemModelMap(rawInventory);
});

/// 将 itemId -> quantity 转换为 ItemModel -> quantity
Map<ItemModel, int> _convertToItemModelMap(Map<String, int> rawInventory) {
  final inventory = <ItemModel, int>{};
  for (final entry in rawInventory.entries) {
    final item = ItemDefinitions.getItem(entry.key);
    if (item != null && entry.value > 0) {
      inventory[item] = entry.value;
    }
  }
  return inventory;
}

/// 背包操作 Notifier
class InventoryNotifier extends StateNotifier<Map<ItemModel, int>> {
  final CloudbaseService _cloudbaseService;
  final Ref _ref;

  InventoryNotifier(this._cloudbaseService, this._ref) : super({}) {
    _loadInventory();
  }

  /// 加载背包数据
  Future<void> _loadInventory() async {
    try {
      final userId = _ref.read(currentUserIdProvider);
      if (userId == null) return;

      final rawInventory = await _cloudbaseService.getUserInventory(userId);

      // 如果背包为空，初始化默认背包
      if (rawInventory.isEmpty) {
        await _cloudbaseService.setInitialInventory(
          userId,
          ItemDefinitions.initialInventory,
        );
        state = _convertToItemModelMap(ItemDefinitions.initialInventory);
        return;
      }

      state = _convertToItemModelMap(rawInventory);
    } catch (e) {
      debugPrint('加载背包失败: $e');
    }
  }

  /// 刷新背包数据
  Future<void> refresh() async {
    await _loadInventory();
  }

  /// 使用道具
  /// 返回 true 表示使用成功
  bool useItem(ItemModel item) {
    final currentQty = state[item] ?? 0;
    if (currentQty <= 0) return false;

    // 先更新本地状态（乐观更新）
    final newState = Map<ItemModel, int>.from(state);
    if (currentQty == 1) {
      newState.remove(item);
    } else {
      newState[item] = currentQty - 1;
    }
    state = newState;

    // 异步同步到 CloudBase
    _syncUseItem(item);

    return true;
  }

  /// 同步使用道具到 CloudBase
  Future<void> _syncUseItem(ItemModel item) async {
    try {
      final userId = _ref.read(currentUserIdProvider);
      if (userId == null) return;

      final success = await _cloudbaseService.useInventoryItem(userId, item.id);
      if (!success) {
        // 如果 CloudBase 操作失败，重新加载背包
        await _loadInventory();
      }
    } catch (e) {
      debugPrint('同步使用道具失败: $e');
      // 失败时重新加载
      await _loadInventory();
    }
  }

  /// 添加道具
  void addItem(ItemModel item, {int quantity = 1}) {
    // 先更新本地状态
    final newState = Map<ItemModel, int>.from(state);
    newState[item] = (newState[item] ?? 0) + quantity;
    state = newState;

    // 异步同步到 CloudBase
    _syncAddItem(item, quantity);
  }

  /// 同步添加道具到 CloudBase
  Future<void> _syncAddItem(ItemModel item, int quantity) async {
    try {
      final userId = _ref.read(currentUserIdProvider);
      if (userId == null) return;

      await _cloudbaseService.addInventoryItem(userId, item.id, quantity);
    } catch (e) {
      debugPrint('同步添加道具失败: $e');
      await _loadInventory();
    }
  }

  /// 获取道具数量
  int getQuantity(ItemModel item) {
    return state[item] ?? 0;
  }
}

/// 背包操作 Provider
final inventoryNotifierProvider =
    StateNotifierProvider<InventoryNotifier, Map<ItemModel, int>>((ref) {
  final cloudbaseService = ref.watch(cloudbaseServiceProvider);
  return InventoryNotifier(cloudbaseService, ref);
});
