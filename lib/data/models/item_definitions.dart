import 'item_model.dart';

/// 道具定义 - 静态配置
///
/// 所有道具的静态定义，用于：
/// 1. Firestore 中仅存储 itemId -> quantity
/// 2. 客户端根据 itemId 查找完整道具信息
class ItemDefinitions {
  ItemDefinitions._();

  /// 所有道具定义
  static const Map<String, ItemModel> items = {
    // === 食物类 ===
    'food_fish': ItemModel(
      id: 'food_fish',
      name: '小鱼干',
      description: '猫咪最爱的零食，恢复饱腹度',
      category: ItemCategory.food,
      rarity: ItemRarity.common,
      imageUrl: '',
      price: 10,
      currency: CurrencyType.coins,
      effects: {'hunger': 20, 'happiness': 5},
    ),
    'food_premium_fish': ItemModel(
      id: 'food_premium_fish',
      name: '高级鱼罐头',
      description: '进口优质鱼肉，大幅恢复饱腹度',
      category: ItemCategory.food,
      rarity: ItemRarity.rare,
      imageUrl: '',
      price: 50,
      currency: CurrencyType.coins,
      effects: {'hunger': 40, 'happiness': 15},
    ),
    'food_treat': ItemModel(
      id: 'food_treat',
      name: '美味肉条',
      description: '香喷喷的肉条零食',
      category: ItemCategory.food,
      rarity: ItemRarity.common,
      imageUrl: '',
      price: 15,
      currency: CurrencyType.coins,
      effects: {'hunger': 15, 'happiness': 10},
    ),
    'food_premium_meal': ItemModel(
      id: 'food_premium_meal',
      name: '豪华大餐',
      description: '精心烹制的宠物美食，全面恢复状态',
      category: ItemCategory.food,
      rarity: ItemRarity.epic,
      imageUrl: '',
      price: 100,
      currency: CurrencyType.coins,
      effects: {'hunger': 60, 'happiness': 25, 'health': 10},
    ),

    // === 清洁道具 ===
    'clean_towel': ItemModel(
      id: 'clean_towel',
      name: '柔软毛巾',
      description: '温柔擦拭，恢复清洁度',
      category: ItemCategory.special,
      rarity: ItemRarity.common,
      imageUrl: '',
      price: 20,
      currency: CurrencyType.coins,
      effects: {'cleanliness': 25, 'happiness': 10},
    ),
    'clean_brush': ItemModel(
      id: 'clean_brush',
      name: '美容刷',
      description: '专业美容刷，让毛发更顺滑',
      category: ItemCategory.special,
      rarity: ItemRarity.rare,
      imageUrl: '',
      price: 80,
      currency: CurrencyType.coins,
      effects: {'cleanliness': 40, 'happiness': 20, 'health': 5},
    ),
    'clean_shampoo': ItemModel(
      id: 'clean_shampoo',
      name: '香氛沐浴露',
      description: '散发清香的沐浴露，深度清洁',
      category: ItemCategory.special,
      rarity: ItemRarity.rare,
      imageUrl: '',
      price: 60,
      currency: CurrencyType.coins,
      effects: {'cleanliness': 50, 'happiness': 15},
    ),

    // === 特殊道具 ===
    'special_energy_drink': ItemModel(
      id: 'special_energy_drink',
      name: '活力饮料',
      description: '快速恢复精力的神奇饮品',
      category: ItemCategory.special,
      rarity: ItemRarity.rare,
      imageUrl: '',
      price: 30,
      currency: CurrencyType.diamonds,
      effects: {'energy': 50, 'happiness': 10},
    ),
    'special_health_potion': ItemModel(
      id: 'special_health_potion',
      name: '健康药水',
      description: '恢复宠物健康值',
      category: ItemCategory.special,
      rarity: ItemRarity.epic,
      imageUrl: '',
      price: 50,
      currency: CurrencyType.diamonds,
      effects: {'health': 40, 'energy': 20},
    ),
  };

  /// 根据 ID 获取道具
  static ItemModel? getItem(String id) => items[id];

  /// 获取所有食物类道具
  static List<ItemModel> get foodItems =>
      items.values.where((item) => item.category == ItemCategory.food).toList();

  /// 获取所有清洁类道具
  static List<ItemModel> get cleanItems =>
      items.values.where((item) => item.category == ItemCategory.special).toList();

  /// 获取指定类别的道具
  static List<ItemModel> getItemsByCategory(ItemCategory category) =>
      items.values.where((item) => item.category == category).toList();

  /// 获取指定稀有度的道具
  static List<ItemModel> getItemsByRarity(ItemRarity rarity) =>
      items.values.where((item) => item.rarity == rarity).toList();

  /// 新用户初始背包
  static const Map<String, int> initialInventory = {
    'food_fish': 5,
    'food_treat': 3,
    'clean_towel': 3,
    'clean_brush': 1,
  };
}
