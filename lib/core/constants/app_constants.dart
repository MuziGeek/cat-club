/// 应用常量定义
class AppConstants {
  AppConstants._();

  // 应用信息
  static const String appName = 'Cat Club';
  static const String appVersion = '1.0.0';

  // 状态值范围
  static const int statusMin = 0;
  static const int statusMax = 100;

  // 等级范围
  static const int levelMin = 1;
  static const int levelMax = 99;

  // 亲密度范围
  static const int intimacyMin = 0;
  static const int intimacyMax = 10000;

  // 状态衰减速率（分钟）
  static const int hungerDecayMinutes = 30;
  static const int happinessDecayMinutes = 60;
  static const int energyDecayMinutes = 45;
  static const int healthDecayMinutes = 120;

  // 互动冷却时间（分钟）
  static const int feedingCooldownMinutes = 10;
  static const int pettingCooldownMinutes = 5;

  // 经验值
  static const int feedingExp = 10;
  static const int pettingExp = 5;
  static const int dailySignInExp = 50;

  // AI 生成
  static const int maxGeneratedAvatars = 4;
  static const int maxPhotoSizeMB = 10;

  // 分页
  static const int defaultPageSize = 20;

  // 动画时长
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
}
