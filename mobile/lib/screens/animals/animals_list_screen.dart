import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/formatters.dart';
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
      appBar: AppBar(
        title: const Text('Cheptel Ovin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(animalsListProvider);
              ref.invalidate(breedsProvider);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter un ovin'),
        onPressed: () => context.push('/animals/add'),
      ),
      body: Column(
        children: [
          // Search & Filter header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Rechercher par nom, ID (ex: NK-2026-01) ou boucle...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: filter.searchQuery != null && filter.searchQuery!.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              ref.read(animalsFilterProvider.notifier).setFilter(
                                  filter.copyWith(searchQuery: ''));
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  onChanged: (val) {
                    ref.read(animalsFilterProvider.notifier).setFilter(
                        filter.copyWith(searchQuery: val.trim()));
                  },
                ),
                const SizedBox(height: 10),

                // Breed Filter Chips
                breedsAsync.when(
                  data: (breeds) => SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          label: const Text('Toutes les races'),
                          selected: filter.breedId == null,
                          onSelected: (_) {
                            ref.read(animalsFilterProvider.notifier).setFilter(
                                filter.copyWith(clearBreed: true));
                          },
                        ),
                        const SizedBox(width: 8),
                        ...breeds.map(
                          (b) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(b.name),
                              selected: filter.breedId == b.id,
                              selectedColor: Formatters.getBreedColor(b.name).withOpacity(0.2),
                              onSelected: (selected) {
                                ref.read(animalsFilterProvider.notifier).setFilter(
                                    filter.copyWith(breedId: selected ? b.id : null, clearBreed: !selected));
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  loading: () => const SizedBox(height: 32),
                  error: (e, st) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Animals List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.refresh(animalsListProvider),
              child: animalsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 40, color: AppColors.danger),
                      const SizedBox(height: 8),
                      Text('Erreur de chargement : $err'),
                      ElevatedButton(
                        onPressed: () => ref.refresh(animalsListProvider),
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
                data: (animals) {
                  if (animals.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.pets, size: 60, color: AppColors.textMuted.withOpacity(0.5)),
                          const SizedBox(height: 12),
                          const Text(
                            'Aucun ovin trouvé',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Ajoutez une brebis ou un bélier avec le bouton ci-dessous.',
                            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
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

  Widget _buildAnimalCard(BuildContext context, Animal animal) {
    final breedName = animal.breed?.name ?? 'Race inconnue';
    final breedColor = Formatters.getBreedColor(breedName);
    final sectorName = animal.currentSector?.name ?? 'Non assigné';

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/animals/${animal.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo / Avatar with sex icon
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: breedColor.withOpacity(0.15),
                    child: Text(
                      animal.name.isNotEmpty ? animal.name[0].toUpperCase() : 'O',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: breedColor,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: animal.isFemale ? Colors.pink : Colors.blueAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Icon(
                      animal.isFemale ? Icons.female : Icons.male,
                      size: 13,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),

              // Info column
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
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Text(
                            animal.id,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Breed & Sector
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: breedColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            breedName,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: breedColor),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            sectorName,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Metrics: Weight & Condition & Repro
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (animal.currentWeightKg != null)
                          _buildSmallBadge(
                            icon: Icons.scale_outlined,
                            label: '${animal.currentWeightKg} kg',
                            color: AppColors.primaryLight,
                          ),
                        _buildSmallBadge(
                          icon: Icons.monitor_heart_outlined,
                          label: Formatters.translateCondition(animal.bodyCondition),
                          color: Formatters.getConditionColor(animal.bodyCondition),
                        ),
                        if (animal.isFemale && animal.reproductionStatus != 'not_pregnant')
                          _buildSmallBadge(
                            icon: Icons.favorite,
                            label: Formatters.translateReproStatus(animal.reproductionStatus),
                            color: AppColors.secondary,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmallBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
