import 'package:freezed_annotation/freezed_annotation.dart';

part 'achievement_model.freezed.dart';
part 'achievement_model.g.dart';

/// 成就类别
enum AchievementCategory {
  /// 互动类成就
  interaction,
  /// 成长类成就
  growth,
  /// 签到类成就
  checkIn,
  /// 收集类成就
  collection,
}

/// 成就触发类型
enum AchievementType {
  /// 抚摸次数
  petCount,
  /// 喂食次数
  feedCount,
  /// 玩耍次数
  playCount,
  /// 宠物等级
  level,
  /// 亲密度
  intimacy,
  /// 连续签到天数
  checkInStreak,
  /// 累计签到天数
  checkInTotal,
  /// 道具种类数量
  itemTypeCount,
  /// 宠物数量
  petOwned,
  /// 清洁次数
  cleanCount,
}

/// 成就奖励模型
@freezed
class AchievementReward with _$AchievementReward {
  const factory AchievementReward({
    /// 金币奖励
    @Default(0) int coins,
    /// 钻石奖励
    @Default(0) int diamonds,
    /// 道具奖励 (道具ID -> 数量)
    @Default({}) Map<String, int> items,
  }) = _AchievementReward;

  factory AchievementReward.fromJson(Map<String, dynamic> json) =>
      _$AchievementRewardFromJson(json);
}

/// 成就定义模型（静态配置）
@freezed
class AchievementModel with _$AchievementModel {
  const factory AchievementModel({
    /// 成就唯一标识
    required String id,
    /// 成就名称
    required String name,
    /// 成就描述
    required String description,
    /// 成就图标（Material Icons 名称）
    required String icon,
    /// 成就类别
    required AchievementCategory category,
    /// 触发类型
    required AchievementType type,
    /// 目标值
    required int targetValue,
    /// 奖励
    required AchievementReward reward,
  }) = _AchievementModel;

  factory AchievementModel.fromJson(Map<String, dynamic> json) =>
      _$AchievementModelFromJson(json);
}

/// 用户成就进度模型（存储在 Firestore）
@freezed
class UserAchievement with _$UserAchievement {
  const factory UserAchievement({
    /// 成就ID
    required String achievementId,
    /// 当前进度值
    @Default(0) int currentValue,
    /// 是否已解锁
    @Default(false) bool isUnlocked,
    /// 解锁时间
    DateTime? unlockedAt,
    /// 是否已领取奖励
    @Default(false) bool isRewardClaimed,
    /// 领取奖励时间
    DateTime? claimedAt,
  }) = _UserAchievement;

  factory UserAchievement.fromJson(Map<String, dynamic> json) =>
      _$UserAchievementFromJson(json);
}

/// UserAchievement 扩展方法
extension UserAchievementX on UserAchievement {
  /// 检查是否可以领取奖励
  bool get canClaimReward => isUnlocked && !isRewardClaimed;
}
