import '../../core/exceptions/cloudbase_exception.dart';
import '../../data/models/achievement_model.dart';

/// 成就仓库接口
///
/// 定义成就相关的数据操作契约
abstract class AchievementRepository {
  /// 获取用户所有成就进度
  Future<Result<List<UserAchievement>>> getUserAchievements(String userId);

  /// 成就进度流
  Stream<List<UserAchievement>> userAchievementsStream(String userId);

  /// 更新成就进度
  Future<Result<void>> updateProgress({
    required String userId,
    required String achievementId,
    required int currentValue,
  });

  /// 解锁成就
  Future<Result<void>> unlock({
    required String userId,
    required String achievementId,
    required int currentValue,
  });

  /// 领取成就奖励
  Future<Result<void>> claimReward({
    required String userId,
    required String achievementId,
    required AchievementReward reward,
  });
}
