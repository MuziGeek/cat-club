import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../config/cloudbase_config.dart';

/// CloudBase HTTP API 认证服务 Provider
final cloudbaseAuthHttpServiceProvider =
    Provider<CloudbaseAuthHttpService>((ref) {
  return CloudbaseAuthHttpService();
});

/// CloudBase 认证状态 Provider
final cloudbaseAuthStateHttpProvider =
    StreamProvider<CloudbaseAuthState?>((ref) {
  final authService = ref.watch(cloudbaseAuthHttpServiceProvider);
  return authService.authStateChanges;
});

/// CloudBase 当前用户 Provider
final cloudbaseCurrentUserProvider = FutureProvider<CloudbaseUser?>((ref) {
  final authService = ref.watch(cloudbaseAuthHttpServiceProvider);
  return authService.getCurrentUser();
});

/// 认证状态
class CloudbaseAuthState {
  final String? accessToken;
  final String? refreshToken;
  final int? expiresIn;
  final String? tokenType;
  final String? sub;
  final String? scope;
  final CloudbaseUser? user;

  CloudbaseAuthState({
    this.accessToken,
    this.refreshToken,
    this.expiresIn,
    this.tokenType,
    this.sub,
    this.scope,
    this.user,
  });

  bool get isAuthenticated => accessToken != null && accessToken!.isNotEmpty;
  bool get isAnonymous => scope == 'anonymous';

  factory CloudbaseAuthState.fromJson(Map<String, dynamic> json) {
    return CloudbaseAuthState(
      accessToken: json['access_token'] as String?,
      refreshToken: json['refresh_token'] as String?,
      expiresIn: json['expires_in'] as int?,
      tokenType: json['token_type'] as String?,
      sub: json['sub'] as String?,
      scope: json['scope'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'expires_in': expiresIn,
        'token_type': tokenType,
        'sub': sub,
        'scope': scope,
      };

  CloudbaseAuthState copyWith({CloudbaseUser? user}) {
    return CloudbaseAuthState(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresIn: expiresIn,
      tokenType: tokenType,
      sub: sub,
      scope: scope,
      user: user ?? this.user,
    );
  }
}

/// CloudBase 用户信息
class CloudbaseUser {
  final String id;
  final String? email;
  final String? phone;
  final String? username;
  final String? nickname;
  final String? avatarUrl;
  final String? gender;
  final bool isAnonymous;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? metadata;

  CloudbaseUser({
    required this.id,
    this.email,
    this.phone,
    this.username,
    this.nickname,
    this.avatarUrl,
    this.gender,
    this.isAnonymous = false,
    this.createdAt,
    this.updatedAt,
    this.metadata,
  });

  String? get displayName => nickname ?? username ?? email ?? phone;

  factory CloudbaseUser.fromJson(Map<String, dynamic> json) {
    final userMetadata = json['user_metadata'] as Map<String, dynamic>? ?? {};
    return CloudbaseUser(
      id: json['id']?.toString() ?? json['sub']?.toString() ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      username: userMetadata['username'] as String?,
      nickname: userMetadata['nickName'] as String? ??
          userMetadata['name'] as String?,
      avatarUrl: userMetadata['avatarUrl'] as String? ??
          userMetadata['picture'] as String?,
      gender: userMetadata['gender'] as String?,
      isAnonymous: json['is_anonymous'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      metadata: userMetadata,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'phone': phone,
        'username': username,
        'nickname': nickname,
        'avatarUrl': avatarUrl,
        'gender': gender,
        'isAnonymous': isAnonymous,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'metadata': metadata,
      };
}

/// 验证码结果
class VerificationResult {
  final String verificationId;
  final int expiresIn;

  VerificationResult({
    required this.verificationId,
    required this.expiresIn,
  });

  factory VerificationResult.fromJson(Map<String, dynamic> json) {
    return VerificationResult(
      verificationId: json['verification_id'] as String,
      expiresIn: json['expires_in'] as int? ?? 600,
    );
  }
}

/// 认证异常
class CloudbaseAuthException implements Exception {
  final String code;
  final String message;
  final int? errorCode;

  CloudbaseAuthException({
    required this.code,
    required this.message,
    this.errorCode,
  });

  factory CloudbaseAuthException.fromJson(Map<String, dynamic> json) {
    return CloudbaseAuthException(
      code: json['error'] as String? ?? 'unknown_error',
      message: json['error_description'] as String? ?? 'Unknown error',
      errorCode: json['error_code'] as int?,
    );
  }

  @override
  String toString() => 'CloudbaseAuthException: [$code] $message';
}

/// CloudBase HTTP API 认证服务
///
/// 基于 CloudBase HTTP API 实现完整的认证功能，
/// 支持邮箱OTP、手机验证码、用户名密码、Google OAuth、匿名登录等方式。
class CloudbaseAuthHttpService {
  static const String _tokenKey = 'cloudbase_auth_token';
  static const String _userKey = 'cloudbase_auth_user';
  static const String _deviceIdKey = 'cloudbase_device_id';

  final String _baseUrl = CloudbaseConfig.apiBaseUrl;
  final String _publishableKey = CloudbaseConfig.publishableKey;

  CloudbaseAuthState? _currentState;
  String? _deviceId;

  final _authStateController = StreamController<CloudbaseAuthState?>.broadcast();

  /// 认证状态变化流
  Stream<CloudbaseAuthState?> get authStateChanges => _authStateController.stream;

  /// 当前认证状态
  CloudbaseAuthState? get currentState => _currentState;

  /// 当前用户 ID
  String? get currentUserId => _currentState?.sub;

  /// 获取当前 Access Token
  Future<String?> getAccessToken() async {
    return _currentState?.accessToken;
  }

  /// 是否已登录
  bool get isSignedIn =>
      _currentState != null && _currentState!.isAuthenticated;

  /// 初始化服务
  Future<void> initialize() async {
    await _loadDeviceId();
    await _loadStoredToken();
  }

  /// 获取或创建设备 ID
  Future<String> _loadDeviceId() async {
    if (_deviceId != null) return _deviceId!;

    final prefs = await SharedPreferences.getInstance();
    _deviceId = prefs.getString(_deviceIdKey);

    if (_deviceId == null) {
      _deviceId = const Uuid().v4();
      await prefs.setString(_deviceIdKey, _deviceId!);
    }

    return _deviceId!;
  }

  /// 加载存储的 Token
  Future<void> _loadStoredToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tokenJson = prefs.getString(_tokenKey);

      if (tokenJson != null) {
        final tokenData = jsonDecode(tokenJson) as Map<String, dynamic>;
        _currentState = CloudbaseAuthState.fromJson(tokenData);

        // 先发送状态，不阻塞等待网络请求
        _authStateController.add(_currentState);
        debugPrint('[CloudBase Auth] 已恢复登录状态: ${_currentState?.sub}');

        // 异步尝试获取用户信息（带超时），不阻塞初始化
        if (_currentState!.isAuthenticated) {
          _fetchCurrentUser()
              .timeout(const Duration(seconds: 5))
              .then((user) {
            if (user != null) {
              _currentState = _currentState!.copyWith(user: user);
              _authStateController.add(_currentState);
            }
          }).catchError((e) {
            debugPrint('[CloudBase Auth] 获取用户信息失败(非阻塞): $e');
          });
        }
      } else {
        // 没有存储的 Token，发送 null 状态
        _authStateController.add(null);
      }
    } catch (e) {
      debugPrint('[CloudBase Auth] 加载 Token 失败: $e');
      _authStateController.add(null);
    }
  }

  /// 保存 Token
  Future<void> _saveToken(CloudbaseAuthState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, jsonEncode(state.toJson()));
    _currentState = state;
    _authStateController.add(_currentState);
  }

  /// 清除 Token
  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    _currentState = null;
    _authStateController.add(null);
  }

  /// 获取请求头
  Map<String, String> _getHeaders({String? accessToken}) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'x-device-id': _deviceId ?? '',
      'Authorization': 'Bearer ${accessToken ?? _publishableKey}',
    };
  }

  /// 发送 HTTP 请求
  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    String? accessToken,
  }) async {
    await _loadDeviceId();

    var uri = Uri.parse('$_baseUrl$path');
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    final headers = _getHeaders(accessToken: accessToken);

    http.Response response;

    try {
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: headers);
          break;
        case 'POST':
          response = await http.post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'PATCH':
          response = await http.patch(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers);
          break;
        default:
          throw CloudbaseAuthException(
            code: 'invalid_method',
            message: 'Invalid HTTP method: $method',
          );
      }
    } on SocketException catch (e) {
      throw CloudbaseAuthException(
        code: 'network_error',
        message: '网络连接失败: ${e.message}',
      );
    }

    if (CloudbaseConfig.debug) {
      debugPrint('[CloudBase Auth] $method $path');
      debugPrint('[CloudBase Auth] Status: ${response.statusCode}');
      debugPrint('[CloudBase Auth] Body: ${response.body}');
    }

    final responseData = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 400) {
      throw CloudbaseAuthException.fromJson(responseData);
    }

    return responseData;
  }

  // ==================== 登录方法 ====================

  /// 用户名密码登录
  Future<CloudbaseAuthState> signInWithPassword({
    String? username,
    String? email,
    String? phone,
    required String password,
  }) async {
    if (username == null && email == null && phone == null) {
      throw CloudbaseAuthException(
        code: 'invalid_argument',
        message: '必须提供 username、email 或 phone 其中之一',
      );
    }

    final body = <String, dynamic>{
      'password': password,
    };

    if (username != null) body['username'] = username;
    if (email != null) body['email'] = email;
    if (phone != null) body['phone_number'] = '+86 $phone';

    debugPrint('[CloudBase Auth] 正在登录...');

    final response = await _request('POST', '/auth/v1/signin', body: body);
    final state = CloudbaseAuthState.fromJson(response);

    // 获取用户信息
    final user = await _fetchCurrentUser(accessToken: state.accessToken);
    final stateWithUser = state.copyWith(user: user);

    await _saveToken(stateWithUser);
    debugPrint('[CloudBase Auth] 登录成功: ${stateWithUser.sub}');

    return stateWithUser;
  }

  /// 发送邮箱验证码
  Future<VerificationResult> sendEmailOtp(String email) async {
    debugPrint('[CloudBase Auth] 发送邮箱验证码: $email');

    final response = await _request(
      'POST',
      '/auth/v1/verification',
      body: {
        'email': email,
        'target': 'ANY',
      },
    );

    return VerificationResult.fromJson(response);
  }

  /// 发送手机验证码
  Future<VerificationResult> sendPhoneOtp(String phone) async {
    // 确保手机号格式正确：+86 13800138000
    final formattedPhone = phone.startsWith('+86') ? phone : '+86 $phone';
    debugPrint('[CloudBase Auth] 发送手机验证码: $formattedPhone');

    final response = await _request(
      'POST',
      '/auth/v1/verification',
      body: {
        'phone_number': formattedPhone,
        'target': 'ANY',
      },
    );

    return VerificationResult.fromJson(response);
  }

  /// 验证验证码
  Future<String> verifyOtp({
    required String verificationId,
    required String code,
  }) async {
    debugPrint('[CloudBase Auth] 验证验证码: $verificationId');

    final response = await _request(
      'POST',
      '/auth/v1/verification/verify',
      body: {
        'verification_id': verificationId,
        'verification_code': code,
      },
    );

    return response['verification_token'] as String;
  }

  /// 使用验证码 Token 登录（自动处理注册/登录）
  Future<CloudbaseAuthState> signInWithVerificationToken(
      String verificationToken) async {
    return signInOrSignUpWithVerificationToken(verificationToken: verificationToken);
  }

  /// 使用验证码 Token 登录或注册（支持手机号/邮箱）
  Future<CloudbaseAuthState> signInOrSignUpWithVerificationToken({
    required String verificationToken,
    String? phone,
    String? email,
  }) async {
    debugPrint('[CloudBase Auth] 使用验证码 Token 登录');

    // 先尝试登录
    try {
      final response = await _request(
        'POST',
        '/auth/v1/signin',
        body: {
          'verification_token': verificationToken,
        },
      );

      final state = CloudbaseAuthState.fromJson(response);

      // 获取用户信息
      final user = await _fetchCurrentUser(accessToken: state.accessToken);
      final stateWithUser = state.copyWith(user: user);

      await _saveToken(stateWithUser);
      debugPrint('[CloudBase Auth] 验证码登录成功: ${stateWithUser.sub}');

      return stateWithUser;
    } catch (e) {
      // 如果登录失败（用户不存在），尝试注册
      debugPrint('[CloudBase Auth] 登录失败，尝试注册: $e');

      // 构建注册请求体
      final signupBody = <String, dynamic>{
        'verification_token': verificationToken,
      };

      // 添加手机号或邮箱（注册必需）
      // CloudBase HTTP API 使用 phone_number 字段，格式必须是 "+86 13800138000"
      if (phone != null && phone.isNotEmpty) {
        // 格式化手机号：确保包含国家码和空格
        String formattedPhone = phone.trim();
        // 移除已有的 +86 前缀（避免重复）
        if (formattedPhone.startsWith('+86')) {
          formattedPhone = formattedPhone.substring(3).trim();
        }
        // 添加正确格式的国家码
        formattedPhone = '+86 $formattedPhone';
        signupBody['phone_number'] = formattedPhone;
      }
      if (email != null && email.isNotEmpty) {
        signupBody['email'] = email;
      }

      debugPrint('[CloudBase Auth] 注册参数: $signupBody');

      // 带重试的注册请求（解决网络不稳定导致的 HandshakeException）
      Map<String, dynamic>? response;
      Exception? lastError;
      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          debugPrint('[CloudBase Auth] 发送注册请求... (尝试 $attempt/3)');
          response = await _request(
            'POST',
            '/auth/v1/signup',
            body: signupBody,
          );
          break; // 成功则跳出循环
        } catch (retryError) {
          lastError = retryError as Exception;
          debugPrint('[CloudBase Auth] 注册请求失败 (尝试 $attempt/3): $retryError');
          if (attempt < 3) {
            // 等待后重试
            await Future.delayed(Duration(milliseconds: 500 * attempt));
          }
        }
      }

      if (response == null) {
        debugPrint('[CloudBase Auth] 注册失败，已重试3次');
        throw lastError ?? CloudbaseAuthException(
          code: 'signup_failed',
          message: '注册失败，请检查网络后重试',
        );
      }

      debugPrint('[CloudBase Auth] 注册响应: $response');

      final state = CloudbaseAuthState.fromJson(response);

      // 获取用户信息
      CloudbaseUser? user;
      try {
        user = await _fetchCurrentUser(accessToken: state.accessToken);
      } catch (userError) {
        debugPrint('[CloudBase Auth] 获取新用户信息失败: $userError');
      }
      final stateWithUser = user != null ? state.copyWith(user: user) : state;

      await _saveToken(stateWithUser);
      debugPrint('[CloudBase Auth] 验证码注册成功: ${stateWithUser.sub}');

      return stateWithUser;
    }
  }

  /// 邮箱 OTP 登录（完整流程）
  Future<CloudbaseAuthState> signInWithEmailOtp({
    required String email,
    required String code,
    required String verificationId,
  }) async {
    final verificationToken = await verifyOtp(
      verificationId: verificationId,
      code: code,
    );
    // 传递 email 参数，确保新用户可以正确注册
    return signInOrSignUpWithVerificationToken(
      verificationToken: verificationToken,
      email: email,
    );
  }

  /// 手机验证码登录（完整流程）
  Future<CloudbaseAuthState> signInWithPhoneOtp({
    required String phone,
    required String code,
    required String verificationId,
  }) async {
    final verificationToken = await verifyOtp(
      verificationId: verificationId,
      code: code,
    );
    return signInOrSignUpWithVerificationToken(
      verificationToken: verificationToken,
      phone: phone,
    );
  }

  /// 匿名登录
  Future<CloudbaseAuthState> signInAnonymously() async {
    debugPrint('[CloudBase Auth] 正在匿名登录');

    final response = await _request(
      'POST',
      '/auth/v1/signin/anonymously',
      body: {},
    );

    final state = CloudbaseAuthState.fromJson(response);
    await _saveToken(state);

    debugPrint('[CloudBase Auth] 匿名登录成功: ${state.sub}');
    return state;
  }

  /// 获取 OAuth 登录 URI
  Future<String> getOAuthUri({
    required String providerId,
    String? redirectUri,
    String? state,
  }) async {
    debugPrint('[CloudBase Auth] 获取 OAuth URI: $providerId');

    final queryParams = <String, String>{
      'provider_id': providerId,
    };

    if (redirectUri != null) queryParams['redirect_uri'] = redirectUri;
    if (state != null) queryParams['state'] = state;

    final response = await _request(
      'GET',
      '/auth/v1/provider/uri',
      queryParams: queryParams,
    );

    return response['uri'] as String;
  }

  /// 使用 OAuth 授权码获取 Provider Token
  Future<Map<String, dynamic>> getProviderToken({
    required String providerId,
    required String providerCode,
    String? redirectUri,
  }) async {
    debugPrint('[CloudBase Auth] 获取 Provider Token: $providerId');

    final response = await _request(
      'POST',
      '/auth/v1/provider/token',
      body: {
        'provider_id': providerId,
        'provider_code': providerCode,
        if (redirectUri != null) 'provider_redirect_uri': redirectUri,
      },
    );

    return response;
  }

  /// 使用 Provider Token 登录
  Future<CloudbaseAuthState> signInWithProvider({
    required String providerToken,
    bool syncProfile = true,
  }) async {
    debugPrint('[CloudBase Auth] 使用 Provider Token 登录');

    final response = await _request(
      'POST',
      '/auth/v1/signin/with/provider',
      body: {
        'provider_token': providerToken,
        'sync_profile': syncProfile,
      },
    );

    final state = CloudbaseAuthState.fromJson(response);

    // 获取用户信息
    final user = await _fetchCurrentUser(accessToken: state.accessToken);
    final stateWithUser = state.copyWith(user: user);

    await _saveToken(stateWithUser);
    debugPrint('[CloudBase Auth] OAuth 登录成功: ${stateWithUser.sub}');

    return stateWithUser;
  }

  /// 自定义登录（使用 Ticket）
  Future<CloudbaseAuthState> signInWithCustomTicket(String ticket) async {
    debugPrint('[CloudBase Auth] 使用自定义 Ticket 登录');

    final response = await _request(
      'POST',
      '/auth/v1/signin/custom',
      body: {
        'provider_id': 'custom',
        'ticket': ticket,
      },
    );

    final state = CloudbaseAuthState.fromJson(response);

    // 获取用户信息
    final user = await _fetchCurrentUser(accessToken: state.accessToken);
    final stateWithUser = state.copyWith(user: user);

    await _saveToken(stateWithUser);
    debugPrint('[CloudBase Auth] 自定义登录成功: ${stateWithUser.sub}');

    return stateWithUser;
  }

  // ==================== 用户管理 ====================

  /// 获取当前用户信息
  Future<CloudbaseUser?> getCurrentUser() async {
    if (_currentState?.accessToken == null) return null;
    return _fetchCurrentUser(accessToken: _currentState!.accessToken);
  }

  /// 从 API 获取用户信息
  Future<CloudbaseUser?> _fetchCurrentUser({String? accessToken}) async {
    final token = accessToken ?? _currentState?.accessToken;
    if (token == null) return null;

    try {
      final response = await _request(
        'GET',
        '/auth/v1/user',
        accessToken: token,
      );

      final userData = response['user'] as Map<String, dynamic>? ?? response;
      return CloudbaseUser.fromJson(userData);
    } catch (e) {
      debugPrint('[CloudBase Auth] 获取用户信息失败: $e');
      return null;
    }
  }

  /// 更新用户信息
  Future<CloudbaseUser?> updateUser({
    String? nickname,
    String? avatarUrl,
    String? gender,
    Map<String, dynamic>? metadata,
  }) async {
    if (_currentState?.accessToken == null) {
      throw CloudbaseAuthException(
        code: 'not_authenticated',
        message: '用户未登录',
      );
    }

    debugPrint('[CloudBase Auth] 更新用户信息');

    final body = <String, dynamic>{};

    if (nickname != null) body['nickname'] = nickname;
    if (avatarUrl != null) body['avatar_url'] = avatarUrl;
    if (gender != null) body['gender'] = gender;
    if (metadata != null) body.addAll(metadata);

    await _request(
      'PATCH',
      '/auth/v1/user',
      body: body,
      accessToken: _currentState!.accessToken,
    );

    // 重新获取用户信息
    final user = await _fetchCurrentUser();
    if (user != null) {
      _currentState = _currentState!.copyWith(user: user);
      _authStateController.add(_currentState);
    }

    return user;
  }

  /// 登出
  Future<void> signOut() async {
    debugPrint('[CloudBase Auth] 正在登出');

    if (_currentState?.accessToken != null) {
      try {
        await _request(
          'POST',
          '/auth/v1/signout',
          accessToken: _currentState!.accessToken,
        );
      } catch (e) {
        debugPrint('[CloudBase Auth] 服务端登出失败: $e');
      }
    }

    await _clearToken();
    debugPrint('[CloudBase Auth] 已登出');
  }

  /// 刷新 Token
  Future<CloudbaseAuthState?> refreshToken() async {
    if (_currentState?.refreshToken == null) return null;

    debugPrint('[CloudBase Auth] 刷新 Token');

    try {
      final response = await _request(
        'POST',
        '/auth/v1/token/refresh',
        body: {
          'refresh_token': _currentState!.refreshToken,
        },
      );

      final state = CloudbaseAuthState.fromJson(response);
      final user = await _fetchCurrentUser(accessToken: state.accessToken);
      final stateWithUser = state.copyWith(user: user);

      await _saveToken(stateWithUser);
      debugPrint('[CloudBase Auth] Token 刷新成功');

      return stateWithUser;
    } catch (e) {
      debugPrint('[CloudBase Auth] Token 刷新失败: $e');
      await _clearToken();
      return null;
    }
  }

  /// 发送密码重置验证码
  Future<VerificationResult> sendPasswordResetOtp({
    String? email,
    String? phone,
  }) async {
    if (email == null && phone == null) {
      throw CloudbaseAuthException(
        code: 'invalid_argument',
        message: '必须提供 email 或 phone',
      );
    }

    debugPrint('[CloudBase Auth] 发送密码重置验证码');

    final body = <String, dynamic>{
      'target': 'PASSWORD_RESET',
    };

    if (email != null) body['email'] = email;
    if (phone != null) body['phone_number'] = '+86 $phone';

    final response = await _request(
      'POST',
      '/auth/v1/verification',
      body: body,
    );

    return VerificationResult.fromJson(response);
  }

  /// 重置密码
  Future<void> resetPassword({
    required String verificationToken,
    required String newPassword,
  }) async {
    debugPrint('[CloudBase Auth] 重置密码');

    await _request(
      'POST',
      '/auth/v1/user/password/reset',
      body: {
        'verification_token': verificationToken,
        'password': newPassword,
      },
    );

    debugPrint('[CloudBase Auth] 密码重置成功');
  }

  /// 修改密码（已登录用户）
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    if (_currentState?.accessToken == null) {
      throw CloudbaseAuthException(
        code: 'not_authenticated',
        message: '用户未登录',
      );
    }

    debugPrint('[CloudBase Auth] 修改密码');

    await _request(
      'POST',
      '/auth/v1/user/password/change',
      body: {
        'old_password': oldPassword,
        'new_password': newPassword,
      },
      accessToken: _currentState!.accessToken,
    );

    debugPrint('[CloudBase Auth] 密码修改成功');
  }

  /// 删除账户
  Future<void> deleteAccount({String? password}) async {
    if (_currentState?.accessToken == null) {
      throw CloudbaseAuthException(
        code: 'not_authenticated',
        message: '用户未登录',
      );
    }

    debugPrint('[CloudBase Auth] 删除账户');

    await _request(
      'DELETE',
      '/auth/v1/user',
      body: password != null ? {'password': password} : null,
      accessToken: _currentState!.accessToken,
    );

    await _clearToken();
    debugPrint('[CloudBase Auth] 账户已删除');
  }

  /// 释放资源
  void dispose() {
    _authStateController.close();
  }
}
