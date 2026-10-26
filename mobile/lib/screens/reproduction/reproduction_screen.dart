import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/error_retry_card.dart';
import '../../models/reproduction.dart';
import '../../providers/reproduction_provider.dart';

class ReproductionScreen extends ConsumerStatefulWidget {
  const ReproductionScreen({super.key});

  @override
  ConsumerState<ReproductionScreen> createState() => _ReproductionScreenState();
}

class _ReproductionScreenState extends ConsumerState<ReproductionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _activeTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() => _activeTab = _tabController.index);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pregnanciesAsync = ref.watch(pregnanciesProvider);
    final matingsAsync = ref.watch(matingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            expandedHeight: 130,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 56),
              title: const Text(
                'Reproduction & Gestation',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.heroGradient,
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(44),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: _buildIslandTabBar(),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: Gestations
            RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async => ref.refresh(pregnanciesProvider),
              child: pregnanciesAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                ),
                error: (err, _) => ErrorRetryCard(
                  message: 'Impossible de charger les gestations : $err',
                  onRetry: () => ref.refresh(pregnanciesProvider),
                ),
                data: (pregnancies) {
                  if (pregnancies.isEmpty) {
                    return _buildEmptyState(
                      icon: LucideIcons.baby,
                      label: 'Aucune gestation en cours suivie.',
                      actionLabel: 'Enregistrer une saillie',
                      onTap: () => context.push('/reproduction/mating'),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                    itemCount: pregnancies.length,
                    itemBuilder: (context, index) =>
                        _buildPregnancyCard(pregnancies[index]),
                  );
                },
              ),
            ),

            // Tab 2: Saillies
            RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async => ref.refresh(matingsProvider),
              child: matingsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                ),
                error: (err, _) => ErrorRetryCard(
                  message: 'Impossible de charger les saillies : $err',
                  onRetry: () => ref.refresh(matingsProvider),
                ),
                data: (matings) {
                  if (matings.isEmpty) {
                    return _buildEmptyState(
                      icon: LucideIcons.heart,
                      label: 'Aucune saillie enregistrée.',
                      actionLabel: 'Enregistrer une saillie',
                      onTap: () => context.push('/reproduction/mating'),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                    itemCount: matings.length,
                    itemBuilder: (context, index) =>
                        _buildMatingCard(matings[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionBar(),
    );
  }

  // --- ISLAND TAB BAR ---
  Widget _buildIslandTabBar() {
    return Container(
      height: 40,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          _buildTabPill(0, LucideIcons.baby, 'Gestations'),
          _buildTabPill(1, LucideIcons.heart, 'Saillies'),
        ],
      ),
    );
  }

  Widget _buildTabPill(int index, IconData icon, String label) {
    final isActive = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _tabController.animateTo(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isActive ? AppColors.primary : Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isActive ? AppColors.primary : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- EMPTY STATE ---
  Widget _buildEmptyState({
    required IconData icon,
    required String label,
    required String actionLabel,
    required VoidCallback onTap,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: onTap,
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }

  // --- PREGNANCY CARD ---
  Widget _buildPregnancyCard(Pregnancy preg) {
    final progress = (preg.currentDay / preg.gestationDurationDays).clamp(
      0.0,
      1.0,
    );
    final daysLeft = preg.daysRemaining;
    final isUrgent = daysLeft <= 10;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        children: [
          // Header with Gradient (solid white text)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            decoration: BoxDecoration(
              gradient: isUrgent
                  ? const LinearGradient(
                      colors: [Color(0xFF7F1D1D), Color(0xFFB91C1C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : AppColors.heroGradient,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.baby,
                    size: 26,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Brebis : ${preg.femaleId}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Bélier : ${preg.ramId ?? "Non précisé"}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                // Countdown badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    daysLeft > 0 ? 'J-$daysLeft' : 'IMMINENT',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isUrgent
                          ? const Color(0xFFB91C1C)
                          : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'J+${preg.currentDay} / ${preg.gestationDurationDays} jours',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Prévue le ${Formatters.formatDate(preg.expectedBirthDate)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Progress bar
                Stack(
                  children: [
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: isUrgent
                              ? AppColors.danger
                              : AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Milestones
                const Text(
                  'Jalons du suivi de gestation',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildMilestonesTimeline(preg.timeline),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- MILESTONE TIMELINE ---
  Widget _buildMilestonesTimeline(List<GestationTimelineItem> milestones) {
    return Column(
      children: [
        for (int i = 0; i < milestones.length; i++)
          _buildMilestoneRow(milestones[i], isLast: i == milestones.length - 1),
      ],
    );
  }

  Widget _buildMilestoneRow(GestationTimelineItem item, {bool isLast = false}) {
    final nodeColor = item.isPassed
        ? AppColors.primary
        : item.dayOffset <= 10
        ? AppColors.danger
        : AppColors.textSecondary;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Node + connector
          SizedBox(
            width: 32,
            child: Column(
              children: [
                const SizedBox(height: 2),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: item.isPassed ? AppColors.primary : Colors.white,
                    border: Border.all(color: nodeColor, width: 2.5),
                  ),
                  child: item.isPassed
                      ? const Icon(
                          LucideIcons.check,
                          size: 12,
                          color: Colors.white,
                        )
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: item.isPassed
                          ? AppColors.primary.withValues(alpha: 0.3)
                          : AppColors.divider,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: item.isPassed
                      ? AppColors.primaryContainer
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: item.isPassed
                        ? AppColors.primary.withValues(alpha: 0.25)
                        : AppColors.divider,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'J+${item.dayOffset} — ${Formatters.formatDate(item.targetDate)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: item.isPassed
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (item.isPassed)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Fait',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- MATING CARD ---
  Widget _buildMatingCard(MatingEvent m) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.goldLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.heart,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${m.femaleId} × ${m.ramId ?? "Bélier inconnu"}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${Formatters.formatDate(m.matingDate)} • ${m.matingType}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              m.status,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- FLOATING ACTION BAR (FOND BLANC OPAQUE SANS FLOU) ---
  Widget _buildFloatingActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider),
        boxShadow: AppColors.floatingShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFabButton(
            icon: LucideIcons.baby,
            label: 'Mise bas',
            backgroundColor: AppColors.goldLight,
            textColor: AppColors.textPrimary,
            onTap: () => context.push('/reproduction/birth'),
          ),
          const SizedBox(width: 10),
          _buildFabButton(
            icon: LucideIcons.plus,
            label: 'Saillie',
            backgroundColor: AppColors.primary,
            textColor: Colors.white,
            onTap: () => context.push('/reproduction/mating'),
          ),
        ],
      ),
    );
  }

  Widget _buildFabButton({
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(icon, size: 17, color: textColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
