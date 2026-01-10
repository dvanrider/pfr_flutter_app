import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers/auth_providers.dart';
import 'providers/user_management_providers.dart';
import 'providers/role_permissions_provider.dart';
import 'providers/theme_provider.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/project_list/project_list_screen.dart';
import 'presentation/screens/project_input/project_input_screen.dart';
import 'presentation/screens/analysis_dashboard/analysis_dashboard_screen.dart';
import 'presentation/screens/financial_input/financial_input_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/help/training_screen.dart';
import 'presentation/screens/help/metrics_screen.dart';
import 'presentation/screens/admin/admin_screen.dart';
import 'presentation/screens/executive/executive_dashboard_screen.dart';
import 'presentation/screens/analysis/project_comparison_screen.dart';
import 'presentation/screens/analysis/sensitivity_analysis_screen.dart';
import 'presentation/screens/analysis/risk_assessment_screen.dart';

/// Router provider that reacts to auth state changes
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final appUser = ref.watch(currentAppUserProvider);
  final canViewExecDashboard = ref.watch(canViewExecutiveDashboardPermProvider);
  final canViewAllProjects = ref.watch(canViewAllProjectsProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: RouterRefreshStream(ref),
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isLoggingIn = state.matchedLocation == '/login';
      final isGoingHome = state.matchedLocation == '/';
      final isGoingExecutive = state.matchedLocation == '/executive';
      final isGoingAnalysis = state.matchedLocation.startsWith('/analysis');

      // If not logged in and not on login page, redirect to login
      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }

      // If logged in and on login page, redirect appropriately
      if (isLoggedIn && isLoggingIn) {
        // Check if user is executive (by role, not permission - this is for UX)
        final user = appUser.valueOrNull;
        if (user?.role == UserRole.executive) {
          return '/executive';
        }
        return '/';
      }

      // Redirect executives to their dashboard when going to home
      if (isLoggedIn && isGoingHome) {
        final user = appUser.valueOrNull;
        if (user?.role == UserRole.executive) {
          return '/executive';
        }
      }

      // Protect executive dashboard with permission check
      // Also allow SuperUser, Admin, and Executive roles directly
      if (isGoingExecutive) {
        final user = appUser.valueOrNull;
        final canAccess = user?.role == UserRole.superUser ||
            user?.role == UserRole.admin ||
            user?.role == UserRole.executive ||
            canViewExecDashboard;
        if (!canAccess) {
          return '/';
        }
      }

      // Protect analysis tools with viewAllProjects permission
      // Also allow SuperUser, Admin, and Executive roles directly
      if (isGoingAnalysis) {
        final user = appUser.valueOrNull;
        final canAccess = user?.role == UserRole.superUser ||
            user?.role == UserRole.admin ||
            user?.role == UserRole.executive ||
            canViewAllProjects;
        if (!canAccess) {
          return '/';
        }
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
      GoRoute(
        path: '/admin',
        name: 'admin',
        builder: (context, state) => const AdminScreen(),
      ),
      GoRoute(
        path: '/executive',
        name: 'executive',
        builder: (context, state) => const ExecutiveDashboardScreen(),
      ),
      GoRoute(
        path: '/analysis/compare',
        name: 'project-comparison',
        builder: (context, state) => const ProjectComparisonScreen(),
      ),
      GoRoute(
        path: '/analysis/sensitivity',
        name: 'sensitivity-analysis',
        builder: (context, state) {
          final projectId = state.uri.queryParameters['projectId'];
          return SensitivityAnalysisScreen(projectId: projectId);
        },
      ),
      GoRoute(
        path: '/analysis/risk',
        name: 'risk-assessment',
        builder: (context, state) {
          final projectId = state.uri.queryParameters['projectId'];
          return RiskAssessmentScreen(projectId: projectId);
        },
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
    final lightTheme = ref.watch(lightThemeProvider);
    final darkTheme = ref.watch(darkThemeProvider);
    final themeMode = ref.watch(resolvedThemeModeProvider);

    return MaterialApp.router(
      title: 'Project Funding Request',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
