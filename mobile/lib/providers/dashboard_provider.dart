import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/dashboard.dart';

final dashboardProvider = FutureProvider<DashboardData>((ref) async {
  final api = ApiClient();
  final res = await api.dio.get(ApiEndpoints.dashboard);
  return DashboardData.fromJson(res.data as Map<String, dynamic>);
});
