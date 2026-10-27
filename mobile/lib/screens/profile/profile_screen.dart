import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/constants/colors.dart';
import '../../core/widgets/legal_documents_sheet.dart';
import '../../core/widgets/sheep_hoof_icon.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  List<Map<String, dynamic>> _teamMembers = [];
  bool _loadingTeam = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadTeamIfNeeded);
  }

  Future<void> _loadTeamIfNeeded() async {
    final user = ref.read(authProvider).user;
    final role = user?['role'] as String? ?? 'admin';
    if (role == 'admin') {
      setState(() => _loadingTeam = true);
      final members = await ref.read(authProvider.notifier).fetchTeamUsers();
      if (mounted) {
        setState(() {
          _teamMembers = members;
          _loadingTeam = false;
        });
      }
    }
  }

  String _translateRole(String? role) {
    switch (role) {
      case 'admin':
        return 'Administrateur / Propriétaire';
      case 'veterinarian':
        return 'Vétérinaire';
      case 'employee':
        return 'Employé d\'élevage';
      default:
        return 'Membre de l\'élevage';
    }
  }

  Color _getRoleBadgeColor(String? role) {
    switch (role) {
      case 'admin':
        return AppColors.gold;
      case 'veterinarian':
        return AppColors.info;
      default:
        return AppColors.primaryAccent;
    }
  }

  void _showEditProfileSheet(
    BuildContext context,
    Map<String, dynamic>? currentUser,
  ) {
    final nameCtrl = TextEditingController(
      text: currentUser?['full_name'] as String? ?? '',
    );
    final emailCtrl = TextEditingController(
      text: currentUser?['email'] as String? ?? '',
    );
    final phoneCtrl = TextEditingController(
      text: currentUser?['phone'] as String? ?? '',
    );
    final passwordCtrl = TextEditingController();
    bool obscurePassword = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: EdgeInsets.fromLTRB(
            22,
            18,
            22,
            MediaQuery.of(ctx).viewInsets.bottom + 22,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: AppColors.floatingShadow,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        LucideIcons.userPen,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Modifier mon profil',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Mettez à jour vos coordonnées et votre mot de passe',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nom complet',
                    prefixIcon: Icon(LucideIcons.user, size: 18),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Adresse email',
                    prefixIcon: Icon(LucideIcons.mail, size: 18),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Téléphone (+221...)',
                    prefixIcon: Icon(LucideIcons.phone, size: 18),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordCtrl,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Nouveau mot de passe (optionnel)',
                    prefixIcon: const Icon(LucideIcons.lockKeyhole, size: 18),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff,
                        size: 18,
                      ),
                      onPressed: () => setSheetState(
                        () => obscurePassword = !obscurePassword,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      final ok = await ref
                          .read(authProvider.notifier)
                          .updateProfile(
                            fullName: nameCtrl.text,
                            email: emailCtrl.text,
                            phone: phoneCtrl.text,
                            password: passwordCtrl.text,
                          );
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              ok
                                  ? 'Profil mis à jour avec succès'
                                  : 'Erreur lors de la mise à jour',
                            ),
                            backgroundColor: ok
                                ? AppColors.primary
                                : AppColors.danger,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        _loadTeamIfNeeded();
                      }
                    },
                    child: const Text('Enregistrer les modifications'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddTeamMemberSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    String selectedRole = 'employee';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: EdgeInsets.fromLTRB(
            22,
            18,
            22,
            MediaQuery.of(ctx).viewInsets.bottom + 22,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: AppColors.floatingShadow,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        LucideIcons.userPlus,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ajouter un collaborateur',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Employé d\'élevage ou vétérinaire',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nom complet *',
                    prefixIcon: Icon(LucideIcons.user, size: 18),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Adresse email *',
                    prefixIcon: Icon(LucideIcons.mail, size: 18),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Téléphone (+221...)',
                    prefixIcon: Icon(LucideIcons.phone, size: 18),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Fonction dans l\'élevage',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildRoleChip(
                      label: 'Employé',
                      value: 'employee',
                      groupValue: selectedRole,
                      icon: LucideIcons.userCheck,
                      onSelect: (v) => setSheetState(() => selectedRole = v),
                    ),
                    const SizedBox(width: 8),
                    _buildRoleChip(
                      label: 'Vétérinaire',
                      value: 'veterinarian',
                      groupValue: selectedRole,
                      icon: LucideIcons.stethoscope,
                      onSelect: (v) => setSheetState(() => selectedRole = v),
                    ),
                    const SizedBox(width: 8),
                    _buildRoleChip(
                      label: 'Admin',
                      value: 'admin',
                      groupValue: selectedRole,
                      icon: LucideIcons.shieldCheck,
                      onSelect: (v) => setSheetState(() => selectedRole = v),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: passwordCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Mot de passe initial *',
                    prefixIcon: Icon(LucideIcons.lockKeyhole, size: 18),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameCtrl.text.trim().isEmpty ||
                          emailCtrl.text.trim().isEmpty ||
                          passwordCtrl.text.isEmpty) {
                        return;
                      }
                      final ok = await ref
                          .read(authProvider.notifier)
                          .createTeamMember(
                            fullName: nameCtrl.text,
                            email: emailCtrl.text,
                            password: passwordCtrl.text,
                            role: selectedRole,
                            phone: phoneCtrl.text,
                          );
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      if (ok) {
                        _loadTeamIfNeeded();
                      }
                    },
                    child: const Text('Créer le compte collaborateur'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleChip({
    required String label,
    required String value,
    required String groupValue,
    required IconData icon,
    required ValueChanged<String> onSelect,
  }) {
    final isSelected = value == groupValue;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelect(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryContainer
                : AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.divider,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final dashboardAsync = ref.watch(dashboardProvider);
    final user = authState.user;
    final fullName = user?['full_name'] as String? ?? 'Administrateur';
    final email = user?['email'] as String? ?? 'admin@jurgui.sn';
    final phone = user?['phone'] as String?;
    final role = user?['role'] as String? ?? 'admin';
    final isAdmin = role == 'admin';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Mon Profil')),
      body: RefreshIndicator(
        color: AppColors.primaryAccent,
        onRefresh: () async {
          await ref.read(authProvider.notifier).checkAuth();
          await _loadTeamIfNeeded();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. HERO PRESTIGE CARD
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppColors.heroGradient,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: AppColors.floatingShadow,
                ),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3.5),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.goldGradient,
                          ),
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: AppColors.primary,
                            child: Text(
                              fullName.isNotEmpty
                                  ? fullName[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _showEditProfileSheet(context, user),
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: AppColors.gold,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              LucideIcons.pencil,
                              size: 13,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      fullName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.goldLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.award,
                            size: 15,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _translateRole(role),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Quick stats inside Hero
                    dashboardAsync.maybeWhen(
                      data: (d) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildMiniMetric(
                              '${d.totalActiveAnimals}',
                              'Ovins actifs',
                            ),
                            Container(
                              height: 24,
                              width: 1,
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                            _buildMiniMetric(
                              '${d.sectors.length}',
                              'Secteurs',
                            ),
                            Container(
                              height: 24,
                              width: 1,
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                            _buildMiniMetric(
                              '${d.activePregnancies}',
                              'Gestations',
                            ),
                          ],
                        ),
                      ),
                      orElse: () => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 2. INFORMATIONS PERSONNELLES & MODIFICATION
              Container(
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
                          'Coordonnées personnelles',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _showEditProfileSheet(context, user),
                          icon: const Icon(LucideIcons.pencil, size: 15),
                          label: const Text(
                            'Modifier',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      icon: LucideIcons.user,
                      label: 'Nom complet',
                      value: fullName,
                    ),
                    const Divider(height: 22, color: AppColors.divider),
                    _buildInfoRow(
                      icon: LucideIcons.mail,
                      label: 'Adresse email',
                      value: email,
                    ),
                    const Divider(height: 22, color: AppColors.divider),
                    _buildInfoRow(
                      icon: LucideIcons.phone,
                      label: 'Téléphone',
                      value: phone != null && phone.isNotEmpty
                          ? phone
                          : 'Non renseigné (+221...)',
                    ),
                    const Divider(height: 22, color: AppColors.divider),
                    _buildInfoRow(
                      icon: LucideIcons.shieldCheck,
                      label: 'Droits d\'accès',
                      value: _translateRole(role),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 3. FICHE D'EXPLOITATION (DAKAR)
              Container(
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
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const SheepHoofIcon(
                            size: 20,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bergerie Jur-gui — Dakar',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                'Paramètres de l\'exploitation ovine',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      icon: LucideIcons.mapPin,
                      label: 'Zone d\'exploitation',
                      value: 'Dakar, Sénégal',
                    ),
                    const Divider(height: 22, color: AppColors.divider),
                    _buildInfoRow(
                      icon: LucideIcons.dna,
                      label: 'Races sélectionnées',
                      value: 'Ladoum • Métis Ladoum • Peulh Peulh',
                    ),
                    const Divider(height: 22, color: AppColors.divider),
                    _buildInfoRow(
                      icon: LucideIcons.calendarClock,
                      label: 'Cycle de gestation de référence',
                      value: '150 jours (jalons J+90 à J+150)',
                    ),
                    const Divider(height: 22, color: AppColors.divider),
                    _buildInfoRow(
                      icon: LucideIcons.banknote,
                      label: 'Devise de gestion',
                      value: 'Franc CFA (FCFA)',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 4. ÉQUIPE DE L'ÉLEVAGE (ADMIN UNIQUEMENT)
              if (isAdmin) ...[
                Container(
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
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Équipe de l\'élevage',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Comptes employés & vétérinaires',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          FilledButton.tonalIcon(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primaryContainer,
                              foregroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => _showAddTeamMemberSheet(context),
                            icon: const Icon(LucideIcons.userPlus, size: 16),
                            label: const Text(
                              'Ajouter',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (_loadingTeam)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primaryAccent,
                            ),
                          ),
                        )
                      else if (_teamMembers.isEmpty)
                        const Text(
                          'Aucun collaborateur enregistré.',
                          style: TextStyle(color: AppColors.textSecondary),
                        )
                      else
                        ..._teamMembers.map((m) {
                          final mName =
                              m['full_name'] as String? ?? 'Collaborateur';
                          final mEmail = m['email'] as String? ?? '';
                          final mRole = m['role'] as String? ?? 'employee';
                          final badgeColor = _getRoleBadgeColor(mRole);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: AppColors.primaryContainer,
                                  child: Text(
                                    mName.isNotEmpty
                                        ? mName[0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        mName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        mEmail,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
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
                                    color: badgeColor.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    mRole == 'admin'
                                        ? 'Admin'
                                        : mRole == 'veterinarian'
                                        ? 'Vétérinaire'
                                        : 'Employé',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: mRole == 'admin'
                                          ? AppColors.goldDark
                                          : badgeColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // 5. MENTIONS LÉGALES & CONFIDENTIALITÉ
              Container(
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
                      'Informations légales',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () =>
                          showLegalDocumentSheet(context, LegalDocType.terms),
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                LucideIcons.fileText,
                                size: 18,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Conditions Générales d\'Utilisation',
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Règles d\'accès et d\'usage de la plateforme Jur-gui',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              LucideIcons.chevronRight,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 18, color: AppColors.divider),
                    InkWell(
                      onTap: () =>
                          showLegalDocumentSheet(context, LegalDocType.privacy),
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.goldLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                LucideIcons.shieldCheck,
                                size: 18,
                                color: AppColors.goldDark,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Politique de Confidentialité',
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Protection des données personnelles et de l\'élevage',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              LucideIcons.chevronRight,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 6. BOUTON DE DÉCONNEXION
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: BorderSide(
                      color: AppColors.danger.withValues(alpha: 0.4),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    backgroundColor: Colors.white,
                  ),
                  icon: const Icon(LucideIcons.logOut, size: 18),
                  label: const Text(
                    'Se déconnecter',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  onPressed: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniMetric(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
