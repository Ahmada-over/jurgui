import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/sheep_hoof_icon.dart';
import '../../models/animal.dart';
import '../../providers/animals_provider.dart';

class AnimalsListScreen extends ConsumerWidget {
  const AnimalsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final animalsAsync = ref.watch(animalsListProvider);
    final breedsAsync = ref.watch(breedsProvider);
    final filter = ref.watch(animalsFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cheptel Ovin'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(LucideIcons.plus),
        label: const Text(
          'Ajouter un ovin',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.2),
        ),
        onPressed: () => context.push('/animals/add'),
      ),
      body: Column(
        children: [
          // Sleek 2026 Search & Filter Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.divider),
                    boxShadow: AppColors.softShadow,
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Rechercher (Nom, NK-..., boucle)...',
                      prefixIcon: const Icon(
                        LucideIcons.search,
                        color: AppColors.textSecondary,
                      ),
                      suffixIcon:
                          filter.searchQuery != null &&
                              filter.searchQuery!.isNotEmpty
                          ? IconButton(
                              icon: const Icon(LucideIcons.x, size: 18),
                              onPressed: () {
                                ref
                                    .read(animalsFilterProvider.notifier)
                                    .setFilter(
                                      filter.copyWith(searchQuery: ''),
                                    );
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    onChanged: (val) {
                      ref
                          .read(animalsFilterProvider.notifier)
                          .setFilter(filter.copyWith(searchQuery: val.trim()));
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Breed Selector Pills
                breedsAsync.when(
                  data: (breeds) => SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildFilterPill(
                          label: 'Tout le cheptel',
                          isSelected: filter.breedId == null,
                          color: AppColors.primary,
                          onTap: () {
                            ref
                                .read(animalsFilterProvider.notifier)
                                .setFilter(filter.copyWith(clearBreed: true));
                          },
                        ),
                        const SizedBox(width: 8),
                        ...breeds.map(
                          (b) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _buildFilterPill(
                              label: b.name,
                              isSelected: filter.breedId == b.id,
                              color: Formatters.getBreedColor(b.name),
                              onTap: () {
                                ref
                                    .read(animalsFilterProvider.notifier)
                                    .setFilter(
                                      filter.copyWith(
                                        breedId: filter.breedId == b.id
                                            ? null
                                            : b.id,
                                        clearBreed: filter.breedId == b.id,
                                      ),
                                    );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  loading: () => const SizedBox(height: 36),
                  error: (e, st) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          // Animals List
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primaryAccent,
              onRefresh: () async => ref.refresh(animalsListProvider),
              child: animalsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryAccent,
                  ),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          LucideIcons.circleAlert,
                          size: 44,
                          color: AppColors.danger,
                        ),
                        const SizedBox(height: 10),
                        Text('Erreur: $err'),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => ref.refresh(animalsListProvider),
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (animals) {
                  if (animals.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer.withValues(
                                alpha: 0.5,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const SheepHoofIcon(
                              size: 54,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Aucun ovin trouvé',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Ajoutez une tête au cheptel via le bouton flottant.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                    itemCount: animals.length,
                    itemBuilder: (context, index) {
                      final animal = animals[index];
                      return _build2026AnimalCard(context, animal);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : AppColors.divider,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected ? AppColors.softShadow : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _build2026AnimalCard(BuildContext context, Animal animal) {
    final breedName = animal.breed?.name ?? 'Race inconnue';
    final breedColor = Formatters.getBreedColor(breedName);
    final sectorName = animal.currentSector?.name ?? 'Enclos non défini';
    final isLadoum =
        breedName.toLowerCase().contains('ladoum') &&
        !breedName.toLowerCase().contains('métis');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isLadoum
              ? AppColors.gold.withValues(alpha: 0.35)
              : AppColors.divider,
          width: isLadoum ? 1.2 : 0.8,
        ),
        boxShadow: AppColors.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => context.push('/animals/${animal.id}'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar with luxury prestige ring
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isLadoum ? AppColors.goldGradient : null,
                    color: !isLadoum ? breedColor.withValues(alpha: 0.2) : null,
                  ),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: breedColor.withValues(alpha: 0.14),
                      child: Text(
                        animal.name.isNotEmpty
                            ? animal.name[0].toUpperCase()
                            : 'O',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: breedColor,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              animal.name,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  LucideIcons.tag,
                                  size: 12,
                                  color: AppColors.textSecondary,
                                ),
                                Text(
                                  animal.id,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Breed & Sector
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: breedColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              breedName,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: breedColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              sectorName,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Metrics pills row
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (animal.currentWeightKg != null)
                            _buildPillMetric(
                              icon: LucideIcons.scale,
                              label: '${animal.currentWeightKg} kg',
                              color: AppColors.primary,
                            ),
                          _buildPillMetric(
                            icon: LucideIcons.circle,
                            iconSize: 7,
                            label: Formatters.translateCondition(
                              animal.bodyCondition,
                            ),
                            color: Formatters.getConditionColor(
                              animal.bodyCondition,
                            ),
                          ),
                          if (animal.isFemale &&
                              animal.reproductionStatus != 'not_pregnant')
                            _buildPillMetric(
                              icon: LucideIcons.heart,
                              label: Formatters.translateReproStatus(
                                animal.reproductionStatus,
                              ),
                              color: AppColors.goldDark,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(
                  LucideIcons.chevronRight,
                  size: 14,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPillMetric({
    required IconData icon,
    required String label,
    required Color color,
    double iconSize = 13,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
