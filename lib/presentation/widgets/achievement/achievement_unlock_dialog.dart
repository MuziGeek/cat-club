import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/achievement_definitions.dart';
import '../../../data/models/achievement_model.dart';

/// 成就解锁弹窗
///
/// 当用户解锁新成就时显示的动画弹窗
class AchievementUnlockDialog extends StatefulWidget {
  final AchievementModel achievement;
  final VoidCallback? onClaimReward;

  const AchievementUnlockDialog({
    super.key,
    required this.achievement,
    this.onClaimReward,
  });

  /// 显示成就解锁弹窗
  static Future<void> show(
    BuildContext context,
    AchievementModel achievement, {
    VoidCallback? onClaimReward,
  }) async {
    // 触感反馈
    HapticFeedback.mediumImpact();

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '关闭',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return AchievementUnlockDialog(
          achievement: achievement,
          onClaimReward: onClaimReward,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );
        return ScaleTransition(
          scale: curvedAnimation,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<AchievementUnlockDialog> createState() => _AchievementUnlockDialogState();
}

class _AchievementUnlockDialogState extends State<AchievementUnlockDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _shineController;
  late Animation<double> _shineAnimation;

  @override
  void initState() {
    super.initState();
    _shineController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _shineAnimation = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _shineController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.emoji_events,
                    color: Colors.amber.shade600,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '成就解锁！',
                    style: AppTextStyles.h3.copyWith(
                      color: Colors.amber.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 成就图标（带闪光效果）
              _buildAchievementIcon(),
              const SizedBox(height: 16),

              // 成就名称
              Text(
                widget.achievement.name,
                style: AppTextStyles.h4.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // 成就描述
              Text(
                widget.achievement.description,
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // 奖励展示
              _buildRewardSection(),
              const SizedBox(height: 24),

              // 按钮
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        '稍后领取',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onClaimReward?.call();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '立即领取',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建成就图标（带闪光效果）
  Widget _buildAchievementIcon() {
    return AnimatedBuilder(
      animation: _shineAnimation,
      builder: (context, child) {
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _getCategoryColor(widget.achievement.category),
                _getCategoryColor(widget.achievement.category).withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _getCategoryColor(widget.achievement.category).withOpacity(0.4),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Stack(
            children: [
              // 闪光效果
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Transform.translate(
                  offset: Offset(_shineAnimation.value * 80, 0),
                  child: Container(
                    width: 30,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0),
                          Colors.white.withOpacity(0.3),
                          Colors.white.withOpacity(0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // 图标
              Center(
                child: Icon(
                  _getIconData(widget.achievement.icon),
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 构建奖励区域
  Widget _buildRewardSection() {
    final reward = widget.achievement.reward;
    final items = <Widget>[];

    if (reward.coins > 0) {
      items.add(_buildRewardItem(Icons.monetization_on, Colors.amber, '${reward.coins} 金币'));
    }
    if (reward.diamonds > 0) {
      items.add(_buildRewardItem(Icons.diamond, Colors.blue, '${reward.diamonds} 钻石'));
    }
    if (reward.items.isNotEmpty) {
      final count = reward.items.values.fold(0, (a, b) => a + b);
      items.add(_buildRewardItem(Icons.card_giftcard, Colors.purple, '$count 道具'));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        children: [
          Text(
            '🎁 奖励',
            style: TextStyle(
              fontSize: 12,
              color: Colors.amber.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: items,
          ),
        ],
      ),
    );
  }

  Widget _buildRewardItem(IconData icon, Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Color _getCategoryColor(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.interaction:
        return Colors.pink;
      case AchievementCategory.growth:
        return Colors.green;
      case AchievementCategory.checkIn:
        return Colors.orange;
      case AchievementCategory.collection:
        return Colors.purple;
    }
  }

  IconData _getIconData(String iconName) {
    final iconMap = <String, IconData>{
      'favorite': Icons.favorite,
      'favorite_border': Icons.favorite_border,
      'pets': Icons.pets,
      'restaurant': Icons.restaurant,
      'restaurant_menu': Icons.restaurant_menu,
      'sports_esports': Icons.sports_esports,
      'bathtub': Icons.bathtub,
      'star': Icons.star,
      'star_half': Icons.star_half,
      'stars': Icons.stars,
      'calendar_today': Icons.calendar_today,
      'event_available': Icons.event_available,
      'event_note': Icons.event_note,
      'inventory_2': Icons.inventory_2,
      'backpack': Icons.backpack,
      'groups': Icons.groups,
    };
    return iconMap[iconName] ?? Icons.emoji_events;
  }
}
