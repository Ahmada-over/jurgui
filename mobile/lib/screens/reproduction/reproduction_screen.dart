import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/reproduction.dart';
import '../../providers/reproduction_provider.dart';

class ReproductionScreen extends ConsumerWidget {
  const ReproductionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pregnanciesAsync = ref.watch(pregnanciesProvider);
    final matingsAsync = ref.watch(matingsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reproduction & Gestation'),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Gestations en cours', icon: Icon(Icons.pregnant_woman)),
              Tab(text: 'Saillies enregistrées', icon: Icon(Icons.favorite)),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                ref.invalidate(pregnanciesProvider);
                ref.invalidate(matingsProvider);
              },
            ),
          ],
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton.extended(
              heroTag: 'fab_birth',
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.child_care),
              label: const Text('Déclarer mise bas'),
              onPressed: () => context.push('/reproduction/birth'),
            ),
            const SizedBox(height: 10),
            FloatingActionButton.extended(
              heroTag: 'fab_mating',
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Nouvelle saillie'),
              onPressed: () => context.push('/reproduction/mating'),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            // Tab 1: Gestations
            RefreshIndicator(
              onRefresh: () async => ref.refresh(pregnanciesProvider),
              child: pregnanciesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Erreur: $err')),
                data: (pregnancies) {
                  if (pregnancies.isEmpty) {
                    return const Center(
                      child: Text(
                        'Aucune gestation en cours suivie.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount: pregnancies.length,
                    itemBuilder: (context, index) {
                      final preg = pregnancies[index];
                      return _buildPregnancyCard(context, preg);
                    },
                  );
                },
              ),
            ),

            // Tab 2: Saillies
            RefreshIndicator(
              onRefresh: () async => ref.refresh(matingsProvider),
              child: matingsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Erreur: $err')),
                data: (matings) {
                  if (matings.isEmpty) {
                    return const Center(
                      child: Text(
                        'Aucune saillie enregistrée.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount: matings.length,
                    itemBuilder: (context, index) {
                      final m = matings[index];
                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: AppColors.secondaryContainer,
                            child: Icon(Icons.favorite, color: AppColors.secondary),
                          ),
                          title: Text(
                            'Brebis : ${m.femaleId} × Bélier : ${m.ramId ?? "Non spécifié"}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Date : ${Formatters.formatDateTime(m.matingDate)} • Type : ${m.matingType}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              m.status,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPregnancyCard(BuildContext context, Pregnancy preg) {
    final progress = (preg.currentDay / preg.gestationDurationDays).clamp(0.0, 1.0);
    final daysLeft = preg.daysRemaining;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.secondaryContainer,
                      child: Icon(Icons.pregnant_woman, color: AppColors.secondary),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Brebis : ${preg.femaleId}',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Reproducteur : ${preg.ramId ?? "Non précisé"}',
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    daysLeft > 0 ? 'Dans $daysLeft j' : 'Mise bas imminente !',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: daysLeft <= 5 ? AppColors.danger : AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Progress bar J+X / 150
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Évolution : J+${preg.currentDay} / ${preg.gestationDurationDays}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                Text(
                  'Prévue : ${Formatters.formatDate(preg.expectedBirthDate)}',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              borderRadius: BorderRadius.circular(6),
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(
                daysLeft <= 10 ? AppColors.danger : AppColors.secondary,
              ),
            ),
            const SizedBox(height: 16),

            // Gestation Milestones (J+90, J+105, J+120, J+135, J+145, J+150)
            const Text(
              'Jalons & Échéances de soins :',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            ...preg.timeline.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Icon(
                        item.isPassed ? Icons.check_circle : Icons.radio_button_unchecked,
                        size: 16,
                        color: item.isPassed ? AppColors.success : AppColors.textMuted,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'J+${item.dayOffset} (${Formatters.formatDate(item.targetDate)}) :',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: item.isPassed ? AppColors.textMuted : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 12,
                            color: item.isPassed ? AppColors.textMuted : AppColors.textSecondary,
                            decoration: item.isPassed ? TextDecoration.lineThrough : null,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
