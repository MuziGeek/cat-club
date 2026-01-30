import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/user_model.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';

/// FirestoreService Provider
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

/// 当前用户数据流 Provider
final currentUserProvider = StreamProvider<UserModel?>((ref) {
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
