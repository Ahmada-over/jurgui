import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';

class Formatters {
  static final NumberFormat _cfaFormat = NumberFormat('#,###', 'fr_FR');
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy', 'fr_FR');
  static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');

  static String formatCFA(num? amount) {
    if (amount == null) return '0 FCFA';
    return '${_cfaFormat.format(amount).replaceAll(',', ' ')} FCFA';
  }

  static String formatDate(DateTime? date) {
    if (date == null) return 'Non renseignée';
    try {
      return _dateFormat.format(date);
    } catch (_) {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
  }

  static String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Non renseignée';
    try {
      return _dateTimeFormat.format(dateTime);
    } catch (_) {
      return '${formatDate(dateTime)} ${dateTime.hour}h${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  static String formatGestationDays(DateTime startDate, {int totalDays = 150}) {
    final diff = DateTime.now().difference(startDate).inDays;
    return 'J+$diff / $totalDays';
  }

  static Color getBreedColor(String? breedName) {
    if (breedName == null) return AppColors.primary;
    final name = breedName.toLowerCase();
    if (name.contains('ladoum') && !name.contains('métis')) {
      return const Color(0xFFB07D38); // Or Ladoum
    } else if (name.contains('métis')) {
      return const Color(0xFF2D6A4F); // Vert Métis
    } else if (name.contains('peulh')) {
      return const Color(0xFF6D4C41); // Ocre Peulh
    }
    return AppColors.primary;
  }

  static Color getConditionColor(String? condition) {
    switch (condition?.toLowerCase()) {
      case 'thin':
      case 'maigre':
        return AppColors.warning;
      case 'normal':
        return AppColors.success;
      case 'fat':
      case 'gras':
        return AppColors.info;
      default:
        return AppColors.textSecondary;
    }
  }

  static String translateCondition(String? condition) {
    switch (condition?.toLowerCase()) {
      case 'thin':
        return 'Maigre';
      case 'normal':
        return 'Normal';
      case 'fat':
        return 'Gras';
      default:
        return condition ?? 'Normal';
    }
  }

  static String translateReproStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'not_pregnant':
        return 'Non gestante';
      case 'suspected':
        return 'Gestation suspectée';
      case 'confirmed':
        return 'Gestation confirmée';
      case 'lactating':
        return 'Allaitante';
      case 'resting':
        return 'En repos';
      default:
        return status ?? 'Non gestante';
    }
  }
}
