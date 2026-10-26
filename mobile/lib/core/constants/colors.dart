import 'package:flutter/material.dart';

class AppColors {
  // --- PALETTE ÉLEVAGE INTELLIGENT 2026 ---
  // Vert Forêt Prestige (Agritech & Élevage d'Élite)
  static const Color primary = Color(0xFF0D3B2E);
  static const Color primaryLight = Color(0xFF1B5E4B);
  static const Color primaryAccent = Color(0xFF10B981); // Émeraude vive 2026
  static const Color primaryContainer = Color(0xFFE8F5EE);

  // Or & Champagne Ladoum (Symbole de prestige des ovins Ladoum à Dakar)
  static const Color gold = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFF9F3DC);
  static const Color goldDark = Color(0xFFA68018);
  static const Color secondary = gold;
  static const Color secondaryContainer = goldLight;

  // Surfaces & Fond
  static const Color background = Color(0xFFF6F8F6);
  static const Color surface = Colors.white;
  static const Color cardBg = Colors.white;
  static const Color darkCard = Color(0xFF11261F);

  // Statuts & Indicateurs vifs 2026
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Textes & Éléments neutres
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color divider = Color(0xFFE2E8F0);
  static const Color inputBorder = Color(0xFFE2E8F0);
  static const Color inputFill = Color(0xFFF8FAFC);

  // Dégradés 2026
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF092920), Color(0xFF134E3C), Color(0xFF1C6750)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE5C365), Color(0xFFD4AF37), Color(0xFFB88E1C)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.white, Color(0xFFFAFCFA)],
  );

  // Ombres douces teintées 2026
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: const Color(0xFF0D3B2E).withValues(alpha: 0.05),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.02),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get floatingShadow => [
        BoxShadow(
          color: const Color(0xFF0D3B2E).withValues(alpha: 0.12),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ];

  static List<BoxShadow> get glowGold => [
        BoxShadow(
          color: gold.withValues(alpha: 0.3),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ];
}
