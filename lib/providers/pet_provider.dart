import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/status_decay_calculator.dart';
import '../data/models/achievement_model.dart';
import '../data/models/pet_model.dart';
import '../services/cloudbase_service.dart';
import '../services/storage_service.dart';
import 'achievement_provider.dart';
import 'auth_provider.dart';
import 'user_provider.dart';

/// 用户所有宠物流 Provider
final userPetsProvider = StreamProvider<List<PetModel>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  final cloudbaseService = ref.watch(cloudbaseServiceProvider);

  if (userId == null) return Stream.value([]);
  return cloudbaseService.userPetsStream(userId);
});

/// 当前选中宠物 ID Provider
final selectedPetIdProvider = StateProvider<String?>((ref) => null);

/// 当前选中宠物数据 Provider
final selectedPetProvider = StreamProvider<PetModel?>((ref) {
  final petId = ref.watch(selectedPetIdProvider);
  final cloudbaseService = ref.watch(cloudbaseServiceProvider);

  if (petId == null) return Stream.value(null);
  return cloudbaseService.petStream(petId);
});

/// 宠物创建状态
class PetCreateState {
  final bool isLoading;
  final String? error;
  final String? createdPetId;

  const PetCreateState({
    this.isLoading = false,
    this.error,
    this.createdPetId,
  });

  PetCreateState copyWith({
    bool? isLoading,
    String? error,
    String? createdPetId,
  }) {
    return PetCreateState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      createdPetId: createdPetId ?? this.createdPetId,
    );
  }
}

/// 宠物创建 Notifier
class PetCreateNotifier extends StateNotifier<PetCreateState> {
  final CloudbaseService _cloudbaseService;
  final Ref _ref;

  PetCreateNotifier(this._cloudbaseService, this._ref)
      : super(const PetCreateState());

  /// 创建宠物
  Future<String?> createPet({
    required String name,
    required PetSpecies species,
    String? breed,
    required PetAppearance appearance,
    String? originalPhotoUrl,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final userId = _ref.read(currentUserIdProvider);
      if (userId == null) throw Exception('用户未登录');

      final now = DateTime.now();
      final pet = PetModel(
        id: '', // 由 CloudBase 生成
        userId: userId,
        name: name,
        species: species,
        breed: breed,
        appearance: appearance,
        originalPhotoUrl: originalPhotoUrl,
        status: const PetStatus(),
        stats: const PetStats(),
        createdAt: now,
        updatedAt: now,
        lastInteractionAt: now,
      );

      // 创建宠物文档
      final petId = await _cloudbaseService.createPet(pet);

      // 添加宠物到用户
      await _cloudbaseService.addPetToUser(userId, petId);

      state = state.copyWith(isLoading: false, createdPetId: petId);
      return petId;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  /// 重置状态
  void reset() {
    state = const PetCreateState();
  }

  /// 检查是否可以创建新宠物
  ///
  /// [userId] 用户 ID
  ///
  /// 返回 (canCreate, currentCount, maxCount)
  Future<(bool, int, int)> canCreatePet(String userId) async {
    final user = await _cloudbaseService.getUser(userId);
    final maxPets = user?.maxPets ?? 4;
    final currentCount = user?.petIds.length ?? 0;
    return (currentCount < maxPets, currentCount, maxPets);
  }
}

/// 宠物创建 Provider
final petCreateProvider =
    StateNotifierProvider<PetCreateNotifier, PetCreateState>((ref) {
  final cloudbaseService = ref.watch(cloudbaseServiceProvider);
  return PetCreateNotifier(cloudbaseService, ref);
});

/// 宠物互动 Notifier
class PetInteractionNotifier extends StateNotifier<AsyncValue<void>> {
  final CloudbaseService _cloudbaseService;
  final Ref _ref;

  PetInteractionNotifier(this._cloudbaseService, this._ref)
      : super(const AsyncValue.data(null));

  /// 放生/删除宠物（永久删除）
  ///
  /// [petId] 宠物 ID
  /// [userId] 用户 ID
  /// [storageService] 可选的 Storage 服务，用于删除照片
  ///
  /// 返回 true 表示删除成功
  Future<bool> releasePet({
    required String petId,
    required String userId,
    StorageService? storageService,
  }) async {
    state = const AsyncValue.loading();
    try {
      // 1. 获取宠物信息（用于删除照片）
      final pet = await _cloudbaseService.getPet(petId);

      // 2. 删除 Storage 中的照片（如果有且提供了 storageService）
      if (storageService != null && pet?.originalPhotoUrl != null && pet!.originalPhotoUrl!.isNotEmpty) {
        try {
          await storageService.deleteImage(pet.originalPhotoUrl!);
        } catch (e) {
          // 照片删除失败不阻塞流程
          debugPrint('删除照片失败: $e');
        }
      }

      // 3. 从用户列表移除
      await _cloudbaseService.removePetFromUser(userId, petId);

      // 4. 删除宠物文档
      await _cloudbaseService.deletePet(petId);

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      debugPrint('放生宠物失败: $e');
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// 同步衰减状态到 CloudBase
  /// 在互动前调用，确保衰减后的状态被持久化
  Future<PetStatus> _syncDecayedStatus(PetModel pet) async {
    // 计算衰减后的状态
    final decayedStatus = StatusDecayCalculator.calculateDecay(pet);

    // 如果状态有变化，同步到 CloudBase
    if (decayedStatus != pet.status) {
      await _cloudbaseService.updatePetStatus(
        pet.id,
        happiness: decayedStatus.happiness,
        hunger: decayedStatus.hunger,
        energy: decayedStatus.energy,
        health: decayedStatus.health,
        cleanliness: decayedStatus.cleanliness,
      );
    }

    return decayedStatus;
  }

  /// 喂食
  Future<bool> feed(String petId, {int hungerGain = 20}) async {
    state = const AsyncValue.loading();
    try {
      // 获取当前宠物状态
      final pet = await _cloudbaseService.getPet(petId);
      if (pet == null) throw Exception('宠物不存在');

      // 先同步衰减状态
      final decayedStatus = await _syncDecayedStatus(pet);

      // 基于衰减后的状态计算新状态值（不超过100）
      final newHunger = (decayedStatus.hunger + hungerGain).clamp(0, 100);
      final newHappiness = (decayedStatus.happiness + 5).clamp(0, 100);

      // 更新状态
      await _cloudbaseService.updatePetStatus(
        petId,
        hunger: newHunger,
        happiness: newHappiness,
      );

      // 更新成长数据
      await _cloudbaseService.updatePetStats(
        petId,
        experienceGain: 10,
        intimacyGain: 5,
        incrementFeedings: true,
      );

      // 更新用户统计并检查成就
      final userId = _ref.read(currentUserIdProvider);
      if (userId != null) {
        await _cloudbaseService.incrementUserStat(userId, 'feedCount');
        final stats = await _cloudbaseService.getUserStats(userId);
        if (stats != null) {
          await _ref.read(achievementNotifierProvider.notifier).checkAndUpdateProgress(
            userId: userId,
            type: AchievementType.feedCount,
            currentValue: stats['feedCount'] ?? 0,
          );
        }
      }

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// 抚摸
  Future<bool> pet(String petId) async {
    state = const AsyncValue.loading();
    try {
      final pet = await _cloudbaseService.getPet(petId);
      if (pet == null) throw Exception('宠物不存在');

      // 先同步衰减状态
      final decayedStatus = await _syncDecayedStatus(pet);

      final newHappiness = (decayedStatus.happiness + 15).clamp(0, 100);

      await _cloudbaseService.updatePetStatus(
        petId,
        happiness: newHappiness,
      );

      await _cloudbaseService.updatePetStats(
        petId,
        experienceGain: 5,
        intimacyGain: 10,
        incrementInteractions: true,
      );

      // 更新用户统计并检查成就
      final userId = _ref.read(currentUserIdProvider);
      if (userId != null) {
        await _cloudbaseService.incrementUserStat(userId, 'petCount');
        final stats = await _cloudbaseService.getUserStats(userId);
        if (stats != null) {
          await _ref.read(achievementNotifierProvider.notifier).checkAndUpdateProgress(
            userId: userId,
            type: AchievementType.petCount,
            currentValue: stats['petCount'] ?? 0,
          );
        }
      }

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// 休息（恢复精力）
  Future<bool> rest(String petId) async {
    state = const AsyncValue.loading();
    try {
      final pet = await _cloudbaseService.getPet(petId);
      if (pet == null) throw Exception('宠物不存在');

      // 先同步衰减状态
      final decayedStatus = await _syncDecayedStatus(pet);

      final newEnergy = (decayedStatus.energy + 30).clamp(0, 100);

      await _cloudbaseService.updatePetStatus(
        petId,
        energy: newEnergy,
      );

      await _cloudbaseService.updatePetStats(
        petId,
        incrementInteractions: true,
      );

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// 清洁
  Future<bool> clean(String petId, {int cleanlinessGain = 25}) async {
    state = const AsyncValue.loading();
    try {
      final pet = await _cloudbaseService.getPet(petId);
      if (pet == null) throw Exception('宠物不存在');

      // 先同步衰减状态
      final decayedStatus = await _syncDecayedStatus(pet);

      // 清洁效果: 清洁度+25, 心情+10, 健康+5
      final newCleanliness = (decayedStatus.cleanliness + cleanlinessGain).clamp(0, 100);
      final newHappiness = (decayedStatus.happiness + 10).clamp(0, 100);
      final newHealth = (decayedStatus.health + 5).clamp(0, 100);

      await _cloudbaseService.updatePetStatus(
        petId,
        cleanliness: newCleanliness,
        happiness: newHappiness,
        health: newHealth,
      );

      // 经验+8, 亲密度+8
      await _cloudbaseService.updatePetStats(
        petId,
        experienceGain: 8,
        intimacyGain: 8,
        incrementInteractions: true,
      );

      // 更新用户统计并检查成就
      final userId = _ref.read(currentUserIdProvider);
      if (userId != null) {
        await _cloudbaseService.incrementUserStat(userId, 'cleanCount');
        final stats = await _cloudbaseService.getUserStats(userId);
        if (stats != null) {
          await _ref.read(achievementNotifierProvider.notifier).checkAndUpdateProgress(
            userId: userId,
            type: AchievementType.cleanCount,
            currentValue: stats['cleanCount'] ?? 0,
          );
        }
      }

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// 玩耍（双击触发）
  Future<bool> play(String petId) async {
    state = const AsyncValue.loading();
    try {
      final pet = await _cloudbaseService.getPet(petId);
      if (pet == null) throw Exception('宠物不存在');

      // 先同步衰减状态
      final decayedStatus = await _syncDecayedStatus(pet);

      // 玩耍效果: 心情+20, 精力-10
      final newHappiness = (decayedStatus.happiness + 20).clamp(0, 100);
      final newEnergy = (decayedStatus.energy - 10).clamp(0, 100);

      await _cloudbaseService.updatePetStatus(
        petId,
        happiness: newHappiness,
        energy: newEnergy,
      );

      // 经验+10, 亲密度+15
      await _cloudbaseService.updatePetStats(
        petId,
        experienceGain: 10,
        intimacyGain: 15,
        incrementInteractions: true,
      );

      // 更新用户统计并检查成就
      final userId = _ref.read(currentUserIdProvider);
      if (userId != null) {
        await _cloudbaseService.incrementUserStat(userId, 'playCount');
        final stats = await _cloudbaseService.getUserStats(userId);
        if (stats != null) {
          await _ref.read(achievementNotifierProvider.notifier).checkAndUpdateProgress(
            userId: userId,
            type: AchievementType.playCount,
            currentValue: stats['playCount'] ?? 0,
          );
        }
      }

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// 同步衰减状态（公开方法，供外部调用）
  ///
  /// 在应用启动/恢复时调用，确保离线期间的状态衰减被持久化
  Future<void> syncDecayedStatusIfNeeded(String petId) async {
    try {
      final pet = await _cloudbaseService.getPet(petId);
      if (pet == null) return;
      await _syncDecayedStatus(pet);
    } catch (e) {
      // 静默失败，不影响用户体验
      debugPrint('同步衰减状态失败: $e');
    }
  }

  /// 重置状态
  void reset() {
    state = const AsyncValue.data(null);
  }

  /// 更新宠物照片
  ///
  /// [petId] 宠物 ID
  /// [photoFile] 新照片文件
  /// [storageService] Storage 服务
  ///
  /// 返回新照片的 URL，失败返回 null
  Future<String?> updatePetPhoto({
    required String petId,
    required File photoFile,
    required StorageService storageService,
  }) async {
    state = const AsyncValue.loading();
    try {
      // 获取用户 ID
      final userId = _ref.read(currentUserIdProvider);
      if (userId == null) throw Exception('用户未登录');

      // 获取当前宠物信息
      final pet = await _cloudbaseService.getPet(petId);
      if (pet == null) throw Exception('宠物不存在');

      // 上传新照片
      final newPhotoUrl = await storageService.uploadPetAvatar(
        userId: userId,
        petId: petId,
        imageFile: photoFile,
      );

      if (newPhotoUrl == null) throw Exception('照片上传失败');

      // 更新宠物文档
      await _cloudbaseService.updatePet(petId, {
        'originalPhotoUrl': newPhotoUrl,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // 如果有旧照片，尝试删除
      if (pet.originalPhotoUrl != null && pet.originalPhotoUrl!.isNotEmpty) {
        try {
          await storageService.deleteImage(pet.originalPhotoUrl!);
        } catch (e) {
          // 删除失败不影响主流程
          debugPrint('删除旧照片失败: $e');
        }
      }

      state = const AsyncValue.data(null);
      return newPhotoUrl;
    } catch (e, st) {
      debugPrint('更新宠物照片失败: $e');
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

/// 宠物互动 Provider
final petInteractionProvider =
    StateNotifierProvider<PetInteractionNotifier, AsyncValue<void>>((ref) {
  final cloudbaseService = ref.watch(cloudbaseServiceProvider);
  return PetInteractionNotifier(cloudbaseService, ref);
});

/// 带状态衰减的选中宠物 Provider
///
/// 在获取宠物数据时自动计算离线衰减
final selectedPetWithDecayProvider = Provider<AsyncValue<PetModel?>>((ref) {
  final petAsync = ref.watch(selectedPetProvider);

  return petAsync.when(
    data: (pet) {
      if (pet == null) return const AsyncValue.data(null);

      // 计算衰减后的状态
      final decayedStatus = StatusDecayCalculator.calculateDecay(pet);

      // 返回带衰减状态的宠物
      return AsyncValue.data(pet.copyWith(status: decayedStatus));
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});
