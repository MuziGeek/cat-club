import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';
import 'user_provider.dart';

/// AuthService Provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// 当前用户状态 Provider
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// 认证状态枚举
enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
}

/// 认证状态 Provider
final authStatusProvider = Provider<AuthStatus>((ref) {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) =>
        user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated,
    loading: () => AuthStatus.initial,
    error: (_, __) => AuthStatus.unauthenticated,
  );
});

/// 登录状态 Notifier
class LoginNotifier extends StateNotifier<AsyncValue<void>> {
  final AuthService _authService;

  LoginNotifier(this._authService) : super(const AsyncValue.data(null));

  /// 邮箱密码登录
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _authService.signInWithEmail(
        email: email,
        password: password,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Google 登录
  Future<bool> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final credential = await _authService.signInWithGoogle();
      if (credential == null) {
        // 用户取消了登录
        state = const AsyncValue.data(null);
        return false;
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

/// 登录 Notifier Provider
final loginProvider =
    StateNotifierProvider<LoginNotifier, AsyncValue<void>>((ref) {
  final authService = ref.watch(authServiceProvider);
  return LoginNotifier(authService);
});

/// 注册状态 Notifier
class RegisterNotifier extends StateNotifier<AsyncValue<void>> {
  final AuthService _authService;
  final Ref _ref;

  RegisterNotifier(this._authService, this._ref) : super(const AsyncValue.data(null));

  /// 邮箱密码注册
  Future<bool> registerWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    state = const AsyncValue.loading();
    try {
      final credential = await _authService.registerWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );

      // 创建用户文档
      if (credential.user != null) {
        await _ref.read(userNotifierProvider.notifier).createUserDocument(
          userId: credential.user!.uid,
          email: email,
          displayName: displayName,
        );
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

/// 注册 Notifier Provider
final registerProvider =
    StateNotifierProvider<RegisterNotifier, AsyncValue<void>>((ref) {
  final authService = ref.watch(authServiceProvider);
  return RegisterNotifier(authService, ref);
});
