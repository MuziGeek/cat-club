import 'achievement_model.dart';

/// 成就定义配置
///
/// 包含所有可解锁成就的静态配置
class AchievementDefinitions {
  AchievementDefinitions._();

  /// 所有成就定义
  static const Map<String, AchievementModel> achievements = {
    // ========== 互动类成就 ==========
    'first_pet': AchievementModel(
      id: 'first_pet',
      name: '初次相遇',
      description: '第一次抚摸你的宠物',
      icon: 'favorite',
      category: AchievementCategory.interaction,
      type: AchievementType.petCount,
      targetValue: 1,
      reward: AchievementReward(coins: 50),
    ),
    'pet_master': AchievementModel(
      id: 'pet_master',
      name: '抚摸大师',
      description: '抚摸宠物100次',
      icon: 'pets',
      category: AchievementCategory.interaction,
      type: AchievementType.petCount,
      targetValue: 100,
      reward: AchievementReward(coins: 200),
    ),
    'first_feed': AchievementModel(
      id: 'first_feed',
      name: '初次喂食',
      description: '第一次喂食宠物',
      icon: 'restaurant',
      category: AchievementCategory.interaction,
      type: AchievementType.feedCount,
      targetValue: 1,
      reward: AchievementReward(coins: 30),
    ),
    'feed_master': AchievementModel(
      id: 'feed_master',
      name: '喂食达人',
      description: '喂食宠物50次',
      icon: 'restaurant_menu',
      category: AchievementCategory.interaction,
      type: AchievementType.feedCount,
      targetValue: 50,
      reward: AchievementReward(coins: 150),
    ),
    'play_master': AchievementModel(
      id: 'play_master',
      name: '玩耍达人',
      description: '和宠物玩耍30次',
      icon: 'sports_esports',
      category: AchievementCategory.interaction,
      type: AchievementType.playCount,
      targetValue: 30,
      reward: AchievementReward(coins: 100),
    ),
    'clean_master': AchievementModel(
      id: 'clean_master',
      name: '清洁达人',
      description: '为宠物清洁20次',
      icon: 'bathtub',
      category: AchievementCategory.interaction,
      type: AchievementType.cleanCount,
      targetValue: 20,
      reward: AchievementReward(coins: 80),
    ),

    // ========== 成长类成就 ==========
    'level_5': AchievementModel(
      id: 'level_5',
      name: '初出茅庐',
      description: '宠物升到5级',
      icon: 'star',
      category: AchievementCategory.growth,
      type: AchievementType.level,
      targetValue: 5,
      reward: AchievementReward(coins: 100),
    ),
    'level_10': AchievementModel(
      id: 'level_10',
      name: '小有成就',
      description: '宠物升到10级',
      icon: 'star_half',
      category: AchievementCategory.growth,
      type: AchievementType.level,
      targetValue: 10,
      reward: AchievementReward(diamonds: 5),
    ),
    'level_20': AchievementModel(
      id: 'level_20',
      name: '炉火纯青',
      description: '宠物升到20级',
      icon: 'stars',
      category: AchievementCategory.growth,
      type: AchievementType.level,
      targetValue: 20,
      reward: AchievementReward(diamonds: 15),
    ),
    'intimacy_50': AchievementModel(
      id: 'intimacy_50',
      name: '渐入佳境',
      description: '亲密度达到50',
      icon: 'favorite_border',
      category: AchievementCategory.growth,
      type: AchievementType.intimacy,
      targetValue: 50,
      reward: AchievementReward(coins: 80),
    ),
    'intimacy_100': AchievementModel(
      id: 'intimacy_100',
      name: '亲密无间',
      description: '亲密度达到100',
      icon: 'favorite',
      category: AchievementCategory.growth,
      type: AchievementType.intimacy,
      targetValue: 100,
      reward: AchievementReward(diamonds: 10),
    ),

    // ========== 签到类成就 ==========
    'check_in_3': AchievementModel(
      id: 'check_in_3',
      name: '三天打鱼',
      description: '连续签到3天',
      icon: 'calendar_today',
      category: AchievementCategory.checkIn,
      type: AchievementType.checkInStreak,
      targetValue: 3,
      reward: AchievementReward(coins: 50),
    ),
    'check_in_7': AchievementModel(
      id: 'check_in_7',
      name: '坚持不懈',
      description: '连续签到7天',
      icon: 'event_available',
      category: AchievementCategory.checkIn,
      type: AchievementType.checkInStreak,
      targetValue: 7,
      reward: AchievementReward(
        coins: 100,
        items: {'premium_fish': 1},
      ),
    ),
    'check_in_30': AchievementModel(
      id: 'check_in_30',
      name: '持之以恒',
      description: '累计签到30天',
      icon: 'event_note',
      category: AchievementCategory.checkIn,
      type: AchievementType.checkInTotal,
      targetValue: 30,
      reward: AchievementReward(diamonds: 20),
    ),

    // ========== 收集类成就 ==========
    'item_5': AchievementModel(
      id: 'item_5',
      name: '初级收藏家',
      description: '拥有5种不同道具',
      icon: 'inventory_2',
      category: AchievementCategory.collection,
      type: AchievementType.itemTypeCount,
      targetValue: 5,
      reward: AchievementReward(coins: 60),
    ),
    'item_10': AchievementModel(
      id: 'item_10',
      name: '道具达人',
      description: '拥有10种不同道具',
      icon: 'backpack',
      category: AchievementCategory.collection,
      type: AchievementType.itemTypeCount,
      targetValue: 10,
      reward: AchievementReward(diamonds: 10),
    ),
    'multi_pet': AchievementModel(
      id: 'multi_pet',
      name: '宠物大家庭',
      description: '拥有3只宠物',
      icon: 'groups',
      category: AchievementCategory.collection,
      type: AchievementType.petOwned,
      targetValue: 3,
      reward: AchievementReward(coins: 150),
    ),
  };

  /// 获取所有成就列表
  static List<AchievementModel> get all => achievements.values.toList();

  /// 根据ID获取成就
  static AchievementModel? getById(String id) => achievements[id];

  /// 根据类别获取成就
  static List<AchievementModel> getByCategory(AchievementCategory category) {
    return achievements.values
        .where((a) => a.category == category)
        .toList();
  }

  /// 根据触发类型获取成就
  static List<AchievementModel> getByType(AchievementType type) {
    return achievements.values
        .where((a) => a.type == type)
        .toList();
  }

  /// 获取成就总数
  static int get totalCount => achievements.length;

  /// 获取各类别成就数量
  static Map<AchievementCategory, int> get countByCategory {
    final result = <AchievementCategory, int>{};
    for (final category in AchievementCategory.values) {
      result[category] = getByCategory(category).length;
    }
    return result;
  }
}

/// AchievementCategory 扩展 - 显示名称
extension AchievementCategoryX on AchievementCategory {
  String get displayName {
    switch (this) {
      case AchievementCategory.interaction:
        return '互动';
      case AchievementCategory.growth:
        return '成长';
      case AchievementCategory.checkIn:
        return '签到';
      case AchievementCategory.collection:
        return '收集';
    }
  }

  String get icon {
    switch (this) {
      case AchievementCategory.interaction:
        return 'touch_app';
      case AchievementCategory.growth:
        return 'trending_up';
      case AchievementCategory.checkIn:
        return 'calendar_month';
      case AchievementCategory.collection:
        return 'collections';
    }
  }
}
