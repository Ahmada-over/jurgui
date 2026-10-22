import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/reproduction.dart';

final pregnanciesProvider = FutureProvider<List<Pregnancy>>((ref) async {
  final api = ApiClient();
  final res = await api.dio.get(ApiEndpoints.pregnancies, queryParameters: {'status': 'in_progress'});
  return (res.data as List<dynamic>).map((p) => Pregnancy.fromJson(p as Map<String, dynamic>)).toList();
});

final matingsProvider = FutureProvider<List<MatingEvent>>((ref) async {
  final api = ApiClient();
  final res = await api.dio.get(ApiEndpoints.matings);
  return (res.data as List<dynamic>).map((m) => MatingEvent.fromJson(m as Map<String, dynamic>)).toList();
});

class ReproductionService {
  final ApiClient _api = ApiClient();

  Future<MatingEvent> recordMating({
    required String femaleId,
    String? ramId,
    required DateTime matingDate,
    String matingType = 'natural',
    String? notes,
  }) async {
    final res = await _api.dio.post(
      ApiEndpoints.matings,
      data: {
        'female_id': femaleId,
        'ram_id': ramId,
        'mating_date': matingDate.toIso8601String(),
        'mating_type': matingType,
        'status': 'observed',
        'notes': notes,
      },
    );
    return MatingEvent.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Pregnancy> createPregnancy({
    required String femaleId,
    String? ramId,
    int? matingEventId,
    required DateTime startDate,
    int gestationDurationDays = 150,
    String confirmationStatus = 'confirmed',
    String? notes,
  }) async {
    final res = await _api.dio.post(
      ApiEndpoints.pregnancies,
      data: {
        'female_id': femaleId,
        'ram_id': ramId,
        'mating_event_id': matingEventId,
        'start_date': "${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}",
        'gestation_duration_days': gestationDurationDays,
        'confirmation_status': confirmationStatus,
        'notes': notes,
      },
    );
    return Pregnancy.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Birth> recordBirth({
    int? pregnancyId,
    required String femaleId,
    String? ramId,
    required DateTime birthDate,
    required int totalLambs,
    required int aliveCount,
    required int stillbornCount,
    required int maleCount,
    required int femaleCount,
    String? difficulties,
    List<Map<String, dynamic>> newLambs = const [],
  }) async {
    final res = await _api.dio.post(
      ApiEndpoints.births,
      data: {
        'pregnancy_id': pregnancyId,
        'female_id': femaleId,
        'ram_id': ramId,
        'birth_date': birthDate.toIso8601String(),
        'total_lambs': totalLambs,
        'alive_count': aliveCount,
        'stillborn_count': stillbornCount,
        'male_count': maleCount,
        'female_count': femaleCount,
        'difficulties': difficulties,
        'new_lambs': newLambs,
      },
    );
    return Birth.fromJson(res.data as Map<String, dynamic>);
  }
}

final reproductionServiceProvider = Provider((ref) => ReproductionService());
