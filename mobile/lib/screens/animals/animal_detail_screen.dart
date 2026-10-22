import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/animal.dart';
import '../../providers/animals_provider.dart';

class AnimalDetailScreen extends ConsumerStatefulWidget {
  final String animalId;

  const AnimalDetailScreen({super.key, required this.animalId});

  @override
  ConsumerState<AnimalDetailScreen> createState() => _AnimalDetailScreenState();
}

class _AnimalDetailScreenState extends ConsumerState<AnimalDetailScreen> {
  void _showAddWeightDialog(Animal animal) {
    final weightController = TextEditingController(text: animal.currentWeightKg?.toString() ?? '');
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Nouvelle pesée : ${animal.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Poids (kg)',
                suffixText: 'kg',
                prefixIcon: Icon(Icons.scale),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Observations (optionnel)',
                prefixIcon: Icon(Icons.note_alt_outlined),
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
              final w = double.tryParse(weightController.text);
              if (w == null || w <= 0) return;
              Navigator.pop(ctx);
              await ref.read(animalActionsServiceProvider).addWeight(animal.id, w, notesController.text.trim());
              ref.invalidate(animalDetailProvider(animal.id));
              ref.invalidate(animalsListProvider);
            },
            child: const Text('Enregistrer'),
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
          title: Text('Déplacer ${animal.name} d\'enclos'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              sectorsAsync.when(
                data: (sectors) => DropdownButtonFormField<int>(
                  value: selectedSectorId,
                  decoration: const InputDecoration(
                    labelText: 'Enclos / Secteur de destination',
                    prefixIcon: Icon(Icons.meeting_room_outlined),
                  ),
                  items: sectors.map((s) {
                    return DropdownMenuItem<int>(
                      value: s.id,
                      child: Text('${s.name} (${s.currentOccupancy}/${s.estimatedCapacity})'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setDialogState(() => selectedSectorId = val);
                  },
                ),
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('Erreur: $e'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Motif du déplacement',
                  hintText: 'ex: Lot de reproduction, isolement...',
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
              onPressed: selectedSectorId == null
                  ? null
                  : () async {
                      Navigator.pop(ctx);
                      await ref.read(animalActionsServiceProvider).moveAnimalSector(
                            animal.id,
                            selectedSectorId!,
                            reasonController.text.trim().isEmpty ? 'Déplacement de routine' : reasonController.text.trim(),
                          );
                      ref.invalidate(animalDetailProvider(animal.id));
                      ref.invalidate(animalsListProvider);
                      ref.invalidate(sectorsProvider);
                    },
              child: const Text('Valider le mouvement'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final animalAsync = ref.watch(animalDetailProvider(widget.animalId));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.animalId),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(animalDetailProvider(widget.animalId)),
          ),
        ],
      ),
      body: animalAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erreur : $err')),
        data: (animal) {
          final breedName = animal.breed?.name ?? 'Race inconnue';
          final breedColor = Formatters.getBreedColor(breedName);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: breedColor.withOpacity(0.15),
                        child: Text(
                          animal.name.isNotEmpty ? animal.name[0].toUpperCase() : 'O',
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: breedColor),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              animal.name,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ID : ${animal.id} ${animal.physicalTag != null ? "• Boucle : ${animal.physicalTag}" : ""}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: breedColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                breedName,
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: breedColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Action buttons (Pesée, Déplacement, Saillie)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.scale, size: 18),
                      label: const Text('Pesée', style: TextStyle(fontSize: 14)),
                      onPressed: () => _showAddWeightDialog(animal),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.swap_horiz, size: 18),
                      label: const Text('Déplacer', style: TextStyle(fontSize: 14)),
                      onPressed: () => _showMoveSectorDialog(animal),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Characteristics Grid
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Caractéristiques & État',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const Divider(),
                      _buildInfoRow('Sexe', animal.isFemale ? 'Femelle (Brebis)' : 'Mâle (Bélier)'),
                      _buildInfoRow('Enclos actuel', animal.currentSector?.name ?? 'Non défini'),
                      _buildInfoRow('Poids actuel', animal.currentWeightKg != null ? '${animal.currentWeightKg} kg' : 'Non pesé'),
                      _buildInfoRow('État corporel', Formatters.translateCondition(animal.bodyCondition)),
                      if (animal.isFemale)
                        _buildInfoRow('Statut reproduction', Formatters.translateReproStatus(animal.reproductionStatus)),
                      _buildInfoRow('Origine', animal.origin),
                      if (animal.purchasePriceCfa != null)
                        _buildInfoRow('Prix d\'acquisition', Formatters.formatCFA(animal.purchasePriceCfa)),
                      _buildInfoRow('Date d\'entrée', Formatters.formatDate(animal.entryDate)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Weight History
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Historique des Pesées',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Ajouter'),
                            onPressed: () => _showAddWeightDialog(animal),
                          ),
                        ],
                      ),
                      if (animal.weightRecords.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'Aucune pesée enregistrée pour le moment.',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                          ),
                        )
                      else
                        ...animal.weightRecords.map((w) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const CircleAvatar(
                                radius: 18,
                                backgroundColor: AppColors.primaryContainer,
                                child: Icon(Icons.scale, color: AppColors.primary, size: 18),
                              ),
                              title: Text(
                                '${w.weightKg} kg',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              subtitle: Text(
                                '${Formatters.formatDateTime(w.recordedAt)}${w.notes != null ? " • ${w.notes}" : ""}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Movements History (Module A - 3.5 non-deletable history)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Historique des Déplacements d\'Enclos',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const Divider(),
                      if (animal.movements.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'Aucun déplacement historisé.',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                          ),
                        )
                      else
                        ...animal.movements.map((m) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.swap_horiz, color: AppColors.secondary),
                              title: Text(
                                'Vers Secteur #${m.toSectorId}',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                              subtitle: Text(
                                '${Formatters.formatDateTime(m.movementDate)}${m.reason != null ? " • ${m.reason}" : ""}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            )),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
