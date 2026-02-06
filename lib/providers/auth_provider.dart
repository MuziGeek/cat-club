import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/cloudbase_auth_http_service.dart';
import 'user_provider.dart';

/// CloudBase 认证服务单例实例
/// 确保整个应用使用同一个实例，避免登出时状态不同步
final _authServiceInstance = CloudbaseAuthHttpService();

/// CloudBase 认证服务 Provider (单例)
final authServiceProvider = Provider<CloudbaseAuthHttpService>((ref) {
  return _authServiceInstance;
});

/// 当前用户状态 Provider (CloudBase)
final authStateProvider = StreamProvider<CloudbaseAuthState?>((ref) {
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
    data: (state) =>
        state != null && state.isAuthenticated ? AuthStatus.authenticated : AuthStatus.unauthenticated,
    loading: () => AuthStatus.initial,
    error: (_, __) => AuthStatus.unauthenticated,
  );
});

/// 当前用户 ID Provider
/// 优先使用同步方式获取，确保登录后立即可用
final currentUserIdProvider = Provider<String?>((ref) {
  // 直接从 authService 同步获取，不依赖流状态
  final authService = ref.watch(authServiceProvider);
  return authService.currentUserId;
});

/// 登录状态 Notifier
class LoginNotifier extends StateNotifier<AsyncValue<void>> {
  final CloudbaseAuthHttpService _authService;

  LoginNotifier(this._authService) : super(const AsyncValue.data(null));

  /// 邮箱密码登录
  Future<bool> signInWithPassword({
    String? username,
    String? email,
    String? phone,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _authService.signInWithPassword(
        username: username,
        email: email,
        phone: phone,
        password: password,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// 发送邮箱验证码
  Future<VerificationResult?> sendEmailOtp(String email) async {
    state = const AsyncValue.loading();
    try {
      final result = await _authService.sendEmailOtp(email);
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// 发送手机验证码
  Future<VerificationResult?> sendPhoneOtp(String phone) async {
    state = const AsyncValue.loading();
    try {
      final result = await _authService.sendPhoneOtp(phone);
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// 邮箱验证码登录
  Future<bool> signInWithEmailOtp({
    required String email,
    required String code,
    required String verificationId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _authService.signInWithEmailOtp(
        email: email,
        code: code,
        verificationId: verificationId,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// 手机验证码登录
  Future<bool> signInWithPhoneOtp({
    required String phone,
    required String code,
    required String verificationId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _authService.signInWithPhoneOtp(
        phone: phone,
        code: code,
        verificationId: verificationId,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// 匿名登录
  Future<bool> signInAnonymously() async {
    state = const AsyncValue.loading();
    try {
      await _authService.signInAnonymously();
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// 登出
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _authService.signOut();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
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
  final CloudbaseAuthHttpService _authService;
  final Ref _ref;

  RegisterNotifier(this._authService, this._ref) : super(const AsyncValue.data(null));

  /// 发送邮箱验证码（用于注册）
  Future<VerificationResult?> sendEmailOtp(String email) async {
    state = const AsyncValue.loading();
    try {
      final result = await _authService.sendEmailOtp(email);
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// 发送手机验证码（用于注册）
  Future<VerificationResult?> sendPhoneOtp(String phone) async {
    state = const AsyncValue.loading();
    try {
      final result = await _authService.sendPhoneOtp(phone);
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// 邮箱验证码注册/登录
  Future<bool> registerWithEmailOtp({
    required String email,
    required String code,
    required String verificationId,
    String? displayName,
  }) async {
    state = const AsyncValue.loading();
    try {
      final authState = await _authService.signInWithEmailOtp(
        email: email,
        code: code,
        verificationId: verificationId,
      );

      // 创建用户文档（如果是新用户）
      if (authState.sub != null) {
        await _ref.read(userNotifierProvider.notifier).createUserDocument(
          userId: authState.sub!,
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

  /// 手机验证码注册/登录
  Future<bool> registerWithPhoneOtp({
    required String phone,
    required String code,
    required String verificationId,
    String? displayName,
  }) async {
    state = const AsyncValue.loading();
    try {
      final authState = await _authService.signInWithPhoneOtp(
        phone: phone,
        code: code,
        verificationId: verificationId,
      );

      // 创建用户文档（如果是新用户）
      if (authState.sub != null) {
        await _ref.read(userNotifierProvider.notifier).createUserDocument(
          userId: authState.sub!,
          phone: phone,
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
