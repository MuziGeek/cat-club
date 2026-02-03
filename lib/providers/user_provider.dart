import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/item_model.dart';
import '../data/models/user_model.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';

/// FirestoreService Provider
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

/// 用户数据刷新触发器
/// 改变此值会强制 currentUserProvider 重新获取数据
final userRefreshTriggerProvider = StateProvider<int>((ref) => 0);

/// 当前用户数据 Provider（使用 FutureProvider 确保每次刷新都获取最新数据）
final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  // 监听刷新触发器 - 当触发器变化时，重新获取数据
  final trigger = ref.watch(userRefreshTriggerProvider);
  print('[USER_PROVIDER] currentUserProvider 被调用, trigger=$trigger');

  final authState = ref.watch(authStateProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);

  // 直接获取用户，避免 when 内部 async 的类型问题
  final user = authState.valueOrNull;
  if (user == null) {
    print('[USER_PROVIDER] authState.valueOrNull 为 null');
    return null;
  }

  print('[USER_PROVIDER] 正在从 Firestore 获取用户数据, uid=${user.uid}');
  try {
    final userData = await firestoreService.getUser(user.uid);
    print('[USER_PROVIDER] 获取完成: coins=${userData?.coins}, diamonds=${userData?.diamonds}');
    return userData;
  } catch (e, st) {
    print('[USER_PROVIDER] 获取用户数据异常: $e');
    print('[USER_PROVIDER] 堆栈: $st');
    rethrow;
  }
});

/// 用户数据实时流 Provider（用于需要实时监听的场景）
final userStreamProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);

  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return firestoreService.userStream(user.uid);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

/// 便捷别名 - 当前用户 Provider
final userProvider = currentUserProvider;

/// 用户操作 Notifier
class UserNotifier extends StateNotifier<AsyncValue<void>> {
  final FirestoreService _firestoreService;
  final Ref _ref;

  UserNotifier(this._firestoreService, this._ref)
      : super(const AsyncValue.data(null));

  /// 创建用户文档（注册时调用）
  Future<bool> createUserDocument({
    required String userId,
    required String email,
    String? displayName,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = UserModel(
        id: userId,
        email: email,
        displayName: displayName,
        coins: 100, // 初始货币
        diamonds: 10,
        createdAt: DateTime.now(),
      );
      await _firestoreService.createUser(user);
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
      final authState = _ref.read(authStateProvider);
      final userId = authState.valueOrNull?.uid;
      if (userId == null) throw Exception('用户未登录');

      await _firestoreService.updateUser(userId, {
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
      final authState = _ref.read(authStateProvider);
      final userId = authState.valueOrNull?.uid;
      if (userId == null) throw Exception('用户未登录');

      await _firestoreService.updateUserCurrency(
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
      final authState = _ref.read(authStateProvider);
      final userId = authState.valueOrNull?.uid;
      if (userId == null) throw Exception('用户未登录');

      // 扣除货币（使用负数）
      if (currency == CurrencyType.coins) {
        await _firestoreService.updateUserCurrency(userId, coins: -price);
      } else {
        await _firestoreService.updateUserCurrency(userId, diamonds: -price);
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
  final firestoreService = ref.watch(firestoreServiceProvider);
  return UserNotifier(firestoreService, ref);
});
