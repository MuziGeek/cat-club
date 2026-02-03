import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/item_definitions.dart';
import '../../../providers/check_in_provider.dart';
import '../../../services/check_in_service.dart';

/// 显示签到对话框
/// 返回 true 表示签到成功，需要刷新数据
Future<bool> showCheckInDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const CheckInDialog(),
  );
  return result ?? false;
}

/// 签到对话框
class CheckInDialog extends ConsumerStatefulWidget {
  const CheckInDialog({super.key});

  @override
  ConsumerState<CheckInDialog> createState() => _CheckInDialogState();
}

class _CheckInDialogState extends ConsumerState<CheckInDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _showResult = false;
  CheckInResult? _result;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleCheckIn() async {
    final result = await ref.read(checkInProvider.notifier).checkIn();
    if (result != null && result.success) {
      setState(() {
        _showResult = true;
        _result = result;
      });
      _animationController.reset();
      _animationController.forward();
    }
  }

  /// 关闭对话框并返回结果
  void _closeAndRefresh() {
    ref.read(checkInProvider.notifier).clearLastResult();
    // 返回 true 表示签到成功，由调用方刷新数据
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final checkInState = ref.watch(checkInProvider);
    final weeklyRewards = ref.watch(weeklyRewardsProvider);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 340,
          padding: const EdgeInsets.all(16),
          child: _showResult && _result != null
              ? _buildResultContent(_result!)
              : _buildCheckInContent(checkInState, weeklyRewards),
        ),
      ),
    );
  }

  Widget _buildCheckInContent(
    CheckInState state,
    List<CheckInReward> weeklyRewards,
  ) {
    // 计算当前应该签到的天数（1-7）
    // consecutiveDays=0: 未签到过，当前是第1天
    // consecutiveDays=1且已签到: 今天签了第1天
    // consecutiveDays=1且未签到: 昨天签了第1天，今天是第2天
    int currentDay;
    if (state.consecutiveDays == 0) {
      currentDay = 1;
    } else if (state.hasCheckedInToday) {
      // 今天已签到，显示已签到的天数
      currentDay = ((state.consecutiveDays - 1) % 7) + 1;
    } else {
      // 今天未签到，显示将要签到的天数
      currentDay = (state.consecutiveDays % 7) + 1;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 标题
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '每日签到',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // [调试] 重置签到按钮
                IconButton(
                  onPressed: () async {
                    await ref.read(checkInProvider.notifier).resetCheckIn();
                  },
                  icon: const Icon(Icons.refresh, size: 20),
                  tooltip: '重置签到(调试)',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 连续签到天数
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '已连续签到 ${state.consecutiveDays} 天',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 7天奖励 - 使用 Row 替代 GridView 避免溢出
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(7, (index) {
            final day = index + 1;
            final reward = weeklyRewards[index];

            // 计算已完成的天数
            bool isCompleted;
            if (state.hasCheckedInToday) {
              // 今天已签到：已签到天数在周期内的位置
              final todayInCycle = ((state.consecutiveDays - 1) % 7) + 1;
              isCompleted = day <= todayInCycle;
            } else {
              // 今天未签到：昨天签到的天数在周期内的位置
              if (state.consecutiveDays == 0) {
                isCompleted = false;
              } else {
                final yesterdayInCycle = ((state.consecutiveDays - 1) % 7) + 1;
                isCompleted = day <= yesterdayInCycle;
              }
            }

            final isCurrent = day == currentDay && !state.hasCheckedInToday;

            return _buildDayCard(
              day: day,
              reward: reward,
              isCompleted: isCompleted,
              isCurrent: isCurrent,
            );
          }),
        ),
        const SizedBox(height: 16),

        // 签到按钮
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: state.hasCheckedInToday || state.isLoading
                ? null
                : _handleCheckIn,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              disabledBackgroundColor: Colors.grey[300],
            ),
            child: state.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    state.hasCheckedInToday ? '今日已签到' : '立即签到',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildDayCard({
    required int day,
    required CheckInReward reward,
    required bool isCompleted,
    required bool isCurrent,
  }) {
    Color bgColor;
    Color textColor;
    Color iconColor;

    if (isCompleted) {
      bgColor = const Color(0xFFE8F5E9);
      textColor = const Color(0xFF4CAF50);
      iconColor = const Color(0xFF4CAF50);
    } else if (isCurrent) {
      bgColor = const Color(0xFFFFF3E0);
      textColor = const Color(0xFFFF6B6B);
      iconColor = const Color(0xFFFF6B6B);
    } else {
      bgColor = Colors.grey[100]!;
      textColor = Colors.grey[600]!;
      iconColor = Colors.grey[400]!;
    }

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: isCurrent
              ? Border.all(color: const Color(0xFFFF6B6B), width: 2)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '第$day天',
              style: TextStyle(
                fontSize: 9,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            if (isCompleted)
              Icon(Icons.check_circle, color: iconColor, size: 16)
            else if (day == 7)
              Icon(Icons.card_giftcard, color: iconColor, size: 16)
            else
              Icon(Icons.monetization_on, color: iconColor, size: 16),
            const SizedBox(height: 4),
            Text(
              '+${reward.coins}',
              style: TextStyle(
                fontSize: 9,
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultContent(CheckInResult result) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 成功图标
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
            ),
          ),
          child: const Icon(
            Icons.check,
            color: Colors.white,
            size: 48,
          ),
        ),
        const SizedBox(height: 16),

        // 签到成功标题
        const Text(
          '签到成功！',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        Text(
          '连续签到 ${result.consecutiveDays} 天',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 24),

        // 奖励展示
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              const Text(
                '获得奖励',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),

              // 金币奖励
              if (result.reward.coins > 0)
                _buildRewardRow(
                  icon: Icons.monetization_on,
                  color: const Color(0xFFFFB300),
                  text: '金币 +${result.reward.coins}',
                ),

              // 钻石奖励
              if (result.reward.diamonds > 0) ...[
                const SizedBox(height: 8),
                _buildRewardRow(
                  icon: Icons.diamond,
                  color: const Color(0xFF00BCD4),
                  text: '钻石 +${result.reward.diamonds}',
                ),
              ],

              // 道具奖励
              ...result.reward.items.entries.map((entry) {
                final item = ItemDefinitions.getItem(entry.key);
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _buildRewardRow(
                    icon: Icons.inventory_2,
                    color: const Color(0xFF9C27B0),
                    text: '${item?.name ?? entry.key} x${entry.value}',
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 确认按钮 - 关闭时刷新数据
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _closeAndRefresh,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text(
              '太棒了！',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRewardRow({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
