import '../../data/models/pet_model.dart';

/// 状态衰减计算器
///
/// 根据离线时间计算宠物状态的衰减值
class StatusDecayCalculator {
  StatusDecayCalculator._();

  /// 每小时衰减速率
  static const double _happinessDecayRate = 2.0;
  static const double _hungerDecayRate = 3.0;
  static const double _energyDecayRate = 1.5;
  static const double _cleanlinessDecayRate = 2.0;
  static const double _healthDecayRate = 0.5;

  /// 低状态阈值（低于此值健康衰减加速）
  static const int _lowStatusThreshold = 20;

  /// 健康加速衰减系数
  static const double _healthAcceleratedDecayMultiplier = 2.0;

  /// 最大计算离线时间（小时）
  static const int _maxOfflineHours = 24;

  /// 计算状态衰减
  ///
  /// [pet] 宠物模型
  /// [currentTime] 当前时间（用于测试可注入）
  ///
  /// 返回衰减后的 PetStatus，如果是纪念模式则返回原状态
  static PetStatus calculateDecay(PetModel pet, {DateTime? currentTime}) {
    // 纪念模式宠物不衰减
    if (pet.isMemorial) {
      return pet.status;
    }

    final now = currentTime ?? DateTime.now();
    final lastInteraction = pet.lastInteractionAt;

    // 计算离线时间（小时）
    final offlineDuration = now.difference(lastInteraction);
    final offlineHours = offlineDuration.inMinutes / 60.0;

    // 限制最大离线时间
    final effectiveHours = offlineHours.clamp(0.0, _maxOfflineHours.toDouble());

    if (effectiveHours <= 0) {
      return pet.status;
    }

    // 计算各状态衰减
    final newHappiness = _applyDecay(
      pet.status.happiness,
      _happinessDecayRate,
      effectiveHours,
    );

    final newHunger = _applyDecay(
      pet.status.hunger,
      _hungerDecayRate,
      effectiveHours,
    );

    final newEnergy = _applyDecay(
      pet.status.energy,
      _energyDecayRate,
      effectiveHours,
    );

    final newCleanliness = _applyDecay(
      pet.status.cleanliness,
      _cleanlinessDecayRate,
      effectiveHours,
    );

    // 健康衰减：如果饱腹或心情过低，加速衰减
    double healthDecayRate = _healthDecayRate;
    if (newHunger < _lowStatusThreshold || newHappiness < _lowStatusThreshold) {
      healthDecayRate *= _healthAcceleratedDecayMultiplier;
    }

    final newHealth = _applyDecay(
      pet.status.health,
      healthDecayRate,
      effectiveHours,
    );

    return PetStatus(
      happiness: newHappiness,
      hunger: newHunger,
      energy: newEnergy,
      health: newHealth,
      cleanliness: newCleanliness,
    );
  }

  /// 应用衰减计算
  static int _applyDecay(int currentValue, double rate, double hours) {
    final decay = (rate * hours).round();
    return (currentValue - decay).clamp(0, 100);
  }

  /// 计算需要同步到服务器的衰减状态
  ///
  /// 返回 null 表示无需更新（衰减量为 0 或纪念模式）
  static PetStatus? getDecayedStatusIfNeeded(PetModel pet, {DateTime? currentTime}) {
    if (pet.isMemorial) return null;

    final decayedStatus = calculateDecay(pet, currentTime: currentTime);

    // 检查是否有变化
    if (decayedStatus.happiness == pet.status.happiness &&
        decayedStatus.hunger == pet.status.hunger &&
        decayedStatus.energy == pet.status.energy &&
        decayedStatus.health == pet.status.health &&
        decayedStatus.cleanliness == pet.status.cleanliness) {
      return null;
    }

    return decayedStatus;
  }
}
