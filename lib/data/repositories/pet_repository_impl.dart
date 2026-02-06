import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/exceptions/cloudbase_exception.dart';
import '../../data/datasources/cloudbase_rest_client.dart';
import '../../data/mappers/pet_mapper.dart';
import '../../data/models/pet_model.dart';
import '../../domain/repositories/pet_repository.dart';

/// 宠物仓库实现
///
/// 使用 CloudBase REST Client 实现宠物数据操作
class PetRepositoryImpl implements PetRepository {
  final CloudbaseRestClient _client;

  PetRepositoryImpl(this._client);

  static const String _table = 'pets';

  @override
  Future<Result<PetModel?>> getPet(String petId) async {
    debugPrint('[PetRepo] getPet: $petId');
    final result = await _client.getOne(_table, petId);
    return result.map((data) {
      if (data == null) return null;
      return PetMapper.fromCloudbase(data, petId);
    });
  }

  @override
  Future<Result<String>> createPet(PetModel pet) async {
    debugPrint('[PetRepo] createPet: ${pet.name}');

    // 确保有有效的 ID
    final petId = pet.id.isNotEmpty ? pet.id : _client.generateUuid();
    final petWithId = pet.id.isEmpty
        ? PetModel(
            id: petId,
            userId: pet.userId,
            name: pet.name,
            species: pet.species,
            breed: pet.breed,
            appearance: pet.appearance,
            originalPhotoUrl: pet.originalPhotoUrl,
            cartoonAvatarUrl: pet.cartoonAvatarUrl,
            generatedAvatars: pet.generatedAvatars,
            status: pet.status,
            stats: pet.stats,
            equippedItems: pet.equippedItems,
            ownedItems: pet.ownedItems,
            isMemorial: pet.isMemorial,
            memorialNote: pet.memorialNote,
            memorialDate: pet.memorialDate,
            createdAt: pet.createdAt,
            updatedAt: pet.updatedAt,
            lastInteractionAt: pet.lastInteractionAt,
          )
        : pet;

    final data = PetMapper.toCloudbase(petWithId);
    final result = await _client.create(_table, data);
    return result.map((_) => petId);
  }

  @override
  Future<Result<void>> updatePet(
    String petId,
    Map<String, dynamic> data,
  ) async {
    debugPrint('[PetRepo] updatePet: $petId');
    return _client.update(_table, petId, data);
  }

  @override
  Future<Result<void>> deletePet(String petId) async {
    debugPrint('[PetRepo] deletePet: $petId');
    return _client.delete(_table, petId);
  }

  @override
  Stream<List<PetModel>> userPetsStream(String userId) {
    late StreamController<List<PetModel>> controller;
    Timer? pollTimer;

    Future<List<PetModel>> fetchPets() async {
      final result = await _client.getList(
        _table,
        filters: {'userId': 'eq.$userId'},
      );
      if (result.isFailure) return [];

      return result.dataOrNull!
          .where((data) => data['id'] != null)
          .map((data) => PetMapper.fromCloudbase(data, data['id'] as String))
          .toList();
    }

    controller = StreamController<List<PetModel>>(
      onListen: () {
        fetchPets().then((pets) {
          if (!controller.isClosed) controller.add(pets);
        });
        pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
          fetchPets().then((pets) {
            if (!controller.isClosed) controller.add(pets);
          });
        });
      },
      onCancel: () {
        pollTimer?.cancel();
      },
    );

    return controller.stream;
  }

  @override
  Stream<PetModel?> petStream(String petId) {
    late StreamController<PetModel?> controller;
    Timer? pollTimer;

    controller = StreamController<PetModel?>(
      onListen: () {
        getPet(petId).then((result) {
          if (!controller.isClosed) {
            controller.add(result.dataOrNull);
          }
        });
        pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
          getPet(petId).then((result) {
            if (!controller.isClosed) {
              controller.add(result.dataOrNull);
            }
          });
        });
      },
      onCancel: () {
        pollTimer?.cancel();
      },
    );

    return controller.stream;
  }

  @override
  Future<Result<void>> updateStatus(
    String petId, {
    int? happiness,
    int? hunger,
    int? energy,
    int? health,
    int? cleanliness,
  }) async {
    debugPrint('[PetRepo] updateStatus: $petId');

    final getResult = await getPet(petId);
    if (getResult.isFailure) return Failure(getResult.exceptionOrNull!);

    final pet = getResult.dataOrNull;
    if (pet == null) {
      return const Failure(NotFoundException('Pet not found'));
    }

    final newStatus = PetStatus(
      happiness: happiness ?? pet.status.happiness,
      hunger: hunger ?? pet.status.hunger,
      energy: energy ?? pet.status.energy,
      health: health ?? pet.status.health,
      cleanliness: cleanliness ?? pet.status.cleanliness,
    );

    return updatePet(petId, PetMapper.toStatusUpdate(newStatus));
  }

  @override
  Future<Result<void>> updateStats(
    String petId, {
    int? experienceGain,
    int? intimacyGain,
    bool incrementFeedings = false,
    bool incrementInteractions = false,
  }) async {
    debugPrint('[PetRepo] updateStats: $petId');

    final getResult = await getPet(petId);
    if (getResult.isFailure) return Failure(getResult.exceptionOrNull!);

    final pet = getResult.dataOrNull;
    if (pet == null) {
      return const Failure(NotFoundException('Pet not found'));
    }

    final newStats = PetStats(
      level: pet.stats.level,
      experience: pet.stats.experience + (experienceGain ?? 0),
      intimacy: pet.stats.intimacy + (intimacyGain ?? 0),
      totalFeedings: pet.stats.totalFeedings + (incrementFeedings ? 1 : 0),
      totalInteractions: pet.stats.totalInteractions + (incrementInteractions ? 1 : 0),
    );

    return updatePet(petId, PetMapper.toStatsUpdate(newStats));
  }
}
