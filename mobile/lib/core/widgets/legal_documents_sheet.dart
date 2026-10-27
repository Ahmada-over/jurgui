import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../constants/colors.dart';

enum LegalDocType { terms, privacy }

void showLegalDocumentSheet(BuildContext context, LegalDocType initialType) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollController) => _LegalDocumentContent(
        initialType: initialType,
        scrollController: scrollController,
      ),
    ),
  );
}

class _LegalDocumentContent extends StatefulWidget {
  final LegalDocType initialType;
  final ScrollController scrollController;

  const _LegalDocumentContent({
    required this.initialType,
    required this.scrollController,
  });

  @override
  State<_LegalDocumentContent> createState() => _LegalDocumentContentState();
}

class _LegalDocumentContentState extends State<_LegalDocumentContent> {
  late LegalDocType _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
  }

  @override
  Widget build(BuildContext context) {
    final isTerms = _selectedType == LegalDocType.terms;

    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isTerms ? LucideIcons.fileText : LucideIcons.shieldCheck,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isTerms
                            ? 'Conditions Générales d\'Utilisation'
                            : 'Politique de Confidentialité',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Text(
                        'Plateforme Jur-gui — Élevage Ovin (Dakar, Sénégal)',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(LucideIcons.x, size: 20),
                ),
              ],
            ),
          ),
          // Onglets CGU / Confidentialité
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _selectedType = LegalDocType.terms),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isTerms ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Conditions (CGU)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isTerms
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _selectedType = LegalDocType.privacy),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color:
                              !isTerms ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Confidentialité',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: !isTerms
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.divider),
          Expanded(
            child: ListView(
              controller: widget.scrollController,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              children: isTerms ? _buildTermsSections() : _buildPrivacySections(),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTermsSections() {
    return const [
      _LegalSection(
        title: '1. Objet de l\'application Jur-gui',
        body:
            'Jur-gui est une application professionnelle de gestion de cheptel ovin (races Ladoum, Métis Ladoum, Peulh Peulh et autres races ovines) destinée aux éleveurs, bergers et vétérinaires. Elle permet le suivi individuel des animaux, de la généalogie, des pesées, des enclos, des saillies, des gestations et des mises bas.',
      ),
      _LegalSection(
        title: '2. Accès et création de compte',
        body:
            'L\'accès à l\'application nécessite la création d\'un compte utilisateur (Propriétaire/Administrateur, Vétérinaire ou Employé d\'élevage). L\'utilisateur s\'engage à fournir des informations exactes et à conserver la confidentialité de ses identifiants de connexion.',
      ),
      _LegalSection(
        title: '3. Utilisation et responsabilité métier',
        body:
            'Les indicateurs, comptes à rebours de gestation (cycle indicatif de 150 jours) et alertes affichés dans Jur-gui constituent des outils d\'aide au suivi d\'exploitation. Ils ne remplacent en aucun cas le diagnostic, la prescription ou l\'intervention d\'un docteur vétérinaire agréé.',
      ),
      _LegalSection(
        title: '4. Propriété des données de l\'élevage',
        body:
            'L\'éleveur conserve l\'entière propriété des données saisies concernant son cheptel (fiches animales, photographies, généalogie, historique de reproduction et de croissance).',
      ),
      _LegalSection(
        title: '5. Disponibilité et sécurité',
        body:
            'Nous mettons en œuvre les meilleures pratiques techniques pour assurer la disponibilité continue du service et la sauvegarde sécurisée des données de la bergerie. Toute utilisation frauduleuse ou tentative d\'accès non autorisé entraînera la suspension du compte.',
      ),
      _LegalSection(
        title: '6. Droit applicable et contact',
        body:
            'Les présentes Conditions Générales d\'Utilisation sont régies par le droit sénégalais. Pour toute question relative au service : support@jurgui.sn.',
      ),
    ];
  }

  List<Widget> _buildPrivacySections() {
    return const [
      _LegalSection(
        title: '1. Données collectées',
        body:
            'Dans le cadre du fonctionnement de Jur-gui, seules les données strictement nécessaires à la gestion de votre élevage sont collectées :\n'
            '• Données de compte : nom complet, adresse email, numéro de téléphone professionnel et rôle dans l\'élevage.\n'
            '• Données d\'exploitation : fiches d\'identification des ovins, photographies des animaux, pesées, généalogie et événements de reproduction.',
      ),
      _LegalSection(
        title: '2. Utilisation de l\'appareil photo et de la galerie',
        body:
            'L\'accès à l\'appareil photo ou à la photothèque du téléphone est utilisé exclusivement lorsque vous choisissez d\'associer une photo d\'identification à la fiche d\'un ovin. Aucune photo n\'est collectée en arrière-plan.',
      ),
      _LegalSection(
        title: '3. Hébergement et sécurité des données',
        body:
            'Les mots de passe sont hachés de manière irréversible (bcrypt). Les échanges entre l\'application mobile et le serveur sont chiffrés via HTTPS/TLS, et la base de données PostgreSQL est protégée par authentification et chiffrement SSL.',
      ),
      _LegalSection(
        title: '4. Absence de partage ou de revente',
        body:
            'Vos données personnelles ainsi que les données généalogiques et zootechniques de votre bergerie sont strictement confidentielles. Elles ne sont ni vendues, ni louées, ni cédées à des tiers publicitaires.',
      ),
      _LegalSection(
        title: '5. Vos droits (Accès, Modification, Suppression)',
        body:
            'Conformément à la réglementation sur la protection des données personnelles (Loi n° 2008-12 au Sénégal / principes RGPD), vous pouvez à tout moment modifier vos informations depuis l\'onglet « Profil » ou demander la suppression complète de votre compte et de vos données à l\'adresse : support@jurgui.sn.',
      ),
    ];
  }
}

class _LegalSection extends StatelessWidget {
  final String title;
  final String body;

  const _LegalSection({
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
