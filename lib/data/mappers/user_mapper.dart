import 'dart:convert';

import '../../core/utils/type_converters.dart';
import '../../data/models/user_model.dart';

/// 用户数据映射器
///
/// 负责 UserModel 与 CloudBase MySQL 数据之间的转换
class UserMapper {
  UserMapper._();

  /// CloudBase 数据 -> UserModel
  static UserModel fromCloudbase(Map<String, dynamic> data, String id) {
    return UserModel(
      id: id,
      email: TypeConverters.parseString(data['email']),
      phone: TypeConverters.parseString(data['phone']),
      displayName: TypeConverters.parseString(data['displayName']),
      avatarUrl: TypeConverters.parseString(data['avatarUrl']),
      coins: TypeConverters.parseInt(data['coins'], fallback: 0),
      diamonds: TypeConverters.parseInt(data['diamonds'], fallback: 0),
      petIds: TypeConverters.parseStringList(data['petIds']),
      maxPets: TypeConverters.parseInt(data['maxPets'], fallback: 4),
      inventory: TypeConverters.parseIntMap(data['inventory']),
      achievements: TypeConverters.parseStringList(data['achievements']),
      following: TypeConverters.parseStringList(data['following']),
      followers: TypeConverters.parseStringList(data['followers']),
      consecutiveDays: TypeConverters.parseInt(data['consecutiveDays'], fallback: 0),
      lastSignInDate: TypeConverters.parseDateTimeNullable(data['lastSignInDate']),
      createdAt: TypeConverters.parseDateTime(data['createdAt']),
    );
  }

  /// UserModel -> CloudBase 数据
  ///
  /// 注意：JSON 字段需要编码为字符串格式存储到 MySQL
  static Map<String, dynamic> toCloudbase(UserModel user) {
    return {
      'id': user.id,
      'email': user.email,
      'phone': user.phone,
      'displayName': user.displayName,
      'avatarUrl': user.avatarUrl,
      'coins': user.coins,
      'diamonds': user.diamonds,
      'petIds': jsonEncode(user.petIds),
      'maxPets': user.maxPets,
      'inventory': jsonEncode(user.inventory),
      'achievements': jsonEncode(user.achievements),
      'following': jsonEncode(user.following),
      'followers': jsonEncode(user.followers),
      'consecutiveDays': user.consecutiveDays,
      'lastSignInDate': user.lastSignInDate?.toIso8601String(),
      'createdAt': user.createdAt.toIso8601String(),
    };
  }

  /// 创建默认新用户数据
  static UserModel createDefault(String userId) {
    return UserModel(
      id: userId,
      coins: 100,
      diamonds: 10,
      petIds: const [],
      maxPets: 4,
      inventory: const {'food_basic': 5, 'toy_ball': 1},
      achievements: const [],
      following: const [],
      followers: const [],
      consecutiveDays: 0,
      createdAt: DateTime.now(),
    );
  }

  /// 生成部分更新数据（仅包含非空字段）
  static Map<String, dynamic> toPartialUpdate({
    String? displayName,
    String? avatarUrl,
    int? coins,
    int? diamonds,
    List<String>? petIds,
    int? maxPets,
    Map<String, int>? inventory,
    List<String>? achievements,
    int? consecutiveDays,
    DateTime? lastSignInDate,
  }) {
    final data = <String, dynamic>{};

    if (displayName != null) data['displayName'] = displayName;
    if (avatarUrl != null) data['avatarUrl'] = avatarUrl;
    if (coins != null) data['coins'] = coins;
    if (diamonds != null) data['diamonds'] = diamonds;
    if (petIds != null) data['petIds'] = jsonEncode(petIds);
    if (maxPets != null) data['maxPets'] = maxPets;
    if (inventory != null) data['inventory'] = jsonEncode(inventory);
    if (achievements != null) data['achievements'] = jsonEncode(achievements);
    if (consecutiveDays != null) data['consecutiveDays'] = consecutiveDays;
    if (lastSignInDate != null) {
      data['lastSignInDate'] = lastSignInDate.toIso8601String();
    }

    return data;
  }
}
