import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/check_in_service.dart';
import 'auth_provider.dart';

/// 签到状态
class CheckInState {
  final bool isLoading;
  final bool hasCheckedInToday;
  final int consecutiveDays;
  final CheckInResult? lastResult;
  final String? error;

  const CheckInState({
    this.isLoading = false,
    this.hasCheckedInToday = false,
    this.consecutiveDays = 0,
    this.lastResult,
    this.error,
  });

  CheckInState copyWith({
    bool? isLoading,
    bool? hasCheckedInToday,
    int? consecutiveDays,
    CheckInResult? lastResult,
    String? error,
  }) {
    return CheckInState(
      isLoading: isLoading ?? this.isLoading,
      hasCheckedInToday: hasCheckedInToday ?? this.hasCheckedInToday,
      consecutiveDays: consecutiveDays ?? this.consecutiveDays,
      lastResult: lastResult ?? this.lastResult,
      error: error,
    );
  }
}

/// 签到状态管理 Notifier
class CheckInNotifier extends StateNotifier<CheckInState> {
  final CheckInService _checkInService;
  final Ref _ref;

  CheckInNotifier(this._checkInService, this._ref)
      : super(const CheckInState()) {
    _init();
  }

  /// 初始化签到状态
  Future<void> _init() async {
    final userId = _getUserId();
    if (userId == null) return;

    state = state.copyWith(isLoading: true);

    try {
      final hasCheckedIn = await _checkInService.hasCheckedInToday(userId);
      final consecutiveDays = await _checkInService.getConsecutiveDays(userId);

      state = state.copyWith(
        isLoading: false,
        hasCheckedInToday: hasCheckedIn,
        consecutiveDays: consecutiveDays,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '加载签到状态失败: $e',
      );
    }
  }

  /// 执行签到
  Future<CheckInResult?> checkIn() async {
    final userId = _getUserId();
    if (userId == null) {
      state = state.copyWith(error: '请先登录');
      return null;
    }

    if (state.hasCheckedInToday) {
      return CheckInResult.failure('今日已签到');
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _checkInService.checkIn(userId);

      state = state.copyWith(
        isLoading: false,
        hasCheckedInToday: result.success,
        consecutiveDays: result.consecutiveDays,
        lastResult: result,
        error: result.success ? null : result.errorMessage,
      );

      return result;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '签到失败: $e',
      );
      return null;
    }
  }

  /// 刷新签到状态
  Future<void> refresh() async {
    await _init();
  }

  /// [调试用] 重置签到状态
  Future<void> resetCheckIn() async {
    final userId = _getUserId();
    if (userId == null) return;

    state = state.copyWith(isLoading: true);
    await _checkInService.resetCheckIn(userId);
    state = state.copyWith(
      isLoading: false,
      hasCheckedInToday: false,
      consecutiveDays: 0,
    );
  }

  /// 清除最后结果（关闭对话框后调用）
  void clearLastResult() {
    state = state.copyWith(lastResult: null);
  }

  /// 获取当前用户 ID
  String? _getUserId() {
    final authState = _ref.read(authStateProvider);
    return authState.valueOrNull?.uid;
  }
}

/// 签到 Provider
final checkInProvider =
    StateNotifierProvider<CheckInNotifier, CheckInState>((ref) {
  final checkInService = ref.watch(checkInServiceProvider);
  return CheckInNotifier(checkInService, ref);
});

/// 获取指定天数的奖励
final rewardForDayProvider = Provider.family<CheckInReward, int>((ref, day) {
  final checkInService = ref.watch(checkInServiceProvider);
  return checkInService.getRewardForDay(day);
});

/// 获取一周奖励配置
final weeklyRewardsProvider = Provider<List<CheckInReward>>((ref) {
  final checkInService = ref.watch(checkInServiceProvider);
  return checkInService.weeklyRewards;
});
