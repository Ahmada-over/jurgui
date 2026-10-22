import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/formatters.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final authState = ref.watch(authProvider);
    final userName = authState.user?['full_name'] ?? 'Éleveur';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Jur-gui — Dakar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Connecté : $userName',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(dashboardProvider),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(dashboardProvider),
        child: dashboardAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off, size: 48, color: AppColors.danger),
                  const SizedBox(height: 12),
                  const Text(
                    'Connexion au serveur impossible',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    err.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.refresh(dashboardProvider),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          ),
          data: (data) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 4 Stat Cards
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Cheptel Actif',
                      value: '${data.totalActiveAnimals}',
                      subtitle: 'Ovins enregistrés',
                      icon: Icons.pets,
                      color: AppColors.primary,
                      onTap: () => context.go('/animals'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Gestations',
                      value: '${data.activePregnancies}',
                      subtitle: 'Suivies en cours',
                      icon: Icons.favorite,
                      color: AppColors.secondary,
                      onTap: () => context.go('/reproduction'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Stocks Alerte',
                      value: '${data.lowStockAlerts.length}',
                      subtitle: data.lowStockAlerts.isEmpty ? 'Niveaux corrects' : 'Seuils atteints',
                      icon: Icons.warning_amber_rounded,
                      color: data.lowStockAlerts.isEmpty ? AppColors.success : AppColors.danger,
                      onTap: () => context.go('/feed'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Tâches Enclos',
                      value: '${data.pendingTasks}',
                      subtitle: 'À réaliser',
                      icon: Icons.assignment_outlined,
                      color: AppColors.info,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Upcoming Births Card (Module B - J+150 alert)
              if (data.upcomingBirths.isNotEmpty) ...[
                const Text(
                  'Mises Bas Imminentes (30 jours)',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 10),
                ...data.upcomingBirths.map((b) => Card(
                      color: AppColors.secondaryContainer,
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.secondary,
                          child: Icon(Icons.child_care, color: Colors.white),
                        ),
                        title: Text(
                          'Brebis : ${b.femaleId}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Date théorique : ${b.expectedDate} (dans ${b.daysLeft} jours)',
                          style: const TextStyle(fontSize: 13),
                        ),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          onPressed: () => context.go('/reproduction'),
                          child: const Text('Suivi', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    )),
                const SizedBox(height: 20),
              ],

              // Breeds breakdown
              const Text(
                'Répartition par Race',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: data.byBreed.entries.map((entry) {
                      final color = Formatters.getBreedColor(entry.key);
                      final count = entry.value;
                      final total = data.totalActiveAnimals;
                      final percent = total > 0 ? (count / total * 100).toStringAsFixed(0) : '0';

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                entry.key,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                            ),
                            Text(
                              '$count têtes ($percent%)',
                              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Sectors & Capacity
              const Text(
                'Occupation des Enclos & Secteurs',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 10),
              ...data.sectors.map((sec) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                sec.sectorName,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: sec.isOvercrowded
                                      ? AppColors.danger.withOpacity(0.15)
                                      : AppColors.success.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  sec.isOvercrowded ? 'Surcharge' : 'Normal',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: sec.isOvercrowded ? AppColors.danger : AppColors.success,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: sec.capacity > 0 ? (sec.occupancy / sec.capacity).clamp(0.0, 1.0) : 0,
                            backgroundColor: AppColors.divider,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              sec.isOvercrowded ? AppColors.danger : AppColors.primary,
                            ),
                            borderRadius: BorderRadius.circular(4),
                            minHeight: 8,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${sec.occupancy} animaux / ${sec.capacity} places estimées',
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: color.withOpacity(0.12),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
