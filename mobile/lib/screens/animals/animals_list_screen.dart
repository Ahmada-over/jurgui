import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';
import '../../core/widgets/animal_photo_avatar.dart';
import '../../core/widgets/error_retry_card.dart';
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
          'Enregistrer un ovin',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        onPressed: () => context.push('/animals/add'),
      ),
      body: Column(
        children: [
          // Recherche & Filtres
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

                // Filtres par race
                breedsAsync.when(
                  data: (breeds) => SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildFilterPill(
                          label: 'Tout le cheptel',
                          isSelected: filter.breedId == null,
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

          // Liste des ovins
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async => ref.refresh(animalsListProvider),
              child: animalsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                ),
                error: (err, _) => ErrorRetryCard(
                  message: 'Impossible de charger le cheptel : $err',
                  onRetry: () => ref.refresh(animalsListProvider),
                ),
                data: (animals) {
                  if (animals.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: const BoxDecoration(
                                color: AppColors.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: const SheepHoofIcon(
                                size: 48,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Aucun ovin enregistré',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Commencez par ajouter votre premier ovin au registre.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 18),
                            ElevatedButton.icon(
                              onPressed: () => context.push('/animals/add'),
                              icon: const Icon(LucideIcons.plus, size: 18),
                              label: const Text('Enregistrer un ovin'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                    itemCount: animals.length,
                    itemBuilder: (context, index) {
                      final animal = animals[index];
                      return _buildAnimalCard(context, animal);
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
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  /// Carte ovin : Photo -> Nom en grand -> Boucle -> Poids
  Widget _buildAnimalCard(BuildContext context, Animal animal) {
    final breedName = animal.breed?.name ?? 'Race non précisée';
    final sectorName = animal.currentSector?.name ?? 'Sans enclos';
    final isLadoum =
        breedName.toLowerCase().contains('ladoum') &&
        !breedName.toLowerCase().contains('métis');
    final tagLabel =
        animal.physicalTag != null && animal.physicalTag!.isNotEmpty
            ? 'Boucle : ${animal.physicalTag} (${animal.id})'
            : 'Boucle / ID : ${animal.id}';
    final weightLabel = animal.currentWeightKg != null
        ? '${animal.currentWeightKg!.toStringAsFixed(1)} kg'
        : 'Non pesé';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.divider,
          width: 1,
        ),
        boxShadow: AppColors.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => context.push('/animals/${animal.id}'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Photo de l'ovin
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isLadoum
                        ? AppColors.goldLight
                        : AppColors.primaryContainer,
                    border: Border.all(
                      color: isLadoum
                          ? AppColors.gold.withValues(alpha: 0.6)
                          : AppColors.primary.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: AnimalPhotoImage(
                    photoUrl: animal.photoUrl,
                    size: 64,
                    fallback: Center(
                      child: Text(
                        animal.name.isNotEmpty
                            ? animal.name[0].toUpperCase()
                            : 'O',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // 2. Nom en grand, boucle, puis poids
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nom en grand
                      Text(
                        animal.name,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),

                      // Boucle / Identifiant
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.tag,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              tagLabel,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Poids mis en avant + Race & Enclos
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  LucideIcons.scale,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  weightLabel,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isLadoum
                                  ? AppColors.goldLight
                                  : AppColors.background,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              breedName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (animal.lineage != null &&
                              animal.lineage!.trim().isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.goldLight,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.gold.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    LucideIcons.dna,
                                    size: 13,
                                    color: AppColors.goldDark,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    animal.lineage!,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.goldDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Text(
                            sectorName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
