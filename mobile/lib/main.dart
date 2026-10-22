import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';

import 'screens/auth/login_screen.dart';
import 'screens/navigation/main_navigation_shell.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/animals/animals_list_screen.dart';
import 'screens/animals/animal_detail_screen.dart';
import 'screens/animals/add_animal_screen.dart';
import 'screens/reproduction/reproduction_screen.dart';
import 'screens/reproduction/add_mating_screen.dart';
import 'screens/reproduction/record_birth_screen.dart';
import 'screens/feed_stock/feed_stock_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: JurguiApp(),
    ),
  );
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/dashboard',
    redirect: (context, state) {
      if (authState.isLoading) return null;
      final isLoggingIn = state.matchedLocation == '/login';
      if (!authState.isAuthenticated && !isLoggingIn) {
        return '/login';
      }
      if (authState.isAuthenticated && isLoggingIn) {
        return '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainNavigationShell(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Dashboard
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          // Branch 1: Cheptel
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/animals',
                builder: (context, state) => const AnimalsListScreen(),
              ),
            ],
          ),
          // Branch 2: Reproduction
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reproduction',
                builder: (context, state) => const ReproductionScreen(),
              ),
            ],
          ),
          // Branch 3: Stocks & Aliments
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/feed',
                builder: (context, state) => const FeedStockScreen(),
              ),
            ],
          ),
        ],
      ),
      // Sub-routes outside BottomBar
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/animals/add',
        builder: (context, state) => const AddAnimalScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/animals/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return AnimalDetailScreen(animalId: id);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/reproduction/mating',
        builder: (context, state) => const AddMatingScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/reproduction/birth',
        builder: (context, state) => const RecordBirthScreen(),
      ),
    ],
  );
});

class JurguiApp extends ConsumerWidget {
  const JurguiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Jur-gui — Élevage Ovin Dakar',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
