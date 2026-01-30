import 'package:freezed_annotation/freezed_annotation.dart';

part 'pet_model.freezed.dart';
part 'pet_model.g.dart';

/// 宠物物种枚举
enum PetSpecies {
  cat,
  dog,
  rabbit,
  hamster,
  bird,
  other,
}

/// 宠物外观
@freezed
class PetAppearance with _$PetAppearance {
  const factory PetAppearance({
    required String furColor,
    String? furPattern,
    required String eyeColor,
    String? specialMarks,
  }) = _PetAppearance;

  factory PetAppearance.fromJson(Map<String, dynamic> json) =>
      _$PetAppearanceFromJson(json);
}

/// 宠物状态值
@freezed
class PetStatus with _$PetStatus {
  const factory PetStatus({
    @Default(100) int happiness,
    @Default(100) int hunger,
    @Default(100) int energy,
    @Default(100) int health,
    @Default(100) int cleanliness,
  }) = _PetStatus;

  factory PetStatus.fromJson(Map<String, dynamic> json) =>
      _$PetStatusFromJson(json);
}

/// 宠物成长数据
@freezed
class PetStats with _$PetStats {
  const factory PetStats({
    @Default(1) int level,
    @Default(0) int experience,
    @Default(0) int intimacy,
    @Default(0) int totalFeedings,
    @Default(0) int totalInteractions,
  }) = _PetStats;

  factory PetStats.fromJson(Map<String, dynamic> json) =>
      _$PetStatsFromJson(json);
}

/// 宠物数据模型
@freezed
class PetModel with _$PetModel {
  const factory PetModel({
    required String id,
    required String userId,
    required String name,
    required PetSpecies species,
    String? breed,

    // 外观
    required PetAppearance appearance,

    // 图片
    String? originalPhotoUrl,
    String? cartoonAvatarUrl,
    @Default([]) List<String> generatedAvatars,

    // 状态
    required PetStatus status,

    // 成长数据
    required PetStats stats,

    // 装备
    @Default([]) List<String> equippedItems,
    @Default([]) List<String> ownedItems,

    // 纪念模式
    @Default(false) bool isMemorial,
    String? memorialNote,
    DateTime? memorialDate,

    // 时间戳
    required DateTime createdAt,
    required DateTime updatedAt,
    required DateTime lastInteractionAt,
  }) = _PetModel;

  factory PetModel.fromJson(Map<String, dynamic> json) =>
      _$PetModelFromJson(json);
}

/// PetModel 扩展方法
extension PetModelExtension on PetModel {
  /// 计算升级所需经验
  int get expToNextLevel {
    if (stats.level < 10) return 100 * stats.level;
    if (stats.level < 30) return 200 * stats.level;
    if (stats.level < 50) return 350 * stats.level;
    if (stats.level < 70) return 500 * stats.level;
    return 800 * stats.level;
  }

  /// 获取亲密度等级名称
  String get intimacyLevelName {
    final intimacy = stats.intimacy;
    if (intimacy < 500) return '初识';
    if (intimacy < 1500) return '熟悉';
    if (intimacy < 3000) return '亲近';
    if (intimacy < 5000) return '信赖';
    if (intimacy < 7500) return '挚友';
    return '灵魂伴侣';
  }

  /// 获取整体心情描述
  String get moodDescription {
    final avgStatus = (status.happiness + status.hunger + status.energy) ~/ 3;
    if (avgStatus >= 80) return '非常开心';
    if (avgStatus >= 60) return '心情不错';
    if (avgStatus >= 40) return '有点无聊';
    if (avgStatus >= 20) return '需要关爱';
    return '很不开心';
  }
}
