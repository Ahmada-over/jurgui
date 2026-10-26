import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/sheep_hoof_icon.dart';
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
              Navigator.pop(ctx);
              await ref
                  .read(animalActionsServiceProvider)
                  .addWeight(animal.id, w, notesController.text.trim());
              ref.invalidate(animalDetailProvider(animal.id));
              ref.invalidate(animalsListProvider);
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
                  value: selectedSectorId,
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
                      Navigator.pop(ctx);
                      await ref
                          .read(animalActionsServiceProvider)
                          .moveAnimalSector(
                            animal.id,
                            selectedSectorId!,
                            reasonController.text.trim().isEmpty
                                ? 'Déplacement de routine'
                                : reasonController.text.trim(),
                          );
                      ref.invalidate(animalDetailProvider(animal.id));
                      ref.invalidate(animalsListProvider);
                      ref.invalidate(sectorsProvider);
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

  @override
  Widget build(BuildContext context) {
    final animalAsync = ref.watch(animalDetailProvider(widget.animalId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.animalId,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: () => ref.refresh(animalDetailProvider(widget.animalId)),
          ),
        ],
      ),
      body: animalAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryAccent),
        ),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                LucideIcons.circleAlert,
                size: 48,
                color: AppColors.danger,
              ),
              const SizedBox(height: 12),
              Text(
                'Erreur de chargement: $err',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () =>
                    ref.refresh(animalDetailProvider(widget.animalId)),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (animal) {
          final breedName = animal.breed?.name ?? 'Race inconnue';
          final isLadoum =
              breedName.toLowerCase().contains('ladoum') &&
              !breedName.toLowerCase().contains('métis');
          final breedColor = Formatters.getBreedColor(breedName);

          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                children: [
                  // 1. HERO PRESTIGE HEADER
                  _buildPrestigeHeroHeader(
                    animal,
                    breedName,
                    isLadoum,
                    breedColor,
                  ),
                  const SizedBox(height: 16),

                  // 2. QUAD STAT TILES
                  _buildQuickStatsGrid(animal),
                  const SizedBox(height: 16),

                  // 3. FL_CHART WEIGHT GROWTH TRAJECTORY
                  _buildWeightGrowthChart(animal),
                  const SizedBox(height: 16),

                  // 4. PEDIGREE & LINEAGE CARD
                  _buildPedigreeLineageCard(animal),
                  const SizedBox(height: 16),

                  // 5. CHARACTERISTICS & HEALTH CARD
                  _buildCharacteristicsCard(animal),
                  const SizedBox(height: 16),

                  // 6. HISTORIQUE DES ENCLOS TIMELINE (MODULE A 3.5)
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
        },
      ),
    );
  }

  // --- HERO HEADER ---
  Widget _buildPrestigeHeroHeader(
    Animal animal,
    String breedName,
    bool isLadoum,
    Color breedColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.softShadow,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar with Prestige Border
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isLadoum ? AppColors.goldGradient : null,
                  color: isLadoum ? null : AppColors.primaryAccent,
                  boxShadow: isLadoum ? AppColors.glowGold : null,
                ),
                padding: const EdgeInsets.all(3),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF092920),
                  ),
                  child: Center(
                    child: Text(
                      animal.name.isNotEmpty
                          ? animal.name.characters.first.toUpperCase()
                          : 'O',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: isLadoum ? AppColors.gold : Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Animal info & tags
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isLadoum)
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppColors.goldGradient,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '✦ ÉLITE LADOUM DAKAR',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF382305),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    Text(
                      animal.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${animal.id}${animal.physicalTag != null ? " • Boucle: ${animal.physicalTag}" : ""}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _buildGlassChip(
                          label: breedName,
                          customIcon: SheepHoofIcon(
                            size: 12,
                            color: isLadoum
                                ? AppColors.gold
                                : AppColors.primaryAccent,
                          ),
                          color: isLadoum
                              ? AppColors.gold
                              : AppColors.primaryAccent,
                        ),
                        _buildGlassChip(
                          label: animal.isFemale ? 'Brebis' : 'Bélier',
                          icon: animal.isFemale
                              ? LucideIcons.venus
                              : LucideIcons.mars,
                          color: animal.isFemale
                              ? const Color(0xFFF472B6)
                              : const Color(0xFF60A5FA),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlassChip({
    required String label,
    IconData? icon,
    Widget? customIcon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          customIcon ?? Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // --- QUAD STAT TILES ---
  Widget _buildQuickStatsGrid(Animal animal) {
    // Calculate weight delta if multiple weights
    String? weightTrend;
    if (animal.weightRecords.length >= 2) {
      final sorted = [...animal.weightRecords]
        ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
      final delta = sorted.last.weightKg - sorted[sorted.length - 2].weightKg;
      final sign = delta >= 0 ? '+' : '';
      weightTrend = '$sign${delta.toStringAsFixed(1)} kg';
    }

    final ageString = animal.birthDate != null
        ? '${DateTime.now().difference(animal.birthDate!).inDays ~/ 30} mois'
        : (animal.estimatedAgeMonths != null
              ? '${animal.estimatedAgeMonths} mois (est.)'
              : 'Non précisé');

    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            title: 'Poids Actuel',
            value: animal.currentWeightKg != null
                ? '${animal.currentWeightKg!.toStringAsFixed(1)} kg'
                : 'Non pesé',
            subtitle:
                weightTrend ??
                (animal.weightRecords.isNotEmpty
                    ? 'Dernier relevé'
                    : 'Aucun relevé'),
            icon: LucideIcons.scale,
            iconColor: AppColors.primaryAccent,
            trendColor: weightTrend != null && weightTrend.startsWith('+')
                ? AppColors.success
                : AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricTile(
            title: 'Enclos',
            value: animal.currentSector?.name ?? 'Non assigné',
            subtitle: animal.currentSector != null
                ? '${animal.currentSector!.currentOccupancy}/${animal.currentSector!.estimatedCapacity} ovins'
                : 'Secteur libre',
            icon: LucideIcons.doorOpen,
            iconColor: const Color(0xFF38BDF8),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricTile(
            title: 'Âge',
            value: ageString,
            subtitle: animal.isFemale
                ? Formatters.translateReproStatus(animal.reproductionStatus)
                : 'Reproducteur',
            icon: LucideIcons.calendarDays,
            iconColor: AppColors.gold,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    Color? trendColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: iconColor),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: trendColor ?? AppColors.textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
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
                      fontWeight: FontWeight.w800,
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
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
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
                        '+ Pesée',
                        style: TextStyle(
                          fontSize: 12,
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
                  Icon(
                    LucideIcons.scale,
                    size: 36,
                    color: AppColors.textMuted.withValues(alpha: 0.6),
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
                        vertical: 8,
                      ),
                    ),
                    icon: const Icon(LucideIcons.plus, size: 16),
                    label: const Text(
                      'Enregistrer la première pesée',
                      style: TextStyle(fontSize: 12),
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
                      color: AppColors.divider.withValues(alpha: 0.6),
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 38,
                        getTitlesWidget: (val, meta) => Text(
                          '${val.toInt()}k',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
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
                                fontSize: 10,
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.bold,
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
                      color: AppColors.primaryLight,
                      barWidth: 3.5,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) =>
                            FlDotCirclePainter(
                              radius: 4.5,
                              color: AppColors.primaryAccent,
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
                            AppColors.primaryAccent.withValues(alpha: 0.28),
                            AppColors.primaryAccent.withValues(alpha: 0.0),
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
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isHighlighted ? AppColors.primary : AppColors.textMuted,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: isHighlighted ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // --- PEDIGREE & LINEAGE CARD ---
  Widget _buildPedigreeLineageCard(Animal animal) {
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
                  color: AppColors.goldDark,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Généalogie & Ascendance (Pedigree)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              // Sire / Père
              Expanded(
                child: _buildParentCard(
                  role: 'Père (Bélier)',
                  parentId: animal.fatherId,
                  icon: LucideIcons.mars,
                  color: const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 12),
              // Dam / Mère
              Expanded(
                child: _buildParentCard(
                  role: 'Mère (Brebis)',
                  parentId: animal.motherId,
                  icon: LucideIcons.venus,
                  color: const Color(0xFFEC4899),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParentCard({
    required String role,
    required String? parentId,
    required IconData icon,
    required Color color,
  }) {
    final hasParent = parentId != null && parentId.isNotEmpty;

    return InkWell(
      onTap: hasParent ? () => context.push('/animals/$parentId') : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Text(
                  role,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              hasParent ? parentId : 'Non répertorié',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: hasParent ? AppColors.textPrimary : AppColors.textMuted,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              hasParent ? 'Consulter la fiche ➔' : 'Origine externe',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: hasParent ? color : AppColors.textMuted,
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
              const Text(
                'Caractéristiques & État Sanitaire',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _buildDetailRow(
            label: 'État corporel (BCS)',
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
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Historique des Mouvements d\'Enclos',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Registre inaltérable (Conformité Module A)',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (animal.movements.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Aucun déplacement historisé pour cet animal.',
                style: TextStyle(
                  color: AppColors.textMuted.withValues(alpha: 0.8),
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
                      color: AppColors.divider.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
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
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${Formatters.formatDateTime(m.movementDate)}${m.reason != null ? " • ${m.reason}" : ""}',
                              style: const TextStyle(
                                fontSize: 11,
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

  // --- FLOATING ACTION BAR ---
  Widget _buildBottomActionBar(Animal animal) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0D3B2E).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppColors.floatingShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAccent,
                foregroundColor: const Color(0xFF092920),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
              ),
              icon: const Icon(LucideIcons.scale, size: 18),
              label: const Text(
                'Peser',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
              onPressed: () => _showAddWeightDialog(animal),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
              ),
              icon: const Icon(LucideIcons.arrowLeftRight, size: 18),
              label: const Text(
                'Déplacer',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
              onPressed: () => _showMoveSectorDialog(animal),
            ),
          ),
        ],
      ),
    );
  }
}
