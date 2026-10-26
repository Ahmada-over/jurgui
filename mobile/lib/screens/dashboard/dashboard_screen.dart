import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/error_retry_card.dart';
import '../../core/widgets/sheep_hoof_icon.dart';
import '../../models/dashboard.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final authState = ref.watch(authProvider);
    final userName = authState.user?['full_name'] ?? 'Administrateur';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async => ref.refresh(dashboardProvider),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // En-tête sobre et lisible
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: SheepHoofIcon(
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Jur-gui',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Bonjour, $userName',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Contenu
              dashboardAsync.when(
                loading: () => const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  ),
                ),
                error: (err, _) => SliverFillRemaining(
                  child: ErrorRetryCard(
                    message: 'Impossible de charger l\'aperçu : $err',
                    onRetry: () => ref.refresh(dashboardProvider),
                  ),
                ),
                data: (data) => SliverList(
                  delegate: SliverChildListDelegate([
                    // 1. BANDEAU FERME & ALERTE DU JOUR
                    _buildFarmAlertBanner(context, data),
                    const SizedBox(height: 16),

                    // 2. TROIS BOUTONS D'ACTION FIXES (pas de défilement, sans Profil)
                    _buildFixedQuickActions(context),
                    const SizedBox(height: 24),

                    // 3. QUATRE TUILES OPÉRATIONNELLES (avec états réels et écrans branchés)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildOperationalGrid(context, data),
                    ),
                    const SizedBox(height: 24),

                    // 4. MISES BAS IMMINENTES
                    if (data.upcomingBirths.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildUpcomingBirthsSection(
                          context,
                          data.upcomingBirths,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // 5. RÉPARTITION PAR RACE
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildBreedBreakdownSection(data),
                    ),
                    const SizedBox(height: 24),

                    // 6. CAPACITÉ DES ENCLOS
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildSectorsSection(data.sectors),
                    ),
                    const SizedBox(height: 36),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Bandeau vert forêt : affiche le nom de la ferme et la seule alerte prioritaire du jour en blanc plein
  Widget _buildFarmAlertBanner(BuildContext context, DashboardData data) {
    final sortedBirths = [...data.upcomingBirths]
      ..sort((a, b) => a.daysLeft.compareTo(b.daysLeft));
    final urgentBirth = sortedBirths.isNotEmpty ? sortedBirths.first : null;
    final saturatedSector = data.sectors
        .where(
          (s) =>
              s.isOvercrowded || (s.capacity > 0 && s.occupancy >= s.capacity),
        )
        .firstOrNull;

    String alertText;
    IconData alertIcon;
    VoidCallback? onAlertTap;
    bool hasAlert = true;

    if (urgentBirth != null && urgentBirth.daysLeft <= 14) {
      final days = urgentBirth.daysLeft;
      alertText = days <= 0
          ? 'Mise bas aujourd\'hui — Brebis ${urgentBirth.femaleId}'
          : 'Mise bas dans $days jour${days > 1 ? "s" : ""} — Brebis ${urgentBirth.femaleId}';
      alertIcon = LucideIcons.baby;
      onAlertTap = () => context.go('/reproduction');
    } else if (saturatedSector != null) {
      alertText =
          'Enclos saturé : ${saturatedSector.sectorName} (${saturatedSector.occupancy}/${saturatedSector.capacity})';
      alertIcon = LucideIcons.doorOpen;
      onAlertTap = () => context.go('/animals');
    } else if (urgentBirth != null) {
      alertText =
          'Prochaine mise bas dans ${urgentBirth.daysLeft} jours (${urgentBirth.femaleId})';
      alertIcon = LucideIcons.calendarClock;
      onAlertTap = () => context.go('/reproduction');
    } else {
      hasAlert = false;
      alertText = 'Aucune alerte critique aujourd\'hui — Élevage calme';
      alertIcon = LucideIcons.check;
      onAlertTap = null;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onAlertTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bergerie Jur-gui — Dakar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: hasAlert
                        ? AppColors.goldLight
                        : Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        alertIcon,
                        size: 20,
                        color: hasAlert ? AppColors.primary : Colors.white,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          alertText,
                          style: TextStyle(
                            color: hasAlert
                                ? AppColors.textPrimary
                                : Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (onAlertTap != null)
                        Icon(
                          LucideIcons.chevronRight,
                          size: 18,
                          color: hasAlert
                              ? AppColors.textPrimary
                              : Colors.white,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Trois boutons fixes de saisie (Nouvel ovin, Saillie, Mise bas) — pas de défilement
  Widget _buildFixedQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildFixedActionButton(
              icon: LucideIcons.plus,
              label: 'Nouvel ovin',
              onTap: () => context.push('/animals/add'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildFixedActionButton(
              icon: LucideIcons.heart,
              label: 'Saillie',
              onTap: () => context.push('/reproduction/mating'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildFixedActionButton(
              icon: LucideIcons.baby,
              label: 'Mise bas',
              onTap: () => context.push('/reproduction/birth'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFixedActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
            boxShadow: AppColors.softShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: AppColors.primary),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Grille des indicateurs avec pastilles d'état réel uniquement (sans les modules masqués)
  Widget _buildOperationalGrid(BuildContext context, DashboardData data) {
    final hasSaturatedSector = data.sectors.any(
      (s) => s.isOvercrowded || (s.capacity > 0 && s.occupancy >= s.capacity),
    );
    final hasImminentBirth = data.upcomingBirths.any((b) => b.daysLeft <= 7);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Indicateurs Opérationnels',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatTile(
                title: 'Cheptel Actif',
                value: '${data.totalActiveAnimals}',
                unit: 'têtes',
                customIcon: const SheepHoofIcon(
                  size: 20,
                  color: AppColors.primary,
                ),
                badgeText: data.totalActiveAnimals > 0 ? 'Recensé' : 'Vide',
                isAlert: false,
                onTap: () => context.go('/animals'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatTile(
                title: 'Gestations',
                value: '${data.activePregnancies}',
                unit: 'suivies',
                icon: LucideIcons.heart,
                badgeText: hasImminentBirth
                    ? 'Imminent'
                    : (data.activePregnancies > 0 ? 'En cours' : 'Calme'),
                isAlert: hasImminentBirth,
                onTap: () => context.go('/reproduction'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildStatTile(
          title: 'Enclos & Secteurs',
          value: '${data.sectors.length}',
          unit: 'enclos actifs',
          icon: LucideIcons.layoutGrid,
          badgeText: hasSaturatedSector ? 'Saturé' : 'Calme',
          isAlert: hasSaturatedSector,
          onTap: () => context.go('/animals'),
        ),
      ],
    );
  }

  Widget _buildStatTile({
    required String title,
    required String value,
    required String unit,
    IconData? icon,
    Widget? customIcon,
    required String badgeText,
    required bool isAlert,
    required VoidCallback onTap,
  }) {
    final badgeBg = isAlert
        ? AppColors.danger.withValues(alpha: 0.12)
        : AppColors.primaryContainer;
    final badgeFg = isAlert ? AppColors.danger : AppColors.primary;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isAlert
                  ? AppColors.danger.withValues(alpha: 0.35)
                  : AppColors.divider,
            ),
            boxShadow: AppColors.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child:
                        customIcon ??
                        Icon(icon, size: 20, color: AppColors.primary),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: badgeFg,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      unit,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingBirthsSection(
    BuildContext context,
    List<UpcomingBirth> births,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.goldLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.45)),
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.bellRing,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Mises Bas Imminentes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => context.go('/reproduction'),
                child: const Text(
                  'Voir tout',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...births.map(
            (b) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppColors.softShadow,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primaryContainer,
                    child: Text(
                      b.femaleId.isNotEmpty
                          ? b.femaleId.substring(
                              0,
                              b.femaleId.length >= 2 ? 2 : 1,
                            )
                          : 'OV',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Brebis : ${b.femaleId}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Terme estimé : ${b.expectedDate}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: b.daysLeft <= 7
                          ? AppColors.danger.withValues(alpha: 0.12)
                          : AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'J-${b.daysLeft}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: b.daysLeft <= 7
                            ? AppColors.danger
                            : AppColors.primary,
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
  }

  Widget _buildBreedBreakdownSection(DashboardData data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Répartition Génétique',
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${data.totalActiveAnimals} animaux',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...data.byBreed.entries.map((entry) {
            final color = Formatters.getBreedColor(entry.key);
            final count = entry.value;
            final ratio = data.totalActiveAnimals > 0
                ? (count / data.totalActiveAnimals)
                : 0.0;
            final percent = (ratio * 100).toStringAsFixed(0);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            entry.key,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '$count têtes ($percent%)',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 7,
                      backgroundColor: AppColors.background,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSectorsSection(List<SectorStat> sectors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Capacité des Enclos',
            style: TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          ...sectors.map((sec) {
            final ratio = sec.capacity > 0
                ? (sec.occupancy / sec.capacity).clamp(0.0, 1.0)
                : 0.0;
            final isFull =
                sec.isOvercrowded ||
                (sec.capacity > 0 && sec.occupancy >= sec.capacity);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        sec.sectorName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isFull
                              ? AppColors.danger.withValues(alpha: 0.14)
                              : AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isFull ? 'Saturé' : 'Calme',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isFull
                                ? AppColors.danger
                                : AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 8,
                      backgroundColor: Colors.white,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isFull ? AppColors.danger : AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${sec.occupancy} animaux présents sur ${sec.capacity} places estimées',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
