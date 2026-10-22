import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/feed.dart';
import '../../providers/feed_provider.dart';

class FeedStockScreen extends ConsumerWidget {
  const FeedStockScreen({super.key});

  void _showDistributionDialog(BuildContext context, WidgetRef ref, FeedProduct prod) {
    final qtyController = TextEditingController();
    final reasonController = TextEditingController(text: 'Distribution ration quotidienne');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Distribuer : ${prod.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Stock actuel : ${prod.currentStock} ${prod.unit}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: qtyController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Quantité distribuée (${prod.unit}) *',
                suffixText: prod.unit,
                prefixIcon: const Icon(Icons.remove_circle_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Motif ou Lot concerné',
                prefixIcon: Icon(Icons.info_outline),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final q = double.tryParse(qtyController.text);
              if (q == null || q <= 0) return;
              Navigator.pop(ctx);
              try {
                await ref.read(feedServiceProvider).recordStockExit(
                      feedProductId: prod.id,
                      quantity: q,
                      reason: reasonController.text.trim(),
                    );
                ref.invalidate(feedProductsProvider);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.danger),
                  );
                }
              }
            },
            child: const Text('Enregistrer distribution'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(feedProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stocks & Aliments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(feedProductsProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(feedProductsProvider),
        child: productsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Erreur : $err')),
          data: (products) {
            if (products.isEmpty) {
              return const Center(child: Text('Catalogue des aliments vide.'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final p = products[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                p.name,
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: p.isLowStock
                                    ? AppColors.danger.withOpacity(0.15)
                                    : AppColors.success.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                p.isLowStock ? 'Seuil critique !' : 'Stock OK',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: p.isLowStock ? AppColors.danger : AppColors.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Catégorie : ${p.category} • Prix unitaire : ${Formatters.formatCFA(p.unitPriceCfa)} / ${p.unit}',
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 12),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${p.currentStock} ${p.unit}',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: p.isLowStock ? AppColors.danger : AppColors.primary,
                                  ),
                                ),
                                Text(
                                  'Seuil d\'alerte : ${p.minStockThreshold} ${p.unit}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              ),
                              icon: const Icon(Icons.outbox, size: 18),
                              label: const Text('Distribuer', style: TextStyle(fontSize: 13)),
                              onPressed: () => _showDistributionDialog(context, ref, p),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
