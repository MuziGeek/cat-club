import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/achievement_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/check_in_provider.dart';
import '../../../providers/pet_provider.dart';
import '../../../providers/user_provider.dart';
import '../../router/app_router.dart';

/// 个人中心页面
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final petsAsync = ref.watch(userPetsProvider);
    final checkInState = ref.watch(checkInProvider);
    final achievementStats = ref.watch(achievementStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 24),

              // 用户头像和信息
              _buildUserHeader(userAsync),

              const SizedBox(height: 24),

              // 货币信息
              _buildCurrencyCard(userAsync),

              const SizedBox(height: 16),

              // 统计数据
              _buildStatsCard(petsAsync, checkInState, achievementStats),

              const SizedBox(height: 16),

              // 菜单列表
              _buildMenuList(context, ref),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  /// 用户头像和信息
  Widget _buildUserHeader(AsyncValue userAsync) {
    final user = userAsync.valueOrNull;
    final String displayName = (user?.displayName as String?) ?? '未设置昵称';
    final String email = (user?.email as String?) ?? '';

    return Column(
      children: [
        // 头像
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person,
            size: 40,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),

        // 昵称
        Text(
          displayName,
          style: AppTextStyles.h3,
        ),
        const SizedBox(height: 4),

        // 邮箱
        Text(
          email,
          style: AppTextStyles.caption,
        ),
      ],
    );
  }

  /// 货币信息卡片
  Widget _buildCurrencyCard(AsyncValue userAsync) {
    final user = userAsync.valueOrNull;
    final int coins = (user?.coins as int?) ?? 0;
    final int diamonds = (user?.diamonds as int?) ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            // 金币
            Expanded(
              child: _CurrencyItem(
                icon: Icons.monetization_on,
                iconColor: Colors.amber,
                label: '金币',
                value: _formatNumber(coins),
              ),
            ),

            Container(
              width: 1,
              height: 40,
              color: AppColors.divider,
            ),

            // 钻石
            Expanded(
              child: _CurrencyItem(
                icon: Icons.diamond,
                iconColor: Colors.blue,
                label: '钻石',
                value: _formatNumber(diamonds),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 统计数据卡片
  Widget _buildStatsCard(AsyncValue petsAsync, CheckInState checkInState, AchievementStats achievementStats) {
    final pets = petsAsync.valueOrNull ?? [];
    final petCount = pets.length;
    final consecutiveDays = checkInState.consecutiveDays;
    final unlockedCount = achievementStats.unlockedCount;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            // 宠物数量
            Expanded(
              child: _StatItem(
                label: '宠物',
                value: petCount.toString(),
              ),
            ),

            // 签到天数
            Expanded(
              child: _StatItem(
                label: '签到',
                value: consecutiveDays.toString(),
              ),
            ),

            // 成就
            Expanded(
              child: _StatItem(
                label: '成就',
                value: unlockedCount.toString(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 菜单列表
  Widget _buildMenuList(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
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
        child: Column(
          children: [
            _MenuItem(
              icon: Icons.pets,
              iconColor: AppColors.primary,
              title: '我的宠物',
              onTap: () => context.push(AppRoutes.petRoom),
            ),
            const Divider(height: 1, indent: 56),

            _MenuItem(
              icon: Icons.inventory_2,
              iconColor: AppColors.accent,
              title: '我的背包',
              onTap: () {
                // TODO: 背包页面
              },
            ),
            const Divider(height: 1, indent: 56),

            _MenuItem(
              icon: Icons.emoji_events,
              iconColor: Colors.amber,
              title: '成就',
              onTap: () => context.push(AppRoutes.achievements),
            ),
            const Divider(height: 1, indent: 56),

            _MenuItem(
              icon: Icons.settings,
              iconColor: AppColors.textSecondary,
              title: '设置',
              onTap: () => context.push(AppRoutes.settings),
            ),
            const Divider(height: 1, indent: 56),

            _MenuItem(
              icon: Icons.logout,
              iconColor: AppColors.error,
              title: '退出登录',
              showArrow: false,
              onTap: () => _showLogoutDialog(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  /// 退出登录确认弹窗
  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authServiceProvider).signOut();
              if (context.mounted) {
                context.go(AppRoutes.login);
              }
            },
            child: Text(
              '退出',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

/// 货币项组件
class _CurrencyItem extends StatelessWidget {
  const _CurrencyItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 8),
            Text(
              value,
              style: AppTextStyles.h3,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.caption,
        ),
      ],
    );
  }
}

/// 统计项组件
class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.h3.copyWith(
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.caption,
        ),
      ],
    );
  }
}

/// 菜单项组件
class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
    this.showArrow = true,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.body1,
              ),
            ),
            if (showArrow)
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
