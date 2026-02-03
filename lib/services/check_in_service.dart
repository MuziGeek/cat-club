import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/item_definitions.dart';

/// 签到服务 Provider
final checkInServiceProvider = Provider<CheckInService>((ref) {
  return CheckInService();
});

/// 签到奖励配置
class CheckInReward {
  final int coins;
  final int diamonds;
  final Map<String, int> items;
  final String description;

  const CheckInReward({
    this.coins = 0,
    this.diamonds = 0,
    this.items = const {},
    this.description = '',
  });

  /// 是否有道具奖励
  bool get hasItems => items.isNotEmpty;
}

/// 签到结果
class CheckInResult {
  final bool success;
  final int consecutiveDays;
  final CheckInReward reward;
  final String? errorMessage;

  const CheckInResult({
    required this.success,
    required this.consecutiveDays,
    required this.reward,
    this.errorMessage,
  });

  factory CheckInResult.failure(String message) {
    return CheckInResult(
      success: false,
      consecutiveDays: 0,
      reward: const CheckInReward(),
      errorMessage: message,
    );
  }
}

/// 每日签到服务
class CheckInService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 签到奖励配置（按连续天数）
  static const Map<int, CheckInReward> _rewardConfig = {
    1: CheckInReward(coins: 50, description: '第1天'),
    2: CheckInReward(coins: 80, description: '第2天'),
    3: CheckInReward(coins: 100, items: {'food_fish': 2}, description: '第3天'),
    4: CheckInReward(coins: 120, description: '第4天'),
    5: CheckInReward(coins: 150, items: {'food_treat': 2}, description: '第5天'),
    6: CheckInReward(coins: 180, description: '第6天'),
    7: CheckInReward(
      coins: 300,
      diamonds: 10,
      items: {'food_premium_fish': 1, 'clean_brush': 1},
      description: '第7天 - 周奖励',
    ),
  };

  /// 获取指定天数的奖励
  CheckInReward getRewardForDay(int day) {
    // 循环 7 天奖励
    final dayInCycle = ((day - 1) % 7) + 1;
    return _rewardConfig[dayInCycle] ?? const CheckInReward(coins: 50);
  }

  /// 获取所有 7 天奖励配置
  List<CheckInReward> get weeklyRewards {
    return List.generate(7, (index) => _rewardConfig[index + 1]!);
  }

  /// 执行签到
  Future<CheckInResult> checkIn(String userId) async {
    print('[CHECK_IN_SERVICE] 开始签到, userId=$userId');
    final userRef = _firestore.collection('users').doc(userId);

    return _firestore.runTransaction<CheckInResult>((transaction) async {
      final doc = await transaction.get(userRef);
      if (!doc.exists) {
        print('[CHECK_IN_SERVICE] 用户不存在');
        return CheckInResult.failure('用户不存在');
      }

      final data = doc.data()!;
      final lastSignInDate = _parseDate(data['lastSignInDate']);
      final currentDays = data['consecutiveDays'] as int? ?? 0;
      final currentCoins = data['coins'] as int? ?? 0;
      print('[CHECK_IN_SERVICE] 当前状态: consecutiveDays=$currentDays, coins=$currentCoins');

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // 检查是否已签到
      if (lastSignInDate != null) {
        final lastDate = DateTime(
          lastSignInDate.year,
          lastSignInDate.month,
          lastSignInDate.day,
        );

        if (lastDate == today) {
          return CheckInResult.failure('今日已签到');
        }

        // 计算新的连续天数
        final yesterday = today.subtract(const Duration(days: 1));
        final isConsecutive = lastDate == yesterday;

        final newDays = isConsecutive ? currentDays + 1 : 1;
        final reward = getRewardForDay(newDays);
        print('[CHECK_IN_SERVICE] 计算奖励: newDays=$newDays, reward.coins=${reward.coins}');

        // 更新签到数据
        final updates = <String, dynamic>{
          'lastSignInDate': Timestamp.fromDate(now),
          'consecutiveDays': newDays,
          'coins': FieldValue.increment(reward.coins),
        };

        if (reward.diamonds > 0) {
          updates['diamonds'] = FieldValue.increment(reward.diamonds);
        }

        // 添加道具奖励
        for (final entry in reward.items.entries) {
          updates['inventory.${entry.key}'] = FieldValue.increment(entry.value);
        }

        print('[CHECK_IN_SERVICE] 正在更新 Firestore: $updates');
        transaction.update(userRef, updates);
        print('[CHECK_IN_SERVICE] Firestore 更新完成');

        return CheckInResult(
          success: true,
          consecutiveDays: newDays,
          reward: reward,
        );
      } else {
        // 首次签到
        const reward = CheckInReward(coins: 100, description: '首次签到奖励');

        transaction.update(userRef, {
          'lastSignInDate': Timestamp.fromDate(now),
          'consecutiveDays': 1,
          'coins': FieldValue.increment(reward.coins),
        });

        return const CheckInResult(
          success: true,
          consecutiveDays: 1,
          reward: reward,
        );
      }
    });
  }

  /// 检查今日是否已签到
  Future<bool> hasCheckedInToday(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) return false;

    final data = doc.data()!;
    final lastSignInDate = _parseDate(data['lastSignInDate']);
    if (lastSignInDate == null) return false;

    final now = DateTime.now();
    return lastSignInDate.year == now.year &&
        lastSignInDate.month == now.month &&
        lastSignInDate.day == now.day;
  }

  /// 获取当前连续签到天数
  Future<int> getConsecutiveDays(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) return 0;

    final data = doc.data()!;
    return data['consecutiveDays'] as int? ?? 0;
  }

  /// [调试用] 重置签到状态
  Future<void> resetCheckIn(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'lastSignInDate': null,
      'consecutiveDays': 0,
    });
  }

  /// 解析日期
  DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
