import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/feed.dart';
import 'dashboard_provider.dart';

class FeedProductsNotifier extends AsyncNotifier<List<FeedProduct>> {
  @override
  Future<List<FeedProduct>> build() async {
    final api = ApiClient();
    final res = await api.dio.get(ApiEndpoints.feedProducts);
    return (res.data as List<dynamic>)
        .map((p) => FeedProduct.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  /// Met à jour instantanément le stock d'un produit en mémoire (optimistic update)
  void adjustStockOptimistically(int feedProductId, double delta) {
    final current = state.value;
    if (current != null) {
      state = AsyncData(
        current.map((p) {
          if (p.id == feedProductId) {
            final nextStock = (p.currentStock + delta).clamp(0.0, double.infinity);
            return p.copyWith(currentStock: nextStock);
          }
          return p;
        }).toList(),
      );
    }
    ref.invalidate(dashboardProvider);
  }
}

final feedProductsProvider =
    AsyncNotifierProvider<FeedProductsNotifier, List<FeedProduct>>(() {
  return FeedProductsNotifier();
});

class FeedService {
  final ApiClient _api = ApiClient();

  Future<void> recordStockExit({
    required int feedProductId,
    required double quantity,
    required String reason,
  }) async {
    await _api.dio.post(
      ApiEndpoints.stockMovements,
      data: {
        'feed_product_id': feedProductId,
        'movement_type': 'out_feeding',
        'quantity': quantity,
        'reason': reason,
      },
    );
  }

  Future<void> recordStockEntry({
    required int feedProductId,
    required double quantity,
    double? unitPriceCfa,
    String? supplier,
  }) async {
    await _api.dio.post(
      ApiEndpoints.stockMovements,
      data: {
        'feed_product_id': feedProductId,
        'movement_type': 'in_purchase',
        'quantity': quantity,
        'unit_price_cfa': unitPriceCfa,
        'supplier': supplier,
        'reason': 'Réapprovisionnement stock',
      },
    );
  }
}

final feedServiceProvider = Provider((ref) => FeedService());
