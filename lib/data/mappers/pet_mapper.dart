import 'dart:convert';

import '../../core/utils/type_converters.dart';
import '../../data/models/pet_model.dart';

/// 宠物数据映射器
///
/// 负责 PetModel 与 CloudBase MySQL 数据之间的转换
class PetMapper {
  PetMapper._();

  /// CloudBase 数据 -> PetModel
  static PetModel fromCloudbase(Map<String, dynamic> data, String id) {
    final appearanceData = TypeConverters.parseJsonMap(data['appearance']);
    final statusData = TypeConverters.parseJsonMap(data['status']);
    final statsData = TypeConverters.parseJsonMap(data['stats']);

    return PetModel(
      id: id,
      userId: data['userId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      species: _parseSpecies(data['species']),
      breed: TypeConverters.parseString(data['breed']),
      appearance: PetAppearance(
        furColor: appearanceData['furColor'] as String? ?? 'orange',
        furPattern: appearanceData['furPattern'] as String?,
        eyeColor: appearanceData['eyeColor'] as String? ?? 'yellow',
        specialMarks: appearanceData['specialMarks'] as String?,
      ),
      originalPhotoUrl: TypeConverters.parseString(data['originalPhotoUrl']),
      cartoonAvatarUrl: TypeConverters.parseString(data['cartoonAvatarUrl']),
      generatedAvatars: TypeConverters.parseStringList(data['generatedAvatars']),
      status: PetStatus(
        happiness: TypeConverters.parseInt(statusData['happiness'], fallback: 100),
        hunger: TypeConverters.parseInt(statusData['hunger'], fallback: 100),
        energy: TypeConverters.parseInt(statusData['energy'], fallback: 100),
        health: TypeConverters.parseInt(statusData['health'], fallback: 100),
        cleanliness: TypeConverters.parseInt(statusData['cleanliness'], fallback: 100),
      ),
      stats: PetStats(
        level: TypeConverters.parseInt(statsData['level'], fallback: 1),
        experience: TypeConverters.parseInt(statsData['experience'], fallback: 0),
        intimacy: TypeConverters.parseInt(statsData['intimacy'], fallback: 0),
        totalFeedings: TypeConverters.parseInt(statsData['totalFeedings'], fallback: 0),
        totalInteractions: TypeConverters.parseInt(statsData['totalInteractions'], fallback: 0),
      ),
      equippedItems: TypeConverters.parseStringList(data['equippedItems']),
      ownedItems: TypeConverters.parseStringList(data['ownedItems']),
      isMemorial: TypeConverters.parseBool(data['isMemorial']),
      memorialNote: TypeConverters.parseString(data['memorialNote']),
      memorialDate: TypeConverters.parseDateTimeNullable(data['memorialDate']),
      createdAt: TypeConverters.parseDateTime(data['createdAt']),
      updatedAt: TypeConverters.parseDateTime(data['updatedAt']),
      lastInteractionAt: TypeConverters.parseDateTime(data['lastInteractionAt']),
    );
  }

  /// PetModel -> CloudBase 数据
  ///
  /// 注意：JSON 字段需要编码为字符串格式存储到 MySQL
  static Map<String, dynamic> toCloudbase(PetModel pet) {
    return {
      'id': pet.id,
      'userId': pet.userId,
      'name': pet.name,
      'species': pet.species.name,
      'breed': pet.breed,
      'appearance': jsonEncode({
        'furColor': pet.appearance.furColor,
        'furPattern': pet.appearance.furPattern,
        'eyeColor': pet.appearance.eyeColor,
        'specialMarks': pet.appearance.specialMarks,
      }),
      'originalPhotoUrl': pet.originalPhotoUrl,
      'cartoonAvatarUrl': pet.cartoonAvatarUrl,
      'generatedAvatars': jsonEncode(pet.generatedAvatars),
      'status': jsonEncode({
        'happiness': pet.status.happiness,
        'hunger': pet.status.hunger,
        'energy': pet.status.energy,
        'health': pet.status.health,
        'cleanliness': pet.status.cleanliness,
      }),
      'stats': jsonEncode({
        'level': pet.stats.level,
        'experience': pet.stats.experience,
        'intimacy': pet.stats.intimacy,
        'totalFeedings': pet.stats.totalFeedings,
        'totalInteractions': pet.stats.totalInteractions,
      }),
      'equippedItems': jsonEncode(pet.equippedItems),
      'ownedItems': jsonEncode(pet.ownedItems),
      'isMemorial': pet.isMemorial ? 1 : 0, // MySQL tinyint(1)
      'memorialNote': pet.memorialNote,
      'memorialDate': pet.memorialDate?.toIso8601String(),
      'createdAt': pet.createdAt.toIso8601String(),
      'updatedAt': pet.updatedAt.toIso8601String(),
      'lastInteractionAt': pet.lastInteractionAt.toIso8601String(),
    };
  }

  /// 生成状态更新数据
  static Map<String, dynamic> toStatusUpdate(PetStatus status) {
    return {
      'status': jsonEncode({
        'happiness': status.happiness,
        'hunger': status.hunger,
        'energy': status.energy,
        'health': status.health,
        'cleanliness': status.cleanliness,
      }),
      'updatedAt': DateTime.now().toIso8601String(),
      'lastInteractionAt': DateTime.now().toIso8601String(),
    };
  }

  /// 生成成长数据更新
  static Map<String, dynamic> toStatsUpdate(PetStats stats) {
    return {
      'stats': jsonEncode({
        'level': stats.level,
        'experience': stats.experience,
        'intimacy': stats.intimacy,
        'totalFeedings': stats.totalFeedings,
        'totalInteractions': stats.totalInteractions,
      }),
      'updatedAt': DateTime.now().toIso8601String(),
      'lastInteractionAt': DateTime.now().toIso8601String(),
    };
  }

  /// 解析宠物物种
  static PetSpecies _parseSpecies(dynamic value) {
    if (value is String) {
      return PetSpecies.values.firstWhere(
        (e) => e.name == value,
        orElse: () => PetSpecies.cat,
      );
    }
    return PetSpecies.cat;
  }
}
