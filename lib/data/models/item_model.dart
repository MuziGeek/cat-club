import 'package:freezed_annotation/freezed_annotation.dart';

part 'item_model.freezed.dart';
part 'item_model.g.dart';

/// 道具类别
enum ItemCategory {
  food,
  accessory,
  clothing,
  background,
  special,
}

/// 道具稀有度
enum ItemRarity {
  common,
  rare,
  epic,
  legendary,
}

/// 货币类型
enum CurrencyType {
  coins,
  diamonds,
}

/// 道具数据模型
@freezed
class ItemModel with _$ItemModel {
  const factory ItemModel({
    required String id,
    required String name,
    required String description,
    required ItemCategory category,
    required ItemRarity rarity,
    required String imageUrl,
    required int price,
    required CurrencyType currency,

    // 效果
    @Default({}) Map<String, int> effects,

    // 限制
    List<String>? applicableSpecies,
    @Default(false) bool isLimited,
    DateTime? availableUntil,
  }) = _ItemModel;

  factory ItemModel.fromJson(Map<String, dynamic> json) =>
      _$ItemModelFromJson(json);
}

/// ItemModel 扩展方法
extension ItemModelExtension on ItemModel {
  /// 获取稀有度显示颜色（十六进制）
  int get rarityColorValue {
    switch (rarity) {
      case ItemRarity.common:
        return 0xFF9E9E9E;
      case ItemRarity.rare:
        return 0xFF2196F3;
      case ItemRarity.epic:
        return 0xFF9C27B0;
      case ItemRarity.legendary:
        return 0xFFFF9800;
    }
  }

  /// 获取稀有度名称
  String get rarityName {
    switch (rarity) {
      case ItemRarity.common:
        return '普通';
      case ItemRarity.rare:
        return '稀有';
      case ItemRarity.epic:
        return '史诗';
      case ItemRarity.legendary:
        return '传说';
    }
  }

  /// 是否为食物
  bool get isFood => category == ItemCategory.food;

  /// 是否为可装备道具
  bool get isEquippable =>
      category == ItemCategory.accessory ||
      category == ItemCategory.clothing ||
      category == ItemCategory.background;
}
