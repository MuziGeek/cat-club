import 'package:flutter/foundation.dart';
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

/// 统一认证 Notifier
///
/// 采用 OTP 验证码认证，自动处理登录/注册：
/// - 新用户：自动创建用户文档
/// - 老用户：直接登录
class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  final CloudbaseAuthHttpService _authService;
  final Ref _ref;

  AuthNotifier(this._authService, this._ref) : super(const AsyncValue.data(null));

  /// 发送邮箱验证码
  Future<VerificationResult?> sendEmailOtp(String email) async {
    state = const AsyncValue.loading();
    try {
      final result = await _authService.sendEmailOtp(email);
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      debugPrint('[AUTH] 发送邮箱验证码失败: $e');
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
      debugPrint('[AUTH] 发送手机验证码失败: $e');
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// 统一认证方法（自动判断登录/注册）
  ///
  /// OTP 验证通过后：
  /// - 如果是新用户，自动创建用户文档
  /// - 如果是老用户，直接完成登录
  Future<bool> authenticateWithOtp({
    String? email,
    String? phone,
    required String code,
    required String verificationId,
    String? displayName,
  }) async {
    state = const AsyncValue.loading();
    try {
      // 1. 验证 OTP 并登录
      CloudbaseAuthState authState;
      if (email != null) {
        authState = await _authService.signInWithEmailOtp(
          email: email,
          code: code,
          verificationId: verificationId,
        );
      } else if (phone != null) {
        authState = await _authService.signInWithPhoneOtp(
          phone: phone,
          code: code,
          verificationId: verificationId,
        );
      } else {
        throw ArgumentError('必须提供 email 或 phone');
      }

      // 2. 确保用户文档存在（CloudBase 会自动处理注册/登录）
      if (authState.sub != null) {
        await _ref.read(userNotifierProvider.notifier).createUserDocument(
          userId: authState.sub!,
          email: email,
          phone: phone,
          displayName: displayName,
        );
      }

      state = const AsyncValue.data(null);
      debugPrint('[AUTH] OTP 认证成功: uid=${authState.sub}');
      return true;
    } catch (e, st) {
      debugPrint('[AUTH] OTP 认证失败: $e');
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// 匿名登录
  Future<bool> signInAnonymously() async {
    state = const AsyncValue.loading();
    try {
      final authState = await _authService.signInAnonymously();

      // 为匿名用户创建文档
      if (authState.sub != null) {
        await _ref.read(userNotifierProvider.notifier).createUserDocument(
          userId: authState.sub!,
          displayName: '匿名用户',
        );
      }

      state = const AsyncValue.data(null);
      debugPrint('[AUTH] 匿名登录成功: uid=${authState.sub}');
      return true;
    } catch (e, st) {
      debugPrint('[AUTH] 匿名登录失败: $e');
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
      debugPrint('[AUTH] 登出成功');
    } catch (e, st) {
      debugPrint('[AUTH] 登出失败: $e');
      state = AsyncValue.error(e, st);
    }
  }

  /// 重置状态
  void reset() {
    state = const AsyncValue.data(null);
  }
}

/// 统一认证 Notifier Provider
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService, ref);
});

// ============================================================================
// 以下为兼容性别名，逐步废弃
// ============================================================================

/// @deprecated 使用 authNotifierProvider 替代
final loginProvider = authNotifierProvider;

/// @deprecated 使用 authNotifierProvider 替代
final registerProvider = authNotifierProvider;
