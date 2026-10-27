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
          color: AppColors.primaryAccent,
          onRefresh: () async => ref.refresh(dashboardProvider),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // En-tête avec identité couleur & cloche de notifications
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: AppColors.heroGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppColors.softShadow,
                        ),
                        child: const Center(
                          child: SheepHoofIcon(
                            color: AppColors.gold,
                            size: 24,
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
                      _buildNotificationBellButton(context, dashboardAsync.value),
                    ],
                  ),
                ),
              ),

              // Contenu
              dashboardAsync.when(
                loading: () => const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryAccent,
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

  /// Cloche de notifications en haut à droite avec pastille vive pour attirer l'attention
  Widget _buildNotificationBellButton(
    BuildContext context,
    DashboardData? data,
  ) {
    final saturatedCount = data?.sectors
            .where(
              (s) =>
                  s.isOvercrowded ||
                  (s.capacity > 0 && s.occupancy >= s.capacity),
            )
            .length ??
        0;
    final birthAlertsCount = data?.upcomingBirths.length ?? 0;
    final totalAlerts = birthAlertsCount + saturatedCount;
    final hasUrgent = (data?.upcomingBirths.any((b) => b.daysLeft <= 7) ??
            false) ||
        saturatedCount > 0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: totalAlerts > 0 ? AppColors.goldLight : Colors.white,
          borderRadius: BorderRadius.circular(15),
          child: InkWell(
            onTap: () => _showNotificationsSheet(context, data),
            borderRadius: BorderRadius.circular(15),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: totalAlerts > 0
                      ? AppColors.gold.withValues(alpha: 0.65)
                      : AppColors.divider,
                  width: 1.3,
                ),
                boxShadow: AppColors.softShadow,
              ),
              child: Icon(
                totalAlerts > 0 ? LucideIcons.bellRing : LucideIcons.bell,
                size: 21,
                color: totalAlerts > 0
                    ? const Color(0xFFC2410C)
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ),
        if (totalAlerts > 0)
          Positioned(
            right: -3,
            top: -3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: hasUrgent ? AppColors.danger : const Color(0xFFC2410C),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1.8),
              ),
              child: Text(
                '$totalAlerts',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Feuille modale des notifications utilisant les couleurs vives de l'accueil
  void _showNotificationsSheet(BuildContext context, DashboardData? data) {
    final births = [...(data?.upcomingBirths ?? <UpcomingBirth>[])]
      ..sort((a, b) => a.daysLeft.compareTo(b.daysLeft));
    final saturatedSectors = (data?.sectors ?? <SectorStat>[])
        .where(
          (s) =>
              s.isOvercrowded || (s.capacity > 0 && s.occupancy >= s.capacity),
        )
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: AppColors.goldGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        LucideIcons.bellRing,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notifications & Alertes',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Suivi en temps réel du cheptel et des mises bas',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (births.isEmpty && saturatedSectors.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          LucideIcons.circleCheck,
                          color: AppColors.primaryAccent,
                          size: 22,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Aucune alerte en attente. Tout le cheptel est calme.',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  ...births.map((b) {
                    final isUrgent = b.daysLeft <= 7;
                    final accent = isUrgent
                        ? const Color(0xFFC2410C)
                        : AppColors.goldDark;
                    final bg = isUrgent
                        ? const Color(0xFFFFF7ED)
                        : AppColors.goldLight;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.35),
                        ),
                      ),
                      child: ListTile(
                        onTap: () {
                          Navigator.pop(sheetCtx);
                          context.go('/reproduction');
                        },
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            LucideIcons.baby,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        title: Text(
                          'Mise bas — Brebis ${b.femaleId}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          'Terme prévu le ${b.expectedDate}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isUrgent ? AppColors.danger : accent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            b.daysLeft <= 0 ? 'Aujourd\'hui' : 'J-${b.daysLeft}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  ...saturatedSectors.map(
                    (s) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.danger.withValues(alpha: 0.35),
                        ),
                      ),
                      child: ListTile(
                        onTap: () {
                          Navigator.pop(sheetCtx);
                          context.go('/animals');
                        },
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            LucideIcons.doorOpen,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        title: Text(
                          'Enclos saturé : ${s.sectorName}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          'Occupation : ${s.occupancy} / ${s.capacity} places',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        trailing: const Icon(
                          LucideIcons.chevronRight,
                          color: AppColors.danger,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Bandeau vert forêt : affiche le nom de la ferme et la seule alerte prioritaire du jour avec couleurs vives
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
    Color alertIconColor;
    VoidCallback? onAlertTap;
    bool hasAlert = true;

    if (urgentBirth != null && urgentBirth.daysLeft <= 14) {
      final days = urgentBirth.daysLeft;
      alertText = days <= 0
          ? 'Mise bas aujourd\'hui — Brebis ${urgentBirth.femaleId}'
          : 'Mise bas dans $days jour${days > 1 ? "s" : ""} — Brebis ${urgentBirth.femaleId}';
      alertIcon = LucideIcons.baby;
      alertIconColor = const Color(0xFFC2410C);
      onAlertTap = () => context.go('/reproduction');
    } else if (saturatedSector != null) {
      alertText =
          'Enclos saturé : ${saturatedSector.sectorName} (${saturatedSector.occupancy}/${saturatedSector.capacity})';
      alertIcon = LucideIcons.doorOpen;
      alertIconColor = AppColors.danger;
      onAlertTap = () => context.go('/animals');
    } else if (urgentBirth != null) {
      alertText =
          'Prochaine mise bas dans ${urgentBirth.daysLeft} jours (${urgentBirth.femaleId})';
      alertIcon = LucideIcons.calendarClock;
      alertIconColor = AppColors.goldDark;
      onAlertTap = () => context.go('/reproduction');
    } else {
      hasAlert = false;
      alertText = 'Aucune alerte critique aujourd\'hui — Élevage calme';
      alertIcon = LucideIcons.check;
      alertIconColor = AppColors.primaryAccent;
      onAlertTap = null;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: AppColors.floatingShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onAlertTap,
          borderRadius: BorderRadius.circular(26),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryAccent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryAccent,
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Bergerie Jur-gui — Dakar',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const Icon(
                      LucideIcons.activity,
                      color: AppColors.gold,
                      size: 22,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: hasAlert
                        ? AppColors.goldLight
                        : Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(16),
                    border: hasAlert
                        ? Border.all(
                            color: AppColors.gold.withValues(alpha: 0.6),
                          )
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: hasAlert
                              ? alertIconColor.withValues(alpha: 0.14)
                              : Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          alertIcon,
                          size: 18,
                          color: hasAlert ? alertIconColor : Colors.white,
                        ),
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
                          color: hasAlert ? alertIconColor : Colors.white,
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

  /// Trois boutons fixes de saisie avec leurs couleurs distinctives d'origine
  Widget _buildFixedQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildFixedActionButton(
              icon: LucideIcons.plus,
              label: 'Nouvel ovin',
              color: AppColors.primary,
              onTap: () => context.push('/animals/add'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildFixedActionButton(
              icon: LucideIcons.heart,
              label: 'Saillie',
              color: AppColors.goldDark,
              onTap: () => context.push('/reproduction/mating'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildFixedActionButton(
              icon: LucideIcons.baby,
              label: 'Mise bas',
              color: const Color(0xFFC2410C),
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
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.22)),
            boxShadow: AppColors.softShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: color),
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

  /// Grille des indicateurs avec les couleurs vives d'accueil et pastilles d'état réel
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
                  color: AppColors.primaryAccent,
                ),
                accentColor: AppColors.primaryAccent,
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
                accentColor: AppColors.goldDark,
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
          accentColor: AppColors.info,
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
    required Color accentColor,
    required String badgeText,
    required bool isAlert,
    required VoidCallback onTap,
  }) {
    final effectiveAccent = isAlert ? AppColors.danger : accentColor;
    final badgeBg = effectiveAccent.withValues(alpha: 0.14);
    final badgeFg = effectiveAccent;

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
                      color: accentColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child:
                        customIcon ??
                        Icon(icon, size: 20, color: accentColor),
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
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
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
                      color: AppColors.gold,
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
                    color: AppColors.goldDark,
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
                          ? AppColors.danger.withValues(alpha: 0.14)
                          : AppColors.primaryAccent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'J-${b.daysLeft}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: b.daysLeft <= 7
                            ? AppColors.danger
                            : AppColors.primaryAccent,
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
