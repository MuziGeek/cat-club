import '../../core/exceptions/cloudbase_exception.dart';
import '../../data/models/user_model.dart';

/// 用户仓库接口
///
/// 定义用户相关的数据操作契约
abstract class UserRepository {
  /// 获取用户
  Future<Result<UserModel?>> getUser(String userId);

  /// 创建用户
  Future<Result<UserModel>> createUser(UserModel user);

  /// 更新用户
  Future<Result<void>> updateUser(String userId, Map<String, dynamic> data);

  /// 确保用户存在（不存在则创建）
  Future<Result<UserModel>> ensureUserExists(String userId);

  /// 用户数据流
  Stream<UserModel?> userStream(String userId);

  // ==================== 货币操作 ====================

  /// 更新用户货币（增量）
  Future<Result<void>> updateCurrency(
    String userId, {
    int? coinsChange,
    int? diamondsChange,
  });

  // ==================== 背包操作 ====================

  /// 获取用户背包
  Future<Result<Map<String, int>>> getInventory(String userId);

  /// 使用道具
  Future<Result<bool>> useItem(String userId, String itemId);

  /// 添加道具
  Future<Result<void>> addItem(String userId, String itemId, int count);

  /// 设置初始背包
  Future<Result<void>> setInitialInventory(
    String userId,
    Map<String, int> inventory,
  );

  // ==================== 宠物关联 ====================

  /// 添加宠物到用户
  Future<Result<void>> addPetToUser(String userId, String petId);

  /// 从用户移除宠物
  Future<Result<void>> removePetFromUser(String userId, String petId);
}
