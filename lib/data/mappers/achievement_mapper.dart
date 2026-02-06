import '../../core/utils/type_converters.dart';
import '../../data/models/achievement_model.dart';

/// 成就数据映射器
///
/// 负责 UserAchievement 与 CloudBase MySQL 数据之间的转换
class AchievementMapper {
  AchievementMapper._();

  /// CloudBase 数据 -> UserAchievement
  static UserAchievement fromCloudbase(Map<String, dynamic> data, String id) {
    return UserAchievement(
      achievementId: data['achievementId'] as String? ?? id,
      currentValue: TypeConverters.parseInt(data['currentValue'], fallback: 0),
      isUnlocked: TypeConverters.parseBool(data['isUnlocked']),
      unlockedAt: TypeConverters.parseDateTimeNullable(data['unlockedAt']),
      isRewardClaimed: TypeConverters.parseBool(data['isRewardClaimed']),
      claimedAt: TypeConverters.parseDateTimeNullable(data['claimedAt']),
    );
  }

  /// 创建新成就进度记录
  static Map<String, dynamic> toCloudbase({
    required String odId,
    required String oderId,
    required String achievementId,
    required int currentValue,
    required bool isUnlocked,
    DateTime? unlockedAt,
  }) {
    return {
      'id': odId,
      'userId': oderId,
      'achievementId': achievementId,
      'currentValue': currentValue,
      'isUnlocked': isUnlocked ? 1 : 0, // MySQL tinyint(1)
      'unlockedAt': unlockedAt?.toIso8601String(),
      'isRewardClaimed': 0,
      'claimedAt': null,
    };
  }

  /// 更新成就进度
  static Map<String, dynamic> toProgressUpdate(int currentValue) {
    return {
      'currentValue': currentValue,
    };
  }

  /// 标记成就已解锁
  static Map<String, dynamic> toUnlockUpdate(int currentValue) {
    return {
      'currentValue': currentValue,
      'isUnlocked': 1,
      'unlockedAt': DateTime.now().toIso8601String(),
    };
  }

  /// 标记奖励已领取
  static Map<String, dynamic> toClaimUpdate() {
    return {
      'isRewardClaimed': 1,
      'claimedAt': DateTime.now().toIso8601String(),
    };
  }
}
