import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/animal_photo_avatar.dart';
import '../../core/widgets/error_retry_card.dart';
import '../../models/animal.dart';
import '../../providers/animals_provider.dart';

class AnimalDetailScreen extends ConsumerStatefulWidget {
  final String animalId;

  const AnimalDetailScreen({super.key, required this.animalId});

  @override
  ConsumerState<AnimalDetailScreen> createState() => _AnimalDetailScreenState();
}

class _AnimalDetailScreenState extends ConsumerState<AnimalDetailScreen> {
  Animal? _optimisticAnimal;

  void _applyOptimisticAnimal(Animal updated) {
    if (mounted) {
      setState(() => _optimisticAnimal = updated);
    }
    ref.read(animalsListProvider.notifier).upsertAnimal(updated);
  }

  void _showAddWeightDialog(Animal animal) {
    final weightController = TextEditingController(
      text: animal.currentWeightKg != null
          ? animal.currentWeightKg!.toStringAsFixed(1)
          : '',
    );
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                LucideIcons.scale,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nouvelle pesée',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    animal.name,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: weightController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'Poids corporel (kg) *',
                suffixText: 'kg',
                suffixStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                prefixIcon: const Icon(LucideIcons.scale),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: notesController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Observations (optionnel)',
                hintText: 'ex: Contrôle mensuel, alimentation concentrée...',
                prefixIcon: const Icon(LucideIcons.filePenLine),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Annuler',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () async {
              final w = double.tryParse(
                weightController.text.replaceAll(',', '.'),
              );
              if (w == null || w <= 0) return;
              final notesText = notesController.text.trim();
              Navigator.pop(ctx);

              // Mise à jour instantanée (0ms) de l'interface
              final optimisticRecord = WeightRecord(
                id: DateTime.now().millisecondsSinceEpoch,
                animalId: animal.id,
                weightKg: w,
                recordedAt: DateTime.now(),
                notes: notesText.isEmpty ? null : notesText,
              );
              final optimistic = animal.copyWith(
                currentWeightKg: w,
                weightRecords: [...animal.weightRecords, optimisticRecord],
              );
              _applyOptimisticAnimal(optimistic);

              try {
                final savedRecord = await ref
                    .read(animalActionsServiceProvider)
                    .addWeight(animal.id, w, notesText);
                final confirmed = animal.copyWith(
                  currentWeightKg: w,
                  weightRecords: [...animal.weightRecords, savedRecord],
                );
                _applyOptimisticAnimal(confirmed);
                ref.invalidate(animalDetailProvider(animal.id));
              } catch (e) {
                _applyOptimisticAnimal(animal);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur : $e'),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Enregistrer la pesée',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showMoveSectorDialog(Animal animal) {
    final sectorsAsync = ref.read(sectorsProvider);
    int? selectedSectorId = animal.currentSectorId;
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.doorOpen,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Déplacer d\'enclos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      animal.name,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              sectorsAsync.when(
                data: (sectors) => DropdownButtonFormField<int>(
                  initialValue: selectedSectorId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Enclos de destination',
                    prefixIcon: const Icon(LucideIcons.fence),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  items: sectors.map((s) {
                    final isFull = s.currentOccupancy >= s.estimatedCapacity;
                    return DropdownMenuItem<int>(
                      value: s.id,
                      child: Text(
                        '${s.name} (${s.currentOccupancy}/${s.estimatedCapacity})${isFull ? " [Plein]" : ""}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: s.id == animal.currentSectorId
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isFull
                              ? AppColors.danger
                              : AppColors.textPrimary,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setDialogState(() => selectedSectorId = val);
                  },
                ),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ),
                error: (e, _) => Text('Erreur: $e'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  labelText: 'Motif du mouvement',
                  hintText: 'ex: Lot de saillie, isolement soins...',
                  prefixIcon: const Icon(LucideIcons.info),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Annuler',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onPressed: selectedSectorId == null
                  ? null
                  : () async {
                      final targetSectorId = selectedSectorId!;
                      final reason = reasonController.text.trim().isEmpty
                          ? 'Déplacement de routine'
                          : reasonController.text.trim();
                      Navigator.pop(ctx);

                      // Mise à jour instantanée (0ms) de l'interface
                      final sectorsList = sectorsAsync.value;
                      final targetSector = sectorsList
                          ?.where((s) => s.id == targetSectorId)
                          .firstOrNull;
                      final optimisticMove = AnimalMovement(
                        id: DateTime.now().millisecondsSinceEpoch,
                        animalId: animal.id,
                        fromSectorId: animal.currentSectorId,
                        toSectorId: targetSectorId,
                        movementDate: DateTime.now(),
                        reason: reason,
                      );
                      final optimistic = animal.copyWith(
                        currentSectorId: targetSectorId,
                        currentSector: targetSector ?? animal.currentSector,
                        movements: [optimisticMove, ...animal.movements],
                      );
                      _applyOptimisticAnimal(optimistic);

                      try {
                        final savedMove = await ref
                            .read(animalActionsServiceProvider)
                            .moveAnimalSector(
                              animal.id,
                              targetSectorId,
                              reason,
                            );
                        final confirmed = optimistic.copyWith(
                          movements: [savedMove, ...animal.movements],
                        );
                        _applyOptimisticAnimal(confirmed);
                        ref.invalidate(animalDetailProvider(animal.id));
                        ref.invalidate(sectorsProvider);
                      } catch (e) {
                        _applyOptimisticAnimal(animal);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Erreur : $e'),
                              backgroundColor: AppColors.danger,
                            ),
                          );
                        }
                      }
                    },
              child: const Text(
                'Confirmer le transfert',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatIsoDate(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  void _showEditAnimalSheet(Animal animal) {
    final nameController = TextEditingController(text: animal.name);
    final tagController = TextEditingController(text: animal.physicalTag ?? '');
    final priceController = TextEditingController(
      text: animal.purchasePriceCfa != null
          ? animal.purchasePriceCfa!.toStringAsFixed(0)
          : '',
    );
    final fatherController = TextEditingController(text: animal.fatherId ?? '');
    final motherController = TextEditingController(text: animal.motherId ?? '');
    final lineageController = TextEditingController(text: animal.lineage ?? '');
    final notesController = TextEditingController(text: animal.notes ?? '');

    int selectedBreedId = animal.breedId;
    String selectedSex = animal.sex.toLowerCase();
    String selectedOrigin = animal.origin;
    String selectedCondition = animal.bodyCondition;
    String selectedStatus = animal.status;
    DateTime? selectedBirthDate = animal.birthDate;
    String? currentPhotoUrl = animal.photoUrl;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final breedsAsync = ref.watch(breedsProvider);

          Future<void> pickBirthDate() async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: ctx,
              initialDate: selectedBirthDate ?? now,
              firstDate: DateTime(now.year - 15),
              lastDate: now,
              helpText: 'Date de naissance de l\'ovin',
              cancelText: 'Annuler',
              confirmText: 'Valider',
            );
            if (picked != null) {
              setSheetState(() => selectedBirthDate = picked);
            }
          }

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.88,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 14,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        LucideIcons.pencil,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Modifier la fiche de l\'ovin',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'ID: ${animal.id}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(LucideIcons.x, size: 20),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: GestureDetector(
                            onTap: () async {
                              final res = await showAnimalPhotoPickerSheet(
                                ctx,
                                hasCurrentPhoto:
                                    currentPhotoUrl != null &&
                                    currentPhotoUrl!.isNotEmpty,
                              );
                              if (res == null) return;
                              if (res.removed) {
                                setSheetState(() => currentPhotoUrl = null);
                              } else if (res.dataUrl != null) {
                                setSheetState(
                                  () => currentPhotoUrl = res.dataUrl,
                                );
                              }
                            },
                            child: Column(
                              children: [
                                Stack(
                                  children: [
                                    Container(
                                      width: 84,
                                      height: 84,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.primaryContainer,
                                        border: Border.all(
                                          color: AppColors.primary.withValues(
                                            alpha: 0.25,
                                          ),
                                          width: 2,
                                        ),
                                      ),
                                      child: AnimalPhotoImage(
                                        photoUrl: currentPhotoUrl,
                                        size: 84,
                                        fallback: const Center(
                                          child: Icon(
                                            LucideIcons.camera,
                                            size: 28,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                        child: const Icon(
                                          LucideIcons.camera,
                                          size: 13,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  currentPhotoUrl != null &&
                                          currentPhotoUrl!.isNotEmpty
                                      ? 'Changer ou supprimer la photo'
                                      : 'Ajouter une photo de l\'ovin',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nom de l\'animal *',
                            prefixIcon: Icon(LucideIcons.badgeCheck),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: tagController,
                          decoration: const InputDecoration(
                            labelText: 'Numéro de boucle / tag physique',
                            prefixIcon: Icon(LucideIcons.tag),
                          ),
                        ),
                        const SizedBox(height: 12),
                        breedsAsync.when(
                          data: (breeds) => DropdownButtonFormField<int>(
                            initialValue:
                                breeds.any((b) => b.id == selectedBreedId)
                                ? selectedBreedId
                                : null,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Race ovine',
                              prefixIcon: Icon(LucideIcons.folders),
                            ),
                            items: breeds
                                .map(
                                  (b) => DropdownMenuItem<int>(
                                    value: b.id,
                                    child: Text(
                                      b.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setSheetState(() => selectedBreedId = val);
                              }
                            },
                          ),
                          loading: () => const LinearProgressIndicator(),
                          error: (e, _) => Text('Erreur: $e'),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: selectedSex,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Sexe',
                                  prefixIcon: Icon(
                                    LucideIcons.venusAndMars,
                                    size: 18,
                                  ),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'female',
                                    child: Text(
                                      'Brebis',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'male',
                                    child: Text(
                                      'Bélier',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setSheetState(() => selectedSex = val);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: selectedCondition,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'État corporel',
                                  prefixIcon: Icon(
                                    LucideIcons.heartPulse,
                                    size: 18,
                                  ),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'normal',
                                    child: Text(
                                      'Normal',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'thin',
                                    child: Text(
                                      'Maigre',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'fat',
                                    child: Text(
                                      'Gras',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setSheetState(
                                      () => selectedCondition = val,
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: pickBirthDate,
                          borderRadius: BorderRadius.circular(12),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Date de naissance (optionnel)',
                              prefixIcon: const Icon(LucideIcons.calendarDays),
                              suffixIcon: selectedBirthDate != null
                                  ? IconButton(
                                      icon: const Icon(LucideIcons.x, size: 18),
                                      tooltip: 'Effacer la date',
                                      onPressed: () => setSheetState(
                                        () => selectedBirthDate = null,
                                      ),
                                    )
                                  : const Icon(
                                      LucideIcons.chevronDown,
                                      size: 18,
                                    ),
                            ),
                            child: Text(
                              selectedBirthDate != null
                                  ? Formatters.formatDate(selectedBirthDate)
                                  : 'Non renseignée (cliquer pour choisir)',
                              style: TextStyle(
                                color: selectedBirthDate != null
                                    ? AppColors.textPrimary
                                    : AppColors.textMuted,
                                fontWeight: selectedBirthDate != null
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: selectedOrigin,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Origine',
                                  prefixIcon: Icon(
                                    LucideIcons.compass,
                                    size: 18,
                                  ),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'birth',
                                    child: Text(
                                      'Né à la ferme',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'purchase',
                                    child: Text(
                                      'Achat extérieur',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setSheetState(() => selectedOrigin = val);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: selectedStatus,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Statut',
                                  prefixIcon: Icon(
                                    LucideIcons.activity,
                                    size: 18,
                                  ),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'active',
                                    child: Text(
                                      'Actif',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'sold',
                                    child: Text(
                                      'Vendu',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'deceased',
                                    child: Text(
                                      'Décédé',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'transferred',
                                    child: Text(
                                      'Transféré',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setSheetState(() => selectedStatus = val);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: priceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Prix d\'acquisition (FCFA)',
                            suffixText: 'FCFA',
                            prefixIcon: Icon(LucideIcons.banknote),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: lineageController,
                          decoration: const InputDecoration(
                            labelText: 'Lignée / Sang (ex: Lignée Serigne)',
                            prefixIcon: Icon(LucideIcons.dna),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: fatherController,
                                decoration: const InputDecoration(
                                  labelText: 'ID Père (Bélier)',
                                  prefixIcon: Icon(LucideIcons.mars),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: motherController,
                                decoration: const InputDecoration(
                                  labelText: 'ID Mère (Brebis)',
                                  prefixIcon: Icon(LucideIcons.venus),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: notesController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Notes de suivi',
                            prefixIcon: Icon(LucideIcons.filePenLine),
                          ),
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: isSaving
                              ? null
                              : () async {
                                  if (nameController.text.trim().isEmpty) {
                                    return;
                                  }
                                  setSheetState(() => isSaving = true);
                                  try {
                                    final payload = <String, dynamic>{
                                      'name': nameController.text.trim(),
                                      'physical_tag':
                                          tagController.text.trim().isEmpty
                                          ? null
                                          : tagController.text.trim(),
                                      'photo_url': currentPhotoUrl,
                                      'breed_id': selectedBreedId,
                                      'sex': selectedSex,
                                      'birth_date': selectedBirthDate != null
                                          ? _formatIsoDate(selectedBirthDate!)
                                          : null,
                                      'origin': selectedOrigin,
                                      'body_condition': selectedCondition,
                                      'status': selectedStatus,
                                      'purchase_price_cfa': double.tryParse(
                                        priceController.text.replaceAll(
                                          ',',
                                          '.',
                                        ),
                                      ),
                                      'father_id':
                                          fatherController.text.trim().isEmpty
                                          ? null
                                          : fatherController.text.trim(),
                                      'mother_id':
                                          motherController.text.trim().isEmpty
                                          ? null
                                          : motherController.text.trim(),
                                      'lineage':
                                          lineageController.text.trim().isEmpty
                                          ? null
                                          : lineageController.text.trim(),
                                      'notes':
                                          notesController.text.trim().isEmpty
                                          ? null
                                          : notesController.text.trim(),
                                    };
                                    final updated = await ref
                                        .read(animalActionsServiceProvider)
                                        .updateAnimal(animal.id, payload);
                                    final merged = updated.copyWith(
                                      weightRecords: animal.weightRecords,
                                      movements: animal.movements,
                                    );
                                    _applyOptimisticAnimal(merged);
                                    ref.invalidate(
                                      animalDetailProvider(animal.id),
                                    );
                                    ref.invalidate(
                                      animalGenealogyProvider(animal.id),
                                    );
                                    if (ctx.mounted) Navigator.pop(ctx);
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Fiche ovin mise à jour avec succès',
                                          ),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    setSheetState(() => isSaving = false);
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('Erreur : $e'),
                                          backgroundColor: AppColors.danger,
                                        ),
                                      );
                                    }
                                  }
                                },
                          icon: isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(LucideIcons.check, size: 18),
                          label: const Text(
                            'Enregistrer les modifications',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final animalAsync = ref.watch(animalDetailProvider(widget.animalId));
    final activeAnimal = _optimisticAnimal ?? animalAsync.value;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        title: Text(
          widget.animalId,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          if (activeAnimal != null) ...[
            IconButton(
              icon: const Icon(LucideIcons.share2, color: Colors.white),
              tooltip: 'Partager la lignée aux éleveurs',
              onPressed: () => _showSharePedigreeSheet(activeAnimal),
            ),
            IconButton(
              icon: const Icon(LucideIcons.pencil, color: Colors.white),
              tooltip: 'Modifier la fiche',
              onPressed: () => _showEditAnimalSheet(activeAnimal),
            ),
          ],
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, color: Colors.white),
            onPressed: () {
              setState(() => _optimisticAnimal = null);
              ref.invalidate(animalDetailProvider(widget.animalId));
              ref.invalidate(animalGenealogyProvider(widget.animalId));
            },
          ),
        ],
      ),
      body: animalAsync.when(
        loading: () => _optimisticAnimal != null
            ? _buildDetailBody(_optimisticAnimal!)
            : const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryAccent,
                ),
              ),
        error: (err, _) => _optimisticAnimal != null
            ? _buildDetailBody(_optimisticAnimal!)
            : ErrorRetryCard(
                message: 'Impossible de charger la fiche : $err',
                onRetry: () =>
                    ref.refresh(animalDetailProvider(widget.animalId)),
              ),
        data: (fetchedAnimal) {
          final animal = _optimisticAnimal ?? fetchedAnimal;
          return _buildDetailBody(animal);
        },
      ),
    );
  }

  Widget _buildDetailBody(Animal animal) {
    final breedName = animal.breed?.name ?? 'Race inconnue';
    final isLadoum =
        breedName.toLowerCase().contains('ladoum') &&
        !breedName.toLowerCase().contains('métis');

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
          children: [
            // 1. CARTE D'IDENTITÉ DE L'OVIN : Photo -> Nom en grand -> Boucle -> Poids
            _buildIdentityHeroCard(
              animal,
              breedName,
              isLadoum,
            ),
            const SizedBox(height: 22),

            // 2. SECTION EN DESSOUS : Courbe, Généalogie, Caractéristiques, Historique d'enclos
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 10),
              child: Text(
                'Suivi & Historique',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ),

            // Courbe de croissance
            _buildWeightGrowthChart(animal),
            const SizedBox(height: 16),

            // Généalogie
            _buildPedigreeLineageCard(animal),
            const SizedBox(height: 16),

            // Caractéristiques & Santé
            _buildCharacteristicsCard(animal),
            const SizedBox(height: 16),

            // Historique des enclos
            _buildSectorMovementsTimeline(animal),
          ],
        ),

        // FLOATING ACTIONS BAR AT BOTTOM
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: _buildBottomActionBar(animal),
        ),
      ],
    );
  }

  // --- CARTE D'IDENTITÉ : Photo, Nom en grand, Boucle, puis Poids ---
  Widget _buildIdentityHeroCard(
    Animal animal,
    String breedName,
    bool isLadoum,
  ) {
    final weightValue = animal.currentWeightKg != null
        ? '${animal.currentWeightKg!.toStringAsFixed(1)} kg'
        : 'Non pesé';
    final sectorValue = animal.currentSector?.name ?? 'Non assigné';
    final ageValue = animal.birthDate != null
        ? '${DateTime.now().difference(animal.birthDate!).inDays ~/ 30} mois'
        : (animal.estimatedAgeMonths != null
              ? '${animal.estimatedAgeMonths} mois'
              : 'Non précisé');
    final tagText =
        animal.physicalTag != null && animal.physicalTag!.isNotEmpty
            ? 'Boucle : ${animal.physicalTag} • ID : ${animal.id}'
            : 'Boucle / ID : ${animal.id}';

    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.softShadow,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Photo de l'ovin (grande et reconnaissable)
              GestureDetector(
                onTap: () async {
                  final res = await showAnimalPhotoPickerSheet(
                    context,
                    hasCurrentPhoto:
                        animal.photoUrl != null && animal.photoUrl!.isNotEmpty,
                  );
                  if (res == null) return;
                  final newPhoto = res.removed ? null : res.dataUrl;
                  final optimistic = animal.copyWith(
                    photoUrl: newPhoto,
                    clearPhotoUrl: res.removed,
                  );
                  _applyOptimisticAnimal(optimistic);
                  try {
                    final updated = await ref
                        .read(animalActionsServiceProvider)
                        .updateAnimal(animal.id, {'photo_url': newPhoto});
                    _applyOptimisticAnimal(
                      updated.copyWith(
                        weightRecords: animal.weightRecords,
                        movements: animal.movements,
                      ),
                    );
                    ref.invalidate(animalDetailProvider(animal.id));
                  } catch (e) {
                    _applyOptimisticAnimal(animal);
                  }
                },
                child: Stack(
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isLadoum
                            ? AppColors.goldLight
                            : Colors.white.withValues(alpha: 0.2),
                      ),
                      padding: const EdgeInsets.all(3),
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF092920),
                        ),
                        child: AnimalPhotoImage(
                          photoUrl: animal.photoUrl,
                          size: 78,
                          fallback: Center(
                            child: Text(
                              animal.name.isNotEmpty
                                  ? animal.name.characters.first.toUpperCase()
                                  : 'O',
                              style: const TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          LucideIcons.camera,
                          size: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // 2. Nom en grand, puis Boucle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      animal.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tagText,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _buildIdentityTag(
                          label: breedName,
                          isChampagne: isLadoum,
                        ),
                        _buildIdentityTag(
                          label: animal.isFemale ? 'Brebis' : 'Bélier',
                          isChampagne: false,
                        ),
                        if (animal.lineage != null &&
                            animal.lineage!.trim().isNotEmpty)
                          _buildIdentityTag(
                            label: 'Lignée : ${animal.lineage}',
                            isChampagne: true,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 3. Poids mis en avant (suivi de l'enclos et de l'âge)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildIdentityMetric(
                    label: 'Poids actuel',
                    value: weightValue,
                    highlight: true,
                  ),
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: AppColors.divider,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: _buildIdentityMetric(
                      label: 'Enclos',
                      value: sectorValue,
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: AppColors.divider,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: _buildIdentityMetric(
                      label: 'Âge',
                      value: ageValue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentityTag({
    required String label,
    required bool isChampagne,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isChampagne
            ? AppColors.goldLight
            : Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: isChampagne ? AppColors.textPrimary : Colors.white,
        ),
      ),
    );
  }

  Widget _buildIdentityMetric({
    required String label,
    required String value,
    bool highlight = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: highlight ? 17 : 15,
            fontWeight: FontWeight.w700,
            color: highlight ? AppColors.primary : AppColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // --- FL_CHART WEIGHT GROWTH CURVE ---
  Widget _buildWeightGrowthChart(Animal animal) {
    final records = [...animal.weightRecords]
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      LucideIcons.chartNoAxesColumnIncreasing,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Courbe de Croissance',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => _showAddWeightDialog(animal),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.plus,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Nouvelle pesée',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (records.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(
                    LucideIcons.scale,
                    size: 36,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Aucune pesée enregistrée pour cet animal.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    icon: const Icon(LucideIcons.plus, size: 16),
                    label: const Text(
                      'Enregistrer la première pesée',
                      style: TextStyle(fontSize: 13),
                    ),
                    onPressed: () => _showAddWeightDialog(animal),
                  ),
                ],
              ),
            )
          else ...[
            // Growth Stats Row
            Row(
              children: [
                _buildGrowthStatChip(
                  'Initiale',
                  '${records.first.weightKg.toStringAsFixed(1)} kg',
                ),
                const SizedBox(width: 12),
                _buildGrowthStatChip(
                  'Dernière',
                  '${records.last.weightKg.toStringAsFixed(1)} kg',
                ),
                const SizedBox(width: 12),
                _buildGrowthStatChip(
                  'Gain total',
                  '${(records.last.weightKg - records.first.weightKg) >= 0 ? "+" : ""}${(records.last.weightKg - records.first.weightKg).toStringAsFixed(1)} kg',
                  isHighlighted: true,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // FlChart LineChart
            SizedBox(
              height: 190,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 10,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: AppColors.divider,
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                        getTitlesWidget: (val, meta) => Text(
                          '${val.toInt()}k',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: (records.length > 4
                            ? (records.length / 3).floorToDouble()
                            : 1),
                        getTitlesWidget: (val, meta) {
                          final idx = val.toInt();
                          if (idx >= 0 && idx < records.length) {
                            final d = records[idx].recordedAt;
                            return Text(
                              '${d.day}/${d.month}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minY:
                      ((records
                                      .map((r) => r.weightKg)
                                      .reduce((a, b) => a < b ? a : b) -
                                  5) /
                              10)
                          .floor() *
                      10,
                  maxY:
                      ((records
                                      .map((r) => r.weightKg)
                                      .reduce((a, b) => a > b ? a : b) +
                                  5) /
                              10)
                          .ceil() *
                      10,
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (int i = 0; i < records.length; i++)
                          FlSpot(i.toDouble(), records[i].weightKg),
                      ],
                      isCurved: true,
                      curveSmoothness: 0.35,
                      color: AppColors.primary,
                      barWidth: 3.5,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) =>
                            FlDotCirclePainter(
                              radius: 4.5,
                              color: AppColors.primary,
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.primary.withValues(alpha: 0.2),
                            AppColors.primary.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGrowthStatChip(
    String title,
    String value, {
    bool isHighlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isHighlighted
            ? AppColors.primaryContainer
            : AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isHighlighted
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isHighlighted ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // --- PEDIGREE & LINEAGE CARD ---
  String _buildPublicPedigreeUrl(String animalId) {
    final base = ApiEndpoints.baseUrl.replaceAll(RegExp(r'/api/v1/?$'), '');
    return '$base/pedigree/${Uri.encodeComponent(animalId)}';
  }

  String _formatAgeDetail(Animal animal) {
    if (animal.birthDate != null) {
      final months =
          DateTime.now().difference(animal.birthDate!).inDays ~/ 30;
      if (months >= 12) {
        final years = months ~/ 12;
        final rem = months % 12;
        return '$years an${years > 1 ? "s" : ""}${rem > 0 ? " $rem mois" : ""}';
      }
      return '$months mois';
    }
    if (animal.estimatedAgeMonths != null) {
      return '${animal.estimatedAgeMonths} mois (est.)';
    }
    return 'Non précisé';
  }

  String _buildPedigreeShareText(Animal animal, AnimalGenealogy? genealogy) {
    final breedName = animal.breed?.name ?? 'Race Ovine Sélectionnée';
    final sexLabel = animal.isFemale
        ? 'Brebis (Femelle)'
        : 'Bélier Géniteur (Mâle)';
    final lineageLabel =
        (animal.lineage != null && animal.lineage!.trim().isNotEmpty)
        ? animal.lineage!
        : 'Lignée Sélectionnée — Registre Jur-gui';
    final fatherLabel = genealogy?.father != null
        ? '${genealogy!.father!.name} (ID: ${genealogy.father!.id})'
        : (animal.fatherId != null && animal.fatherId!.isNotEmpty
              ? 'Réf. ${animal.fatherId!}'
              : 'Ascendant externe');
    final motherLabel = genealogy?.mother != null
        ? '${genealogy!.mother!.name} (ID: ${genealogy.mother!.id})'
        : (animal.motherId != null && animal.motherId!.isNotEmpty
              ? 'Réf. ${animal.motherId!}'
              : 'Ascendante externe');
    final pgfLabel = genealogy?.paternalGrandfather != null
        ? '${genealogy!.paternalGrandfather!.name} (${genealogy.paternalGrandfather!.id})'
        : '—';
    final pgmLabel = genealogy?.paternalGrandmother != null
        ? '${genealogy!.paternalGrandmother!.name} (${genealogy.paternalGrandmother!.id})'
        : '—';
    final mgfLabel = genealogy?.maternalGrandfather != null
        ? '${genealogy!.maternalGrandfather!.name} (${genealogy.maternalGrandfather!.id})'
        : '—';
    final mgmLabel = genealogy?.maternalGrandmother != null
        ? '${genealogy!.maternalGrandmother!.name} (${genealogy.maternalGrandmother!.id})'
        : '—';
    final weightLabel = animal.currentWeightKg != null
        ? '${animal.currentWeightKg!.toStringAsFixed(1)} kg'
        : 'Non communiqué';
    final birthLabel = animal.birthDate != null
        ? '${Formatters.formatDate(animal.birthDate)} (${_formatAgeDetail(animal)})'
        : _formatAgeDetail(animal);
    final tagLabel =
        animal.physicalTag != null && animal.physicalTag!.isNotEmpty
        ? animal.physicalTag!
        : 'Non bouclé';
    final originLabel = animal.origin == 'birth'
        ? 'Né à la bergerie (Sélection interne)'
        : 'Acquisition externe sélectionnée';
    final condLabel = Formatters.translateCondition(animal.bodyCondition);
    final reproLabel = Formatters.translateReproStatus(
      animal.reproductionStatus,
    );
    final certRef =
        'JG-DKR-${animal.id.toUpperCase()}-${DateTime.now().year}';
    final publicUrl = _buildPublicPedigreeUrl(animal.id);

    final buffer = StringBuffer()
      ..writeln('══════════════════════════════════')
      ..writeln('CERTIFICAT OFFICIEL DE LIGNÉE & PEDIGREE')
      ..writeln('LIVRE GÉNÉALOGIQUE OVIN — JUR-GUI DAKAR')
      ..writeln('Réf. Certificat : $certRef')
      ..writeln('══════════════════════════════════')
      ..writeln('')
      ..writeln('1. IDENTIFICATION & SIGNALEMENT ZOOTECHNIQUE')
      ..writeln('• Nom du sujet       : ${animal.name.toUpperCase()}')
      ..writeln('• N° Registre Interne : ${animal.id}')
      ..writeln('• Boucle Officielle  : $tagLabel')
      ..writeln('• Race & Standard    : $breedName')
      ..writeln('• Sexe               : $sexLabel')
      ..writeln('• Date de naissance  : $birthLabel')
      ..writeln('• Origine            : $originLabel')
      ..writeln('')
      ..writeln('2. LIGNÉE & ARBRE GÉNÉALOGIQUE (2 GÉNÉRATIONS)')
      ..writeln('• Lignée / Sang      : $lineageLabel')
      ..writeln('• Père (Géniteur)    : $fatherLabel')
      ..writeln('  ├─ Grand-Père Pat. : $pgfLabel')
      ..writeln('  └─ Grand-Mère Pat. : $pgmLabel')
      ..writeln('• Mère (Génitrice)   : $motherLabel')
      ..writeln('  ├─ Grand-Père Mat. : $mgfLabel')
      ..writeln('  └─ Grand-Mère Mat. : $mgmLabel')
      ..writeln('')
      ..writeln('3. PERFORMANCES & CONFORMATION')
      ..writeln('• Poids certifié     : $weightLabel')
      ..writeln('• État corporel      : $condLabel')
      ..writeln('• Statut reproducteur: $reproLabel');

    if (genealogy != null && genealogy.offspring.isNotEmpty) {
      buffer
        ..writeln('')
        ..writeln(
          '4. DESCENDANCE ENREGISTRÉE (${genealogy.offspring.length} sujet${genealogy.offspring.length > 1 ? "s" : ""})',
        );
      for (final o in genealogy.offspring) {
        final oSex = o.sex == 'female' ? '♀ Brebis' : '♂ Bélier';
        buffer.writeln('• ${o.name} (ID: ${o.id}) — $oSex');
      }
    }

    buffer
      ..writeln('')
      ..writeln('══════════════════════════════════')
      ..writeln('Certificat numérique vérifiable & imprimable (PDF) :')
      ..writeln(publicUrl);

    return buffer.toString();
  }

  void _showSharePedigreeSheet(Animal animal) {
    final genealogy = ref.read(animalGenealogyProvider(animal.id)).value;
    final breedName = animal.breed?.name ?? 'Race Ovine Sélectionnée';
    final lineageLabel =
        (animal.lineage != null && animal.lineage!.trim().isNotEmpty)
        ? animal.lineage!
        : 'Lignée Sélectionnée — Registre Jur-gui';
    final fatherLabel = genealogy?.father != null
        ? '${genealogy!.father!.name} (${genealogy.father!.id})'
        : (animal.fatherId != null && animal.fatherId!.isNotEmpty
              ? 'Réf. ${animal.fatherId!}'
              : 'Ascendant externe');
    final motherLabel = genealogy?.mother != null
        ? '${genealogy!.mother!.name} (${genealogy.mother!.id})'
        : (animal.motherId != null && animal.motherId!.isNotEmpty
              ? 'Réf. ${animal.motherId!}'
              : 'Ascendante externe');
    final pgfLabel = genealogy?.paternalGrandfather != null
        ? '${genealogy!.paternalGrandfather!.name} (${genealogy.paternalGrandfather!.id})'
        : 'Non répertorié';
    final pgmLabel = genealogy?.paternalGrandmother != null
        ? '${genealogy!.paternalGrandmother!.name} (${genealogy.paternalGrandmother!.id})'
        : 'Non répertoriée';
    final mgfLabel = genealogy?.maternalGrandfather != null
        ? '${genealogy!.maternalGrandfather!.name} (${genealogy.maternalGrandfather!.id})'
        : 'Non répertorié';
    final mgmLabel = genealogy?.maternalGrandmother != null
        ? '${genealogy!.maternalGrandmother!.name} (${genealogy.maternalGrandmother!.id})'
        : 'Non répertoriée';
    final weightLabel = animal.currentWeightKg != null
        ? '${animal.currentWeightKg!.toStringAsFixed(1)} kg'
        : 'Non pesé';
    final tagLabel =
        animal.physicalTag != null && animal.physicalTag!.isNotEmpty
        ? animal.physicalTag!
        : 'Non bouclé';
    final certRef =
        'JG-DKR-${animal.id.toUpperCase()}-${DateTime.now().year}';
    final shareText = _buildPedigreeShareText(animal, genealogy);
    final publicUrl = _buildPublicPedigreeUrl(animal.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.90,
        ),
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: AppColors.floatingShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    LucideIcons.award,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dossier Généalogique & Pedigree',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Fiche officielle de lignée pour éleveurs & acheteurs',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Aperçu du Certificat Officiel (Scrollable)
            Flexible(
              child: SingleChildScrollView(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCFCFA),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.gold,
                      width: 1.8,
                    ),
                    boxShadow: AppColors.softShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // En-tête Institutionnel Vert Forêt & Or
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          gradient: AppColors.heroGradient,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(18),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'LIVRE GÉNÉALOGIQUE OVIN • DAKAR',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.gold,
                                    letterSpacing: 0.9,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.28),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: AppColors.gold.withValues(
                                        alpha: 0.4,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    certRef,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(2.5),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: AppColors.goldGradient,
                                  ),
                                  child: AnimalPhotoImage(
                                    photoUrl: animal.photoUrl,
                                    size: 58,
                                    fallback: CircleAvatar(
                                      radius: 29,
                                      backgroundColor: AppColors.primary,
                                      child: Text(
                                        animal.name.isNotEmpty
                                            ? animal.name[0].toUpperCase()
                                            : 'O',
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        animal.name.toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '$breedName • ${animal.isFemale ? "♀ Brebis" : "♂ Bélier Géniteur"}',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white.withValues(
                                            alpha: 0.85,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Bandeau Lignée Or
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: const BoxDecoration(
                          color: AppColors.goldLight,
                          border: Border(
                            bottom: BorderSide(color: Color(0xFFE5D59B)),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              LucideIcons.dna,
                              size: 16,
                              color: AppColors.goldDark,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'LIGNÉE / FAMILLE GÉNÉTIQUE',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.goldDark,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  Text(
                                    lineageLabel,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Corps du certificat : Grille Zootechnique + Arbre 2 générations
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 4 indicateurs clés
                            Row(
                              children: [
                                Expanded(
                                  child: _buildCertMetricBox(
                                    'N° REGISTRE',
                                    animal.id,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildCertMetricBox(
                                    'BOUCLE',
                                    tagLabel,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildCertMetricBox(
                                    'POIDS CERTIFIÉ',
                                    weightLabel,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildCertMetricBox(
                                    'ÂGE',
                                    _formatAgeDetail(animal),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'ASCENDANCE OFFICIELLE (PARENTS & GRANDS-PARENTS)',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Branche Paternelle (Sire)
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFF),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(
                                    0xFF1D4ED8,
                                  ).withValues(alpha: 0.25),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        LucideIcons.mars,
                                        size: 14,
                                        color: Color(0xFF1D4ED8),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'PÈRE (SIRE) : ',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF1D4ED8),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          fatherLabel,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.textPrimary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '├─ GP Paternel : $pgfLabel\n└─ GM Paternelle : $pgmLabel',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.textSecondary,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Branche Maternelle (Dam)
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF8FB),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(
                                    0xFFBE185D,
                                  ).withValues(alpha: 0.25),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        LucideIcons.venus,
                                        size: 14,
                                        color: Color(0xFFBE185D),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'MÈRE (DAM) : ',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFFBE185D),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          motherLabel,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.textPrimary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '├─ GP Maternel : $mgfLabel\n└─ GM Maternelle : $mgmLabel',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.textSecondary,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Bouton Copier Dossier Officiel Complet
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(LucideIcons.fileCheck2, size: 18),
              label: const Text(
                'Copier le dossier généalogique officiel',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: shareText));
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Dossier généalogique officiel copié dans le presse-papiers !',
                      ),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 8),

            // Bouton Copier Lien Certificat Web / PDF
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.divider),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(LucideIcons.globe, size: 18),
              label: const Text(
                'Copier le lien du Certificat Web (PDF imprimable)',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
              ),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: publicUrl));
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lien du certificat copié : $publicUrl'),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertMetricBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPedigreeLineageCard(Animal animal) {
    final genealogyAsync = ref.watch(animalGenealogyProvider(animal.id));
    final genealogy = genealogyAsync.value;
    final hasLineage =
        animal.lineage != null && animal.lineage!.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.goldLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  LucideIcons.network,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Lignée, Généalogie & Partage',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _showSharePedigreeSheet(animal),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.goldLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.45),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.share2,
                        size: 14,
                        color: AppColors.goldDark,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Partager',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.goldDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Bandeau Lignée / Sang
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: hasLineage
                  ? AppColors.goldLight.withValues(alpha: 0.55)
                  : AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: hasLineage
                    ? AppColors.gold.withValues(alpha: 0.45)
                    : AppColors.divider,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.dna,
                  size: 18,
                  color: hasLineage
                      ? AppColors.goldDark
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lignée / Famille génétique',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasLineage
                            ? animal.lineage!
                            : 'Aucune lignée renseignée (cliquer sur Modifier)',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: hasLineage
                              ? AppColors.textPrimary
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Modifier la lignée',
                  icon: const Icon(
                    LucideIcons.pencil,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  onPressed: () => _showEditAnimalSheet(animal),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              // Sire / Père
              Expanded(
                child: _buildParentCard(
                  role: 'Père (Bélier)',
                  parentId: animal.fatherId,
                  parentName: genealogy?.father?.name,
                  icon: LucideIcons.mars,
                  color: const Color(0xFF1D4ED8),
                ),
              ),
              const SizedBox(width: 12),
              // Dam / Mère
              Expanded(
                child: _buildParentCard(
                  role: 'Mère (Brebis)',
                  parentId: animal.motherId,
                  parentName: genealogy?.mother?.name,
                  icon: LucideIcons.venus,
                  color: const Color(0xFFBE185D),
                ),
              ),
            ],
          ),

          // Descendance (Offspring)
          if (genealogy != null && genealogy.offspring.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Descendance enregistrée (${genealogy.offspring.length})',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: genealogy.offspring.map((child) {
                return InkWell(
                  onTap: () => context.push('/animals/${child.id}'),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          child.sex == 'female'
                              ? LucideIcons.venus
                              : LucideIcons.mars,
                          size: 13,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${child.name} (${child.id})',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildParentCard({
    required String role,
    required String? parentId,
    String? parentName,
    required IconData icon,
    required Color color,
  }) {
    final hasParent = parentId != null && parentId.isNotEmpty;
    final displayTitle = hasParent
        ? (parentName != null && parentName.isNotEmpty
              ? '$parentName ($parentId)'
              : parentId)
        : 'Non répertorié';

    return InkWell(
      onTap: hasParent ? () => context.push('/animals/$parentId') : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    role,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              displayTitle,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: hasParent
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              hasParent ? 'Voir la fiche' : 'Origine externe',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: hasParent ? color : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- CHARACTERISTICS & HEALTH CARD ---
  Widget _buildCharacteristicsCard(Animal animal) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  LucideIcons.info,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Caractéristiques',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _showEditAnimalSheet(animal),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.pencil,
                        size: 13,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Modifier',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (animal.birthDate != null)
            _buildDetailRow(
              label: 'Date de naissance',
              value: Formatters.formatDate(animal.birthDate),
            ),
          _buildDetailRow(
            label: 'État corporel',
            value: Formatters.translateCondition(animal.bodyCondition),
            badgeColor: Formatters.getConditionColor(animal.bodyCondition),
          ),
          _buildDetailRow(
            label: 'Statut physiologique',
            value: Formatters.translateReproStatus(animal.reproductionStatus),
          ),
          _buildDetailRow(
            label: 'Origine de l\'animal',
            value: animal.origin == 'birth'
                ? 'Né à la ferme'
                : 'Achat extérieur',
          ),
          if (animal.purchasePriceCfa != null)
            _buildDetailRow(
              label: 'Prix d\'acquisition',
              value: Formatters.formatCFA(animal.purchasePriceCfa),
            ),
          _buildDetailRow(
            label: 'Date d\'entrée en exploitation',
            value: Formatters.formatDate(animal.entryDate),
          ),
          if (animal.notes != null && animal.notes!.isNotEmpty)
            _buildDetailRow(label: 'Notes de suivi', value: animal.notes!),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    Color? badgeColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (badgeColor != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: badgeColor,
                ),
              ),
            )
          else
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
        ],
      ),
    );
  }

  // --- SECTOR MOVEMENTS TIMELINE (MODULE A 3.5) ---
  Widget _buildSectorMovementsTimeline(Animal animal) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  LucideIcons.history,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Historique d\'Enclos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (animal.movements.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Aucun déplacement historisé pour cet animal.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: animal.movements.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final m = animal.movements[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.divider,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.arrowLeftRight,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Vers Enclos #${m.toSectorId}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${Formatters.formatDateTime(m.movementDate)}${m.reason != null ? " • ${m.reason}" : ""}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // --- FLOATING ACTION BAR (OPAQUE) ---
  Widget _buildBottomActionBar(Animal animal) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider),
        boxShadow: AppColors.floatingShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
              ),
              icon: const Icon(LucideIcons.scale, size: 18),
              label: const Text(
                'Peser',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              onPressed: () => _showAddWeightDialog(animal),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.divider),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(LucideIcons.arrowLeftRight, size: 17),
              label: const Text(
                'Déplacer',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              onPressed: () => _showMoveSectorDialog(animal),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.divider),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(LucideIcons.pencil, size: 17),
              label: const Text(
                'Modifier',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              onPressed: () => _showEditAnimalSheet(animal),
            ),
          ),
        ],
      ),
    );
  }
}
