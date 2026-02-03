import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

/// 用户设置
@freezed
class UserSettings with _$UserSettings {
  const factory UserSettings({
    @Default(true) bool notificationsEnabled,
    @Default(true) bool soundEnabled,
    @Default('zh') String language,
    @Default('light') String theme,
  }) = _UserSettings;

  factory UserSettings.fromJson(Map<String, dynamic> json) =>
      _$UserSettingsFromJson(json);
}

/// 用户数据模型
@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    String? email,
    String? displayName,
    String? avatarUrl,

    // 货币
    @Default(0) int coins,
    @Default(0) int diamonds,

    // 宠物
    @Default([]) List<String> petIds,
    @Default(4) int maxPets, // 宠物数量上限，默认4只

    // 背包 - itemId -> quantity
    @Default({}) Map<String, int> inventory,

    // 成就
    @Default([]) List<String> achievements,

    // 社交
    @Default([]) List<String> following,
    @Default([]) List<String> followers,

    // 签到
    @Default(0) int consecutiveDays,
    DateTime? lastSignInDate,

    // 设置
    @Default(UserSettings()) UserSettings settings,

    // 时间戳
    required DateTime createdAt,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}

/// UserModel 扩展方法
extension UserModelExtension on UserModel {
  /// 是否今日已签到
  bool get hasSignedInToday {
    if (lastSignInDate == null) return false;
    final now = DateTime.now();
    return lastSignInDate!.year == now.year &&
        lastSignInDate!.month == now.month &&
        lastSignInDate!.day == now.day;
  }

  /// 用户显示名称
  String get displayNameOrDefault => displayName ?? '宠物主人';
}
