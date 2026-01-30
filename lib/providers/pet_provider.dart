import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/status_decay_calculator.dart';
import '../data/models/pet_model.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';
import 'user_provider.dart';

/// 用户所有宠物流 Provider
final userPetsProvider = StreamProvider<List<PetModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);

  return authState.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      return firestoreService.userPetsStream(user.uid);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

/// 当前选中宠物 ID Provider
final selectedPetIdProvider = StateProvider<String?>((ref) => null);

/// 当前选中宠物数据 Provider
final selectedPetProvider = StreamProvider<PetModel?>((ref) {
  final petId = ref.watch(selectedPetIdProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);

  if (petId == null) return Stream.value(null);
  return firestoreService.petStream(petId);
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
  final FirestoreService _firestoreService;
  final Ref _ref;

  PetCreateNotifier(this._firestoreService, this._ref)
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
      final authState = _ref.read(authStateProvider);
      final userId = authState.valueOrNull?.uid;
      if (userId == null) throw Exception('用户未登录');

      final now = DateTime.now();
      final pet = PetModel(
        id: '', // 由 Firestore 生成
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
      final petId = await _firestoreService.createPet(pet);

      // 添加宠物到用户
      await _firestoreService.addPetToUser(userId, petId);

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
}

/// 宠物创建 Provider
final petCreateProvider =
    StateNotifierProvider<PetCreateNotifier, PetCreateState>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return PetCreateNotifier(firestoreService, ref);
});

/// 宠物互动 Notifier
class PetInteractionNotifier extends StateNotifier<AsyncValue<void>> {
  final FirestoreService _firestoreService;
  final Ref _ref;

  PetInteractionNotifier(this._firestoreService, this._ref)
      : super(const AsyncValue.data(null));

  /// 同步衰减状态到 Firestore
  /// 在互动前调用，确保衰减后的状态被持久化
  Future<PetStatus> _syncDecayedStatus(PetModel pet) async {
    // 计算衰减后的状态
    final decayedStatus = StatusDecayCalculator.calculateDecay(pet);

    // 如果状态有变化，同步到 Firestore
    if (decayedStatus != pet.status) {
      await _firestoreService.updatePetStatus(
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
      final pet = await _firestoreService.getPet(petId);
      if (pet == null) throw Exception('宠物不存在');

      // 先同步衰减状态
      final decayedStatus = await _syncDecayedStatus(pet);

      // 基于衰减后的状态计算新状态值（不超过100）
      final newHunger = (decayedStatus.hunger + hungerGain).clamp(0, 100);
      final newHappiness = (decayedStatus.happiness + 5).clamp(0, 100);

      // 更新状态
      await _firestoreService.updatePetStatus(
        petId,
        hunger: newHunger,
        happiness: newHappiness,
      );

      // 更新成长数据
      await _firestoreService.updatePetStats(
        petId,
        experienceGain: 10,
        intimacyGain: 5,
        incrementFeedings: true,
      );

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
      final pet = await _firestoreService.getPet(petId);
      if (pet == null) throw Exception('宠物不存在');

      // 先同步衰减状态
      final decayedStatus = await _syncDecayedStatus(pet);

      final newHappiness = (decayedStatus.happiness + 15).clamp(0, 100);

      await _firestoreService.updatePetStatus(
        petId,
        happiness: newHappiness,
      );

      await _firestoreService.updatePetStats(
        petId,
        experienceGain: 5,
        intimacyGain: 10,
        incrementInteractions: true,
      );

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
      final pet = await _firestoreService.getPet(petId);
      if (pet == null) throw Exception('宠物不存在');

      // 先同步衰减状态
      final decayedStatus = await _syncDecayedStatus(pet);

      final newEnergy = (decayedStatus.energy + 30).clamp(0, 100);

      await _firestoreService.updatePetStatus(
        petId,
        energy: newEnergy,
      );

      await _firestoreService.updatePetStats(
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
      final pet = await _firestoreService.getPet(petId);
      if (pet == null) throw Exception('宠物不存在');

      // 先同步衰减状态
      final decayedStatus = await _syncDecayedStatus(pet);

      // 清洁效果: 清洁度+25, 心情+10, 健康+5
      final newCleanliness = (decayedStatus.cleanliness + cleanlinessGain).clamp(0, 100);
      final newHappiness = (decayedStatus.happiness + 10).clamp(0, 100);
      final newHealth = (decayedStatus.health + 5).clamp(0, 100);

      await _firestoreService.updatePetStatus(
        petId,
        cleanliness: newCleanliness,
        happiness: newHappiness,
        health: newHealth,
      );

      // 经验+8, 亲密度+8
      await _firestoreService.updatePetStats(
        petId,
        experienceGain: 8,
        intimacyGain: 8,
        incrementInteractions: true,
      );

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
      final pet = await _firestoreService.getPet(petId);
      if (pet == null) throw Exception('宠物不存在');

      // 先同步衰减状态
      final decayedStatus = await _syncDecayedStatus(pet);

      // 玩耍效果: 心情+20, 精力-10
      final newHappiness = (decayedStatus.happiness + 20).clamp(0, 100);
      final newEnergy = (decayedStatus.energy - 10).clamp(0, 100);

      await _firestoreService.updatePetStatus(
        petId,
        happiness: newHappiness,
        energy: newEnergy,
      );

      // 经验+10, 亲密度+15
      await _firestoreService.updatePetStats(
        petId,
        experienceGain: 10,
        intimacyGain: 15,
        incrementInteractions: true,
      );

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// 重置状态
  void reset() {
    state = const AsyncValue.data(null);
  }
}

/// 宠物互动 Provider
final petInteractionProvider =
    StateNotifierProvider<PetInteractionNotifier, AsyncValue<void>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return PetInteractionNotifier(firestoreService, ref);
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
