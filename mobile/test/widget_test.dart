import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/main.dart';
import 'package:mobile/providers/auth_provider.dart';

class MockAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => AuthState(isAuthenticated: false, isLoading: false);
}

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(() => MockAuthNotifier()),
        ],
        child: const JurguiApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Jur-gui'), findsOneWidget);
  });
}
