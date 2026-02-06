import '../../core/exceptions/cloudbase_exception.dart';
import '../../data/models/pet_model.dart';

/// 宠物仓库接口
///
/// 定义宠物相关的数据操作契约
abstract class PetRepository {
  /// 获取宠物
  Future<Result<PetModel?>> getPet(String petId);

  /// 创建宠物
  Future<Result<String>> createPet(PetModel pet);

  /// 更新宠物
  Future<Result<void>> updatePet(String petId, Map<String, dynamic> data);

  /// 删除宠物
  Future<Result<void>> deletePet(String petId);

  /// 用户宠物列表流
  Stream<List<PetModel>> userPetsStream(String userId);

  /// 单个宠物数据流
  Stream<PetModel?> petStream(String petId);

  // ==================== 状态更新 ====================

  /// 更新宠物状态
  Future<Result<void>> updateStatus(
    String petId, {
    int? happiness,
    int? hunger,
    int? energy,
    int? health,
    int? cleanliness,
  });

  // ==================== 成长更新 ====================

  /// 更新宠物成长数据
  Future<Result<void>> updateStats(
    String petId, {
    int? experienceGain,
    int? intimacyGain,
    bool incrementFeedings = false,
    bool incrementInteractions = false,
  });
}
