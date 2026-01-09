import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers/auth_providers.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/project_list/project_list_screen.dart';
import 'presentation/screens/project_input/project_input_screen.dart';
import 'presentation/screens/analysis_dashboard/analysis_dashboard_screen.dart';
import 'presentation/screens/financial_input/financial_input_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/help/training_screen.dart';
import 'presentation/screens/help/metrics_screen.dart';

/// Router provider that reacts to auth state changes
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: RouterRefreshStream(ref),
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isLoggingIn = state.matchedLocation == '/login';

      // If not logged in and not on login page, redirect to login
      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }

      // If logged in and on login page, redirect to home
      if (isLoggedIn && isLoggingIn) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/projects',
        name: 'projects',
        builder: (context, state) => const ProjectListScreen(),
      ),
      GoRoute(
        path: '/project/new',
        name: 'new-project',
        builder: (context, state) => const ProjectInputScreen(),
      ),
      GoRoute(
        path: '/project/:id',
        name: 'project-detail',
        builder: (context, state) {
          final projectId = state.pathParameters['id']!;
          return ProjectInputScreen(projectId: projectId);
        },
      ),
      GoRoute(
        path: '/project/:id/analysis',
        name: 'analysis',
        builder: (context, state) {
          final projectId = state.pathParameters['id']!;
          return AnalysisDashboardScreen(projectId: projectId);
        },
      ),
      GoRoute(
        path: '/project/:id/financials',
        name: 'financials',
        builder: (context, state) {
          final projectId = state.pathParameters['id']!;
          return FinancialInputScreen(projectId: projectId);
        },
      ),
      GoRoute(
        path: '/help/training',
        name: 'training',
        builder: (context, state) => const TrainingScreen(),
      ),
      GoRoute(
        path: '/help/metrics',
        name: 'metrics',
        builder: (context, state) => const MetricsScreen(),
      ),
    ],
  );
});

/// Listenable that notifies router when auth state changes
class RouterRefreshStream extends ChangeNotifier {
  RouterRefreshStream(this._ref) {
    _ref.listen(authStateProvider, (_, __) {
      notifyListeners();
    });
  }

  final Ref _ref;
}

/// Main App Widget
class PFRApp extends ConsumerWidget {
  const PFRApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Project Funding Request',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      routerConfig: router,
    );
  }

  ThemeData _buildTheme() {
    const primaryColor = Color(0xFF1E3A5F); // Corporate blue
    const secondaryColor = Color(0xFF4A90A4);
    const accentColor = Color(0xFF2ECC71);

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(Colors.grey[100]),
        dividerThickness: 1,
      ),
    );
  }
}
