import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/auth_provider.dart';
import '../../router/app_router.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';

/// 认证方式枚举
enum AuthMethod {
  phone,
  email,
}

/// 统一认证页面
///
/// 采用 OTP 验证码认证，自动处理登录/注册：
/// - 新用户：自动创建账号并进入宠物创建页
/// - 老用户：直接进入宠物房间
class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();

  AuthMethod _authMethod = AuthMethod.phone;
  bool _codeSent = false;
  String? _verificationId;
  bool _agreeToTerms = false;
  int _countdown = 0;
  Timer? _countdownTimer;

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _codeController.dispose();
    _nameController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  /// 开始倒计时
  void _startCountdown() {
    setState(() => _countdown = 60);
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
      }
    });
  }

  /// 获取当前输入的账号（手机号或邮箱）
  String get _currentAccount {
    return _authMethod == AuthMethod.phone
        ? _phoneController.text.trim()
        : _emailController.text.trim();
  }

  /// 验证账号格式
  bool _validateAccount() {
    if (_authMethod == AuthMethod.phone) {
      final phone = _phoneController.text.trim();
      if (phone.isEmpty || phone.length != 11) {
        _showError('请输入正确的11位手机号');
        return false;
      }
    } else {
      final email = _emailController.text.trim();
      if (email.isEmpty || !email.contains('@')) {
        _showError('请输入有效的邮箱地址');
        return false;
      }
    }
    return true;
  }

  /// 发送验证码
  Future<void> _handleSendCode() async {
    if (!_validateAccount()) return;

    final authNotifier = ref.read(authNotifierProvider.notifier);
    final result = _authMethod == AuthMethod.phone
        ? await authNotifier.sendPhoneOtp(_phoneController.text.trim())
        : await authNotifier.sendEmailOtp(_emailController.text.trim());

    if (!mounted) return;

    if (result != null) {
      setState(() {
        _codeSent = true;
        _verificationId = result.verificationId;
      });
      _startCountdown();
      _showSuccess(_authMethod == AuthMethod.phone ? '验证码已发送' : '验证码已发送，请查收邮件');
    }
  }

  /// 统一认证（登录/注册一体化）
  Future<void> _handleAuthenticate() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreeToTerms) {
      _showError('请同意用户协议和隐私政策');
      return;
    }

    if (!_codeSent || _verificationId == null) {
      _showError('请先获取验证码');
      return;
    }

    final authNotifier = ref.read(authNotifierProvider.notifier);
    final success = await authNotifier.authenticateWithOtp(
      email: _authMethod == AuthMethod.email ? _emailController.text.trim() : null,
      phone: _authMethod == AuthMethod.phone ? _phoneController.text.trim() : null,
      code: _codeController.text.trim(),
      verificationId: _verificationId!,
      displayName: _nameController.text.trim().isNotEmpty
          ? _nameController.text.trim()
          : null,
    );

    if (!mounted) return;

    if (success) {
      // 路由重定向会自动处理跳转
      context.go(AppRoutes.petRoom);
    }
  }

  /// 匿名登录
  Future<void> _handleAnonymousLogin() async {
    final authNotifier = ref.read(authNotifierProvider.notifier);
    final success = await authNotifier.signInAnonymously();

    if (!mounted) return;

    if (success) {
      context.go(AppRoutes.petRoom);
    }
  }

  /// 切换认证方式
  void _toggleAuthMethod() {
    setState(() {
      _authMethod = _authMethod == AuthMethod.phone
          ? AuthMethod.email
          : AuthMethod.phone;
      _codeSent = false;
      _verificationId = null;
      _codeController.clear();
      _countdown = 0;
      _countdownTimer?.cancel();
    });
  }

  /// 重置验证码状态（重新输入账号）
  void _resetCodeState() {
    setState(() {
      _codeSent = false;
      _verificationId = null;
      _codeController.clear();
      _countdown = 0;
      _countdownTimer?.cancel();
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade400,
      ),
    );
  }

  String _getErrorMessage(Object error) {
    final errorStr = error.toString().toLowerCase();
    if (errorStr.contains('invalid') && errorStr.contains('code')) {
      return '验证码错误或已过期';
    } else if (errorStr.contains('too-many-requests')) {
      return '请求过于频繁，请稍后再试';
    } else if (errorStr.contains('network')) {
      return '网络连接失败';
    } else if (errorStr.contains('invalid-phone')) {
      return '手机号格式错误';
    } else if (errorStr.contains('invalid-email')) {
      return '邮箱格式错误';
    }
    return '操作失败，请重试';
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;

    // 监听错误并显示提示
    ref.listen<AsyncValue<void>>(authNotifierProvider, (previous, next) {
      next.whenOrNull(
        error: (error, _) {
          _showError(_getErrorMessage(error));
        },
      );
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // Logo
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Icon(
                      Icons.pets,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 标题
                Text(
                  'Cat Club',
                  style: AppTextStyles.h1,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '开启你的虚拟养宠之旅',
                  style: AppTextStyles.body2,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // 昵称输入（可选）
                AppTextField(
                  controller: _nameController,
                  label: '昵称（可选）',
                  hint: '给自己起个名字吧',
                  prefixIcon: Icons.person_outlined,
                ),
                const SizedBox(height: 16),

                // 根据认证方式显示不同输入框
                if (_authMethod == AuthMethod.phone) ...[
                  // 手机号输入
                  AppTextField(
                    controller: _phoneController,
                    label: '手机号',
                    hint: '请输入11位手机号',
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icons.phone_android,
                    enabled: !_codeSent,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(11),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入手机号';
                      }
                      if (value.length != 11) {
                        return '请输入11位手机号';
                      }
                      return null;
                    },
                    suffixIcon: _codeSent
                        ? IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: _resetCodeState,
                            tooltip: '修改手机号',
                          )
                        : null,
                  ),
                ] else ...[
                  // 邮箱输入
                  AppTextField(
                    controller: _emailController,
                    label: '邮箱',
                    hint: '请输入邮箱地址',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    enabled: !_codeSent,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入邮箱';
                      }
                      if (!value.contains('@')) {
                        return '请输入有效的邮箱地址';
                      }
                      return null;
                    },
                    suffixIcon: _codeSent
                        ? IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: _resetCodeState,
                            tooltip: '修改邮箱',
                          )
                        : null,
                  ),
                ],
                const SizedBox(height: 16),

                // 验证码输入区域
                if (_codeSent) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _codeController,
                          label: '验证码',
                          hint: '请输入6位验证码',
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.security_outlined,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '请输入验证码';
                            }
                            if (value.length < 4) {
                              return '验证码格式错误';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Padding(
                        padding: const EdgeInsets.only(top: 22),
                        child: SizedBox(
                          width: 100,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: (isLoading || _countdown > 0)
                                ? null
                                : _handleSendCode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              _countdown > 0 ? '${_countdown}s' : '重新发送',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ] else ...[
                  const SizedBox(height: 8),

                  // 发送验证码按钮
                  AppButton(
                    text: '获取验证码',
                    onPressed: isLoading ? null : _handleSendCode,
                    isLoading: isLoading,
                  ),
                  const SizedBox(height: 24),
                ],

                // 同意条款
                Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _agreeToTerms,
                        onChanged: (value) {
                          setState(() => _agreeToTerms = value ?? false);
                        },
                        activeColor: AppColors.primary,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _agreeToTerms = !_agreeToTerms);
                        },
                        child: Text.rich(
                          TextSpan(
                            text: '我已阅读并同意 ',
                            style: AppTextStyles.caption,
                            children: [
                              TextSpan(
                                text: '用户协议',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                              const TextSpan(text: ' 和 '),
                              TextSpan(
                                text: '隐私政策',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                if (_codeSent) ...[
                  const SizedBox(height: 24),

                  // 登录/注册按钮
                  AppButton(
                    text: '登录 / 注册',
                    onPressed: isLoading ? null : _handleAuthenticate,
                    isLoading: isLoading,
                  ),
                ],

                const SizedBox(height: 24),

                // 分割线
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '或',
                        style: AppTextStyles.caption,
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),

                // 切换认证方式
                OutlinedButton.icon(
                  onPressed: isLoading ? null : _toggleAuthMethod,
                  icon: Icon(
                    _authMethod == AuthMethod.phone
                        ? Icons.email_outlined
                        : Icons.phone_android,
                  ),
                  label: Text(
                    _authMethod == AuthMethod.phone
                        ? '使用邮箱验证码'
                        : '使用手机验证码',
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                  ),
                ),
                const SizedBox(height: 12),

                // 匿名体验
                TextButton.icon(
                  onPressed: isLoading ? null : _handleAnonymousLogin,
                  icon: const Icon(Icons.pets_outlined),
                  label: const Text('匿名体验'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
