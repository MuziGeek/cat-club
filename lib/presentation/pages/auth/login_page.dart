import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/auth_provider.dart';
import '../../router/app_router.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';

/// 登录页面
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  bool _obscurePassword = true;
  bool _isPhoneLogin = false; // 切换登录方式
  bool _codeSent = false;
  String? _verificationId;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(loginProvider.notifier).signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (!mounted) return;

    if (success) {
      context.go(AppRoutes.petRoom);
    }
  }

  Future<void> _handleSendPhoneCode() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length != 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入正确的11位手机号')),
      );
      return;
    }

    final result = await ref.read(loginProvider.notifier).sendPhoneOtp(phone);

    if (!mounted) return;

    if (result != null) {
      setState(() {
        _codeSent = true;
        _verificationId = result.verificationId;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('验证码已发送')),
      );
    }
  }

  Future<void> _handlePhoneLogin() async {
    if (_verificationId == null || _codeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入验证码')),
      );
      return;
    }

    final success = await ref.read(loginProvider.notifier).signInWithPhoneOtp(
          phone: _phoneController.text.trim(),
          verificationId: _verificationId!,
          code: _codeController.text.trim(),
        );

    if (!mounted) return;

    if (success) {
      context.go(AppRoutes.petRoom);
    }
  }

  void _toggleLoginMethod() {
    setState(() {
      _isPhoneLogin = !_isPhoneLogin;
      _codeSent = false;
      _verificationId = null;
      _codeController.clear();
    });
  }

  String _getErrorMessage(Object error) {
    final errorStr = error.toString().toLowerCase();
    if (errorStr.contains('user-not-found')) {
      return '用户不存在';
    } else if (errorStr.contains('wrong-password')) {
      return '密码错误';
    } else if (errorStr.contains('invalid-email')) {
      return '邮箱格式错误';
    } else if (errorStr.contains('too-many-requests')) {
      return '登录尝试次数过多，请稍后再试';
    } else if (errorStr.contains('network')) {
      return '网络连接失败';
    }
    return '登录失败，请重试';
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginProvider);
    final isLoading = loginState.isLoading;

    // 监听错误并显示提示
    ref.listen<AsyncValue<void>>(loginProvider, (previous, next) {
      next.whenOrNull(
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_getErrorMessage(error))),
          );
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
                const SizedBox(height: 60),

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
                  '欢迎回来',
                  style: AppTextStyles.h2,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '登录后继续与你的宠物互动',
                  style: AppTextStyles.body2,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // 根据登录方式显示不同的输入框
                if (!_isPhoneLogin) ...[
                  // 邮箱密码登录
                  AppTextField(
                    controller: _emailController,
                    label: '邮箱',
                    hint: '请输入邮箱地址',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入邮箱';
                      }
                      if (!value.contains('@')) {
                        return '请输入有效的邮箱地址';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 密码输入
                  AppTextField(
                    controller: _passwordController,
                    label: '密码',
                    hint: '请输入密码',
                    obscureText: _obscurePassword,
                    prefixIcon: Icons.lock_outlined,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.textHint,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入密码';
                      }
                      if (value.length < 6) {
                        return '密码至少6位';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // 忘记密码
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // TODO: 忘记密码
                      },
                      child: const Text('忘记密码？'),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 登录按钮
                  AppButton(
                    text: '登录',
                    onPressed: isLoading ? null : _handleLogin,
                    isLoading: isLoading,
                  ),
                ] else ...[
                  // 手机验证码登录
                  AppTextField(
                    controller: _phoneController,
                    label: '手机号',
                    hint: '请输入11位手机号',
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icons.phone_android,
                    enabled: !_codeSent,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入手机号';
                      }
                      if (value.length != 11) {
                        return '请输入11位手机号';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  if (_codeSent) ...[
                    // 验证码输入
                    AppTextField(
                      controller: _codeController,
                      label: '验证码',
                      hint: '请输入6位验证码',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.security,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入验证码';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // 登录按钮
                    AppButton(
                      text: '登录',
                      onPressed: isLoading ? null : _handlePhoneLogin,
                      isLoading: isLoading,
                    ),
                    const SizedBox(height: 12),

                    // 重新发送
                    Center(
                      child: TextButton(
                        onPressed: isLoading ? null : _handleSendPhoneCode,
                        child: const Text('重新发送验证码'),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 24),

                    // 发送验证码按钮
                    AppButton(
                      text: '发送验证码',
                      onPressed: isLoading ? null : _handleSendPhoneCode,
                      isLoading: isLoading,
                    ),
                  ],
                ],
                const SizedBox(height: 16),

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

                // 切换登录方式按钮
                OutlinedButton.icon(
                  onPressed: isLoading ? null : _toggleLoginMethod,
                  icon: Icon(_isPhoneLogin ? Icons.email_outlined : Icons.phone_android),
                  label: Text(_isPhoneLogin ? '使用邮箱密码登录' : '使用手机验证码登录'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 32),

                // 注册入口
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '还没有账号？',
                      style: AppTextStyles.body2,
                    ),
                    TextButton(
                      onPressed: () => context.push(AppRoutes.register),
                      child: const Text('立即注册'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
