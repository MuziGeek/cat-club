import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/achievement_definitions.dart';
import '../../../data/models/achievement_model.dart';
import '../../../providers/achievement_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/achievement/achievement_card.dart';

/// 成就展示页面
class AchievementPage extends ConsumerStatefulWidget {
  const AchievementPage({super.key});

  @override
  ConsumerState<AchievementPage> createState() => _AchievementPageState();
}

class _AchievementPageState extends ConsumerState<AchievementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _categories = [
    null, // 全部
    AchievementCategory.interaction,
    AchievementCategory.growth,
    AchievementCategory.checkIn,
    AchievementCategory.collection,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(achievementStatsProvider);
    final userAchievementsAsync = ref.watch(userAchievementsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('成就'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // 成就进度
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.emoji_events, color: Colors.amber.shade600, size: 18),
                const SizedBox(width: 4),
                Text(
                  '${stats.unlockedCount}/${stats.totalCount}',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: _categories.map((category) {
            if (category == null) {
              return const Tab(text: '全部');
            }
            return Tab(text: category.displayName);
          }).toList(),
        ),
      ),
      body: userAchievementsAsync.when(
        data: (userAchievements) {
          return TabBarView(
            controller: _tabController,
            children: _categories.map((category) {
              return _buildAchievementList(category, userAchievements);
            }).toList(),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
    );
  }

  /// 构建成就列表
  Widget _buildAchievementList(
    AchievementCategory? category,
    List<UserAchievement> userAchievements,
  ) {
    // 获取成就列表
    final achievements = category == null
        ? AchievementDefinitions.all
        : AchievementDefinitions.getByCategory(category);

    // 构建用户进度映射
    final userProgressMap = {
      for (final ua in userAchievements) ua.achievementId: ua
    };

    // 构建带进度的成就列表
    final achievementsWithProgress = achievements.map((a) {
      final userProgress = userProgressMap[a.id] ??
          UserAchievement(achievementId: a.id);
      return AchievementWithProgress(
        achievement: a,
        userProgress: userProgress,
      );
    }).toList();

    // 排序：可领取 > 未解锁 > 已领取
    achievementsWithProgress.sort((a, b) {
      if (a.canClaimReward && !b.canClaimReward) return -1;
      if (!a.canClaimReward && b.canClaimReward) return 1;
      if (!a.isUnlocked && b.isUnlocked) return -1;
      if (a.isUnlocked && !b.isUnlocked) return 1;
      return 0;
    });

    if (achievements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined, size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text('暂无成就', style: AppTextStyles.body1),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: achievementsWithProgress.length,
      itemBuilder: (context, index) {
        final achievement = achievementsWithProgress[index];
        return AchievementCard(
          achievement: achievement,
          onClaimReward: achievement.canClaimReward
              ? () => _claimReward(achievement.achievement.id)
              : null,
        );
      },
    );
  }

  /// 领取成就奖励
  Future<void> _claimReward(String achievementId) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    final success = await ref.read(achievementNotifierProvider.notifier).claimReward(
      userId: userId,
      achievementId: achievementId,
    );

    if (!mounted) return;

    if (success) {
      final achievement = AchievementDefinitions.getById(achievementId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text('已领取 ${achievement?.name ?? ''} 奖励'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 12),
              Text('领取失败，请重试'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }
}
