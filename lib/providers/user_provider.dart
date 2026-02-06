import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/item_model.dart';
import '../data/models/user_model.dart';
import '../services/cloudbase_service.dart';
import 'auth_provider.dart';

// 从 cloudbase_service.dart 导出 cloudbaseServiceProvider
export '../services/cloudbase_service.dart' show cloudbaseServiceProvider;

/// 用户数据刷新触发器
/// 改变此值会强制 currentUserProvider 重新获取数据
final userRefreshTriggerProvider = StateProvider<int>((ref) => 0);

/// 当前用户数据 Provider（使用 FutureProvider 确保每次刷新都获取最新数据）
final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  // 监听刷新触发器 - 当触发器变化时，重新获取数据
  final trigger = ref.watch(userRefreshTriggerProvider);
  debugPrint('[USER_PROVIDER] currentUserProvider 被调用, trigger=$trigger');

  final userId = ref.watch(currentUserIdProvider);
  final cloudbaseService = ref.watch(cloudbaseServiceProvider);

  if (userId == null) {
    debugPrint('[USER_PROVIDER] userId 为 null');
    return null;
  }

  debugPrint('[USER_PROVIDER] 正在从 CloudBase 获取用户数据, uid=$userId');
  try {
    final userData = await cloudbaseService.getUser(userId);
    debugPrint('[USER_PROVIDER] 获取完成: coins=${userData?.coins}, diamonds=${userData?.diamonds}');
    return userData;
  } catch (e, st) {
    debugPrint('[USER_PROVIDER] 获取用户数据异常: $e');
    debugPrint('[USER_PROVIDER] 堆栈: $st');
    rethrow;
  }
});

/// 用户数据实时流 Provider（用于需要实时监听的场景）
final userStreamProvider = StreamProvider<UserModel?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  final cloudbaseService = ref.watch(cloudbaseServiceProvider);

  if (userId == null) return Stream.value(null);
  return cloudbaseService.userStream(userId);
});

/// 便捷别名 - 当前用户 Provider
final userProvider = currentUserProvider;

/// 用户操作 Notifier
class UserNotifier extends StateNotifier<AsyncValue<void>> {
  final CloudbaseService _cloudbaseService;
  final Ref _ref;

  UserNotifier(this._cloudbaseService, this._ref)
      : super(const AsyncValue.data(null));

  /// 创建用户文档（注册时调用）
  Future<bool> createUserDocument({
    required String userId,
    String? email,
    String? phone,
    String? displayName,
  }) async {
    state = const AsyncValue.loading();
    try {
      // 先检查用户是否已存在
      final existingUser = await _cloudbaseService.getUser(userId);
      if (existingUser != null) {
        debugPrint('[USER_PROVIDER] 用户已存在，跳过创建');
        state = const AsyncValue.data(null);
        return true;
      }

      final user = UserModel(
        id: userId,
        email: email,
        phone: phone,
        displayName: displayName,
        coins: 100, // 初始货币
        diamonds: 10,
        createdAt: DateTime.now(),
      );
      await _cloudbaseService.createUser(user);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// 更新用户显示名称
  Future<bool> updateDisplayName(String displayName) async {
    state = const AsyncValue.loading();
    try {
      final userId = _ref.read(currentUserIdProvider);
      if (userId == null) throw Exception('用户未登录');

      await _cloudbaseService.updateUser(userId, {
        'displayName': displayName,
      });
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// 更新用户货币
  Future<bool> updateCurrency({int? coins, int? diamonds}) async {
    state = const AsyncValue.loading();
    try {
      final userId = _ref.read(currentUserIdProvider);
      if (userId == null) throw Exception('用户未登录');

      await _cloudbaseService.updateUserCurrency(
        userId,
        coins: coins,
        diamonds: diamonds,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// 购买道具
  ///
  /// 扣除货币，返回是否成功
  Future<bool> purchaseItem({
    required String itemId,
    required int price,
    required CurrencyType currency,
  }) async {
    state = const AsyncValue.loading();
    try {
      final userId = _ref.read(currentUserIdProvider);
      if (userId == null) throw Exception('用户未登录');

      // 扣除货币（使用负数）
      if (currency == CurrencyType.coins) {
        await _cloudbaseService.updateUserCurrency(userId, coins: -price);
      } else {
        await _cloudbaseService.updateUserCurrency(userId, diamonds: -price);
      }

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// 重置状态
  void reset() {
    state = const AsyncValue.data(null);
  }
}

/// 用户 Notifier Provider
final userNotifierProvider =
    StateNotifierProvider<UserNotifier, AsyncValue<void>>((ref) {
  final cloudbaseService = ref.watch(cloudbaseServiceProvider);
  return UserNotifier(cloudbaseService, ref);
});
