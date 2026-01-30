import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// 设置页面
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('设置'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 通知设置
              _buildSectionTitle('通知设置'),
              const SizedBox(height: 8),
              _buildSettingsCard([
                _SettingsSwitchItem(
                  title: '推送通知',
                  subtitle: '接收宠物状态提醒',
                  value: true,
                  onChanged: (value) {
                    // TODO: 保存设置
                  },
                ),
                const Divider(height: 1, indent: 16),
                _SettingsSwitchItem(
                  title: '声音',
                  subtitle: '宠物互动音效',
                  value: true,
                  onChanged: (value) {
                    // TODO: 保存设置
                  },
                ),
              ]),

              const SizedBox(height: 24),

              // 显示设置
              _buildSectionTitle('显示设置'),
              const SizedBox(height: 8),
              _buildSettingsCard([
                _SettingsSwitchItem(
                  title: '深色模式',
                  subtitle: '使用深色主题',
                  value: false,
                  onChanged: (value) {
                    // TODO: 切换主题
                  },
                ),
              ]),

              const SizedBox(height: 24),

              // 关于
              _buildSectionTitle('关于'),
              const SizedBox(height: 8),
              _buildSettingsCard([
                _SettingsItem(
                  title: '版本',
                  trailing: Text(
                    '1.0.0',
                    style: AppTextStyles.caption,
                  ),
                ),
                const Divider(height: 1, indent: 16),
                _SettingsItem(
                  title: '隐私政策',
                  onTap: () {
                    // TODO: 打开隐私政策
                  },
                ),
                const Divider(height: 1, indent: 16),
                _SettingsItem(
                  title: '用户协议',
                  onTap: () {
                    // TODO: 打开用户协议
                  },
                ),
              ]),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: AppTextStyles.body2.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

/// 设置开关项
class _SettingsSwitchItem extends StatelessWidget {
  const _SettingsSwitchItem({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.body1),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

/// 设置普通项
class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    required this.title,
    this.trailing,
    this.onTap,
  });

  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(title, style: AppTextStyles.body1),
            ),
            if (trailing != null) trailing!,
            if (onTap != null)
              Icon(
                Icons.chevron_right,
                color: AppColors.textHint,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
