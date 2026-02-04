import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/achievement_definitions.dart';
import '../../../data/models/achievement_model.dart';
import '../../../providers/achievement_provider.dart';

/// 成就卡片组件
class AchievementCard extends StatelessWidget {
  final AchievementWithProgress achievement;
  final VoidCallback? onClaimReward;

  const AchievementCard({
    super.key,
    required this.achievement,
    this.onClaimReward,
  });

  @override
  Widget build(BuildContext context) {
    final isUnlocked = achievement.isUnlocked;
    final canClaim = achievement.canClaimReward;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isUnlocked ? Colors.white : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: canClaim
              ? AppColors.primary
              : isUnlocked
                  ? Colors.green.shade200
                  : AppColors.border,
          width: canClaim ? 2 : 1,
        ),
        boxShadow: canClaim
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // 成就图标
            _buildIcon(),
            const SizedBox(width: 12),

            // 成就信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 名称和状态
                  Row(
                    children: [
                      Text(
                        achievement.achievement.name,
                        style: AppTextStyles.body1.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isUnlocked ? null : AppColors.textSecondary,
                        ),
                      ),
                      if (isUnlocked && !canClaim) ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Colors.green.shade400,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),

                  // 描述
                  Text(
                    achievement.achievement.description,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 进度条或奖励
                  if (!isUnlocked)
                    _buildProgressBar()
                  else
                    _buildRewardInfo(),
                ],
              ),
            ),

            // 领取按钮
            if (canClaim)
              ElevatedButton(
                onPressed: onClaimReward,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('领取'),
              ),
          ],
        ),
      ),
    );
  }

  /// 构建成就图标
  Widget _buildIcon() {
    final isUnlocked = achievement.isUnlocked;
    final iconName = achievement.achievement.icon;

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: isUnlocked
            ? _getCategoryColor(achievement.achievement.category).withOpacity(0.1)
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        _getIconData(iconName),
        size: 28,
        color: isUnlocked
            ? _getCategoryColor(achievement.achievement.category)
            : Colors.grey.shade400,
      ),
    );
  }

  /// 构建进度条
  Widget _buildProgressBar() {
    final progress = achievement.progressPercent;
    final current = achievement.currentValue;
    final target = achievement.targetValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primary.withOpacity(0.7),
                  ),
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$current/$target',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建奖励信息
  Widget _buildRewardInfo() {
    final reward = achievement.achievement.reward;
    final items = <Widget>[];

    if (reward.coins > 0) {
      items.add(_buildRewardChip(Icons.monetization_on, Colors.amber, '${reward.coins}'));
    }
    if (reward.diamonds > 0) {
      items.add(_buildRewardChip(Icons.diamond, Colors.blue, '${reward.diamonds}'));
    }
    if (reward.items.isNotEmpty) {
      items.add(_buildRewardChip(Icons.card_giftcard, Colors.purple, '道具x${reward.items.values.fold(0, (a, b) => a + b)}'));
    }

    return Wrap(
      spacing: 8,
      children: items,
    );
  }

  Widget _buildRewardChip(IconData icon, Color color, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 获取类别颜色
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

  /// 根据图标名称获取 IconData
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
      'touch_app': Icons.touch_app,
      'trending_up': Icons.trending_up,
      'calendar_month': Icons.calendar_month,
      'collections': Icons.collections,
    };
    return iconMap[iconName] ?? Icons.emoji_events;
  }
}
