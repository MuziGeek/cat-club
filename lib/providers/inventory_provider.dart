import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/item_model.dart';

/// 背包状态管理 Provider
///
/// 管理用户拥有的道具及其数量
/// 后期可接入 Firestore 持久化

/// 背包道具 Provider
/// 返回 Map<ItemModel, int>，表示道具及其数量
final inventoryProvider = FutureProvider<Map<ItemModel, int>>((ref) async {
  // TODO: 后期从 Firestore 加载用户背包
  // 目前返回模拟数据用于测试

  // 模拟延迟
  await Future.delayed(const Duration(milliseconds: 300));

  return _mockInventory;
});

/// 模拟背包数据
final Map<ItemModel, int> _mockInventory = {
  // 食物类
  const ItemModel(
    id: 'food_fish',
    name: '小鱼干',
    description: '猫咪最爱的零食，恢复饱腹度',
    category: ItemCategory.food,
    rarity: ItemRarity.common,
    imageUrl: '',
    price: 10,
    currency: CurrencyType.coins,
    effects: {'hunger': 20, 'happiness': 5},
  ): 5,

  const ItemModel(
    id: 'food_premium_fish',
    name: '高级鱼罐头',
    description: '进口优质鱼肉，大幅恢复饱腹度',
    category: ItemCategory.food,
    rarity: ItemRarity.rare,
    imageUrl: '',
    price: 50,
    currency: CurrencyType.coins,
    effects: {'hunger': 40, 'happiness': 15},
  ): 2,

  const ItemModel(
    id: 'food_treat',
    name: '美味肉条',
    description: '香喷喷的肉条零食',
    category: ItemCategory.food,
    rarity: ItemRarity.common,
    imageUrl: '',
    price: 15,
    currency: CurrencyType.coins,
    effects: {'hunger': 15, 'happiness': 10},
  ): 3,

  // 清洁道具
  const ItemModel(
    id: 'clean_towel',
    name: '柔软毛巾',
    description: '温柔擦拭，恢复清洁度',
    category: ItemCategory.special,
    rarity: ItemRarity.common,
    imageUrl: '',
    price: 20,
    currency: CurrencyType.coins,
    effects: {'cleanliness': 25, 'happiness': 10},
  ): 3,

  const ItemModel(
    id: 'clean_brush',
    name: '美容刷',
    description: '专业美容刷，让毛发更顺滑',
    category: ItemCategory.special,
    rarity: ItemRarity.rare,
    imageUrl: '',
    price: 80,
    currency: CurrencyType.coins,
    effects: {'cleanliness': 40, 'happiness': 20, 'health': 5},
  ): 1,
};

/// 背包操作 Notifier
class InventoryNotifier extends StateNotifier<Map<ItemModel, int>> {
  InventoryNotifier() : super({..._mockInventory});

  /// 使用道具
  bool useItem(ItemModel item) {
    final currentQty = state[item] ?? 0;
    if (currentQty <= 0) return false;

    final newState = Map<ItemModel, int>.from(state);
    if (currentQty == 1) {
      newState.remove(item);
    } else {
      newState[item] = currentQty - 1;
    }

    state = newState;
    return true;
  }

  /// 添加道具
  void addItem(ItemModel item, {int quantity = 1}) {
    final newState = Map<ItemModel, int>.from(state);
    newState[item] = (newState[item] ?? 0) + quantity;
    state = newState;
  }

  /// 获取道具数量
  int getQuantity(ItemModel item) {
    return state[item] ?? 0;
  }
}

/// 背包操作 Provider
final inventoryNotifierProvider =
    StateNotifierProvider<InventoryNotifier, Map<ItemModel, int>>((ref) {
  return InventoryNotifier();
});
