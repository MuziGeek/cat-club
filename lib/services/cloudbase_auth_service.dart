import 'package:cloudbase_ce/cloudbase_ce.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/cloudbase_config.dart';

/// CloudBase 认证服务 Provider
final cloudbaseAuthServiceProvider = Provider<CloudbaseAuthService>((ref) {
  return CloudbaseAuthService();
});

/// CloudBase 认证状态 Provider
final cloudbaseAuthStateProvider = StreamProvider<CloudbaseAuthState?>((ref) {
  final authService = ref.watch(cloudbaseAuthServiceProvider);
  return authService.authStateChanges;
});

/// CloudBase 认证服务
///
/// 封装腾讯云 CloudBase 认证功能
class CloudbaseAuthService {
  CloudBaseCore? _core;
  CloudBaseAuth? _auth;
  bool _isInitialized = false;

  /// 认证状态变化流
  Stream<CloudbaseAuthState?> get authStateChanges async* {
    await _ensureInitialized();
    // CloudBase 不提供原生的状态流，我们手动检查
    while (true) {
      yield await getAuthState();
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  /// 确保已初始化
  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;

    try {
      _core = CloudBaseCore.init({
        'env': CloudbaseConfig.envId,
        'timeout': CloudbaseConfig.timeout,
      });
      _auth = CloudBaseAuth(_core!);
      _isInitialized = true;
      debugPrint('[CloudBase Auth] 初始化成功');
    } catch (e) {
      debugPrint('[CloudBase Auth] 初始化失败: $e');
      rethrow;
    }
  }

  /// 获取当前认证状态
  Future<CloudbaseAuthState?> getAuthState() async {
    await _ensureInitialized();
    try {
      return await _auth!.getAuthState();
    } catch (e) {
      debugPrint('[CloudBase Auth] 获取认证状态失败: $e');
      return null;
    }
  }

  /// 获取当前用户 ID
  Future<String?> getCurrentUserId() async {
    final state = await getAuthState();
    return state?.user?.uid;
  }

  /// 邮箱密码登录
  Future<CloudbaseAuthState?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await _ensureInitialized();
    try {
      debugPrint('[CloudBase Auth] 正在登录: $email');
      final state = await _auth!.signInWithEmailAndPassword(email, password);
      debugPrint('[CloudBase Auth] 登录成功: ${state?.user?.uid}');
      return state;
    } catch (e) {
      debugPrint('[CloudBase Auth] 登录失败: $e');
      rethrow;
    }
  }

  /// 邮箱密码注册
  Future<CloudbaseAuthState?> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await _ensureInitialized();
    try {
      debugPrint('[CloudBase Auth] 正在注册: $email');
      final state = await _auth!.signUpWithEmailAndPassword(email, password);
      debugPrint('[CloudBase Auth] 注册成功: ${state?.user?.uid}');
      return state;
    } catch (e) {
      debugPrint('[CloudBase Auth] 注册失败: $e');
      rethrow;
    }
  }

  /// 匿名登录
  Future<CloudbaseAuthState?> signInAnonymously() async {
    await _ensureInitialized();
    try {
      debugPrint('[CloudBase Auth] 正在匿名登录');
      final state = await _auth!.signInAnonymously();
      debugPrint('[CloudBase Auth] 匿名登录成功: ${state?.user?.uid}');
      return state;
    } catch (e) {
      debugPrint('[CloudBase Auth] 匿名登录失败: $e');
      rethrow;
    }
  }

  /// 登出
  Future<void> signOut() async {
    await _ensureInitialized();
    try {
      await _auth!.signOut();
      debugPrint('[CloudBase Auth] 已登出');
    } catch (e) {
      debugPrint('[CloudBase Auth] 登出失败: $e');
      rethrow;
    }
  }

  /// 发送密码重置邮件
  Future<void> sendPasswordResetEmail(String email) async {
    await _ensureInitialized();
    try {
      await _auth!.sendPasswordResetEmail(email);
      debugPrint('[CloudBase Auth] 密码重置邮件已发送: $email');
    } catch (e) {
      debugPrint('[CloudBase Auth] 发送密码重置邮件失败: $e');
      rethrow;
    }
  }

  /// 检查是否已登录
  Future<bool> isSignedIn() async {
    final state = await getAuthState();
    return state?.user != null;
  }
}
