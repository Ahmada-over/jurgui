import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/animal.dart';
import 'dashboard_provider.dart';

class AnimalsFilter {
  final int? breedId;
  final int? sectorId;
  final String? sex;
  final String? status;
  final String? searchQuery;

  AnimalsFilter({
    this.breedId,
    this.sectorId,
    this.sex,
    this.status = 'active',
    this.searchQuery,
  });

  AnimalsFilter copyWith({
    int? breedId,
    int? sectorId,
    String? sex,
    String? status,
    String? searchQuery,
    bool clearBreed = false,
    bool clearSector = false,
  }) {
    return AnimalsFilter(
      breedId: clearBreed ? null : (breedId ?? this.breedId),
      sectorId: clearSector ? null : (sectorId ?? this.sectorId),
      sex: sex ?? this.sex,
      status: status ?? this.status,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class AnimalsFilterNotifier extends Notifier<AnimalsFilter> {
  @override
  AnimalsFilter build() => AnimalsFilter();

  void setFilter(AnimalsFilter f) => state = f;
}

final animalsFilterProvider = NotifierProvider<AnimalsFilterNotifier, AnimalsFilter>(() {
  return AnimalsFilterNotifier();
});

final breedsProvider = FutureProvider<List<Breed>>((ref) async {
  final api = ApiClient();
  final res = await api.dio.get(ApiEndpoints.breeds);
  return (res.data as List<dynamic>).map((b) => Breed.fromJson(b as Map<String, dynamic>)).toList();
});

final sectorsProvider = FutureProvider<List<Sector>>((ref) async {
  final api = ApiClient();
  final res = await api.dio.get(ApiEndpoints.sectors);
  return (res.data as List<dynamic>).map((s) => Sector.fromJson(s as Map<String, dynamic>)).toList();
});

class AnimalsListNotifier extends AsyncNotifier<List<Animal>> {
  @override
  Future<List<Animal>> build() async {
    final filter = ref.watch(animalsFilterProvider);
    final api = ApiClient();

    final queryParams = <String, dynamic>{
      'status': filter.status ?? 'active',
    };
    if (filter.breedId != null) queryParams['breed_id'] = filter.breedId;
    if (filter.sectorId != null) queryParams['sector_id'] = filter.sectorId;
    if (filter.sex != null) queryParams['sex'] = filter.sex;
    if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
      queryParams['search'] = filter.searchQuery;
    }

    final res = await api.dio.get(ApiEndpoints.animals, queryParameters: queryParams);
    return (res.data as List<dynamic>)
        .map((a) => Animal.fromJson(a as Map<String, dynamic>))
        .toList();
  }

  /// Met à jour instantanément la liste en mémoire sans attendre un nouvel appel réseau
  void upsertAnimal(Animal animal) {
    final current = state.value;
    if (current != null) {
      final idx = current.indexWhere((a) => a.id == animal.id);
      if (idx >= 0) {
        final next = [...current];
        next[idx] = animal;
        state = AsyncData(next);
      } else {
        state = AsyncData([animal, ...current]);
      }
    } else {
      ref.invalidateSelf();
    }
    ref.invalidate(dashboardProvider);
    ref.invalidate(sectorsProvider);
  }
}

final animalsListProvider =
    AsyncNotifierProvider<AnimalsListNotifier, List<Animal>>(() {
  return AnimalsListNotifier();
});

final animalDetailProvider = FutureProvider.family<Animal, String>((ref, animalId) async {
  final api = ApiClient();
  final res = await api.dio.get('${ApiEndpoints.animals}/$animalId');
  return Animal.fromJson(res.data as Map<String, dynamic>);
});

class AnimalActionsService {
  final ApiClient _api = ApiClient();

  Future<Animal> createAnimal(Map<String, dynamic> data) async {
    final res = await _api.dio.post(ApiEndpoints.animals, data: data);
    return Animal.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Animal> updateAnimal(String animalId, Map<String, dynamic> data) async {
    final res = await _api.dio.put('${ApiEndpoints.animals}/$animalId', data: data);
    return Animal.fromJson(res.data as Map<String, dynamic>);
  }

  Future<AnimalMovement> moveAnimalSector(String animalId, int toSectorId, String reason) async {
    final res = await _api.dio.post(
      '${ApiEndpoints.animals}/$animalId/move',
      data: {'to_sector_id': toSectorId, 'reason': reason},
    );
    return AnimalMovement.fromJson(res.data as Map<String, dynamic>);
  }

  Future<WeightRecord> addWeight(String animalId, double weightKg, String? notes) async {
    final res = await _api.dio.post(
      '${ApiEndpoints.animals}/$animalId/weights',
      data: {'weight_kg': weightKg, 'notes': notes},
    );
    return WeightRecord.fromJson(res.data as Map<String, dynamic>);
  }
}

final animalActionsServiceProvider = Provider((ref) => AnimalActionsService());
