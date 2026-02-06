import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/auth_provider.dart';
import '../../router/app_router.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';

/// 注册页面
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  bool _agreeToTerms = false;
  bool _codeSent = false;
  String? _verificationId;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  /// 发送验证码
  Future<void> _handleSendCode() async {
    // 验证邮箱
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效的邮箱地址')),
      );
      return;
    }

    final result = await ref.read(registerProvider.notifier).sendEmailOtp(email);

    if (!mounted) return;

    if (result != null) {
      setState(() {
        _codeSent = true;
        _verificationId = result.verificationId;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('验证码已发送，请查收邮件')),
      );
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请同意用户协议和隐私政策')),
      );
      return;
    }

    if (!_codeSent || _verificationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先获取验证码')),
      );
      return;
    }

    final success = await ref.read(registerProvider.notifier).registerWithEmailOtp(
          email: _emailController.text.trim(),
          code: _codeController.text.trim(),
          verificationId: _verificationId!,
          displayName: _nameController.text.trim(),
        );

    if (!mounted) return;

    if (success) {
      context.go(AppRoutes.petCreate);
    }
  }

  String _getErrorMessage(Object error) {
    final errorStr = error.toString().toLowerCase();
    if (errorStr.contains('email-already-in-use')) {
      return '该邮箱已被注册';
    } else if (errorStr.contains('invalid-email')) {
      return '邮箱格式错误';
    } else if (errorStr.contains('weak-password')) {
      return '密码强度不够';
    } else if (errorStr.contains('network')) {
      return '网络连接失败';
    }
    return '注册失败，请重试';
  }

  @override
  Widget build(BuildContext context) {
    final registerState = ref.watch(registerProvider);
    final isLoading = registerState.isLoading;

    // 监听错误并显示提示
    ref.listen<AsyncValue<void>>(registerProvider, (previous, next) {
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 标题
                Text(
                  '创建账号',
                  style: AppTextStyles.h2,
                ),
                const SizedBox(height: 8),
                Text(
                  '注册后开启你的虚拟养宠之旅',
                  style: AppTextStyles.body2,
                ),
                const SizedBox(height: 32),

                // 昵称输入
                AppTextField(
                  controller: _nameController,
                  label: '昵称',
                  hint: '给自己起个名字吧',
                  prefixIcon: Icons.person_outlined,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入昵称';
                    }
                    if (value.length < 2) {
                      return '昵称至少2个字符';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 邮箱输入
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

                // 验证码输入
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _codeController,
                        label: '验证码',
                        hint: '请输入邮箱验证码',
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.security_outlined,
                        enabled: _codeSent,
                        validator: (value) {
                          if (!_codeSent) return null;
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
                      padding: const EdgeInsets.only(bottom: 4),
                      child: SizedBox(
                        width: 120,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _handleSendCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(_codeSent ? '重新发送' : '获取验证码'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 同意条款
                Row(
                  children: [
                    Checkbox(
                      value: _agreeToTerms,
                      onChanged: (value) {
                        setState(() => _agreeToTerms = value ?? false);
                      },
                      activeColor: AppColors.primary,
                    ),
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
                const SizedBox(height: 24),

                // 注册按钮
                AppButton(
                  text: '注册',
                  onPressed: isLoading ? null : _handleRegister,
                  isLoading: isLoading,
                ),
                const SizedBox(height: 24),

                // 登录入口
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '已有账号？',
                      style: AppTextStyles.body2,
                    ),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('立即登录'),
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
