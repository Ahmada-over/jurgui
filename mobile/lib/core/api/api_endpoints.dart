import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

class ApiEndpoints {
  /// URL de production GCP Cloud Run (peut aussi être surchargée au build via
  /// `--dart-define=API_BASE_URL=https://jurgui-api-xxx.a.run.app/api/v1`)
  static const String _envBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  /// Remplacer par l'URL exacte de ton service Cloud Run déployé sur GCP :
  static const String cloudRunBaseUrl =
      'https://jurgui-api-REMPLACER.europe-west1.run.app/api/v1';

  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) {
      return _envBaseUrl;
    }
    // En mode release (Play Store / APK sur téléphone) ou si l'URL Cloud Run est renseignée
    if (kReleaseMode || !cloudRunBaseUrl.contains('REMPLACER')) {
      return cloudRunBaseUrl;
    }
    if (kIsWeb) {
      return 'http://127.0.0.1:8002/api/v1';
    }
    try {
      if (Platform.isAndroid) {
        // Standard Android emulator loopback
        return 'http://10.0.2.2:8002/api/v1';
      }
    } catch (_) {}
    return 'http://127.0.0.1:8002/api/v1';
  }

  // Auth
  static const String login = '/auth/login';
  static const String me = '/auth/me';

  // Cheptel
  static const String breeds = '/breeds';
  static const String sectors = '/sectors';
  static const String animals = '/animals';

  // Reproduction
  static const String matings = '/reproduction/matings';
  static const String pregnancies = '/reproduction/pregnancies';
  static const String births = '/reproduction/births';

  // Nutrition & Stocks
  static const String feedProducts = '/feed/products';
  static const String feedRations = '/feed/rations';
  static const String stockMovements = '/feed/movements';

  // Health
  static const String healthObservations = '/health/observations';
  static const String vaccinations = '/health/vaccinations';
  static const String hygieneTasks = '/health/hygiene';

  // Dashboard & Tasks
  static const String dashboard = '/dashboard/overview';
  static const String tasks = '/tasks';
  static const String notifications = '/tasks/notifications';
  static const String financesSummary = '/finances/summary';
}
