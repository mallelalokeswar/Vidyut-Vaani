import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vidyut_vaani/core/constants/app_constants.dart';
import 'package:vidyut_vaani/core/models/app_user.dart';
import 'package:vidyut_vaani/features/auth/providers/auth_provider.dart';
import 'package:vidyut_vaani/features/auth/screens/login_screen.dart';
import 'package:vidyut_vaani/features/auth/screens/register_screen.dart';
import 'package:vidyut_vaani/features/auth/screens/forgot_password_screen.dart';
import 'package:vidyut_vaani/features/auth/screens/splash_screen.dart';
import 'package:vidyut_vaani/features/citizen/screens/citizen_dashboard_screen.dart';
import 'package:vidyut_vaani/features/admin/screens/admin_dashboard_screen.dart';
import 'package:vidyut_vaani/features/operator/screens/operator_dashboard_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppConstants.routeSplash,
    refreshListenable: GoRouterRefreshStream(
      ref.watch(authProvider.notifier).stream,
    ),
    redirect: (BuildContext context, GoRouterState state) {
      final authState = ref.read(authProvider);
      final location = state.matchedLocation;

      // Show splash while checking session
      if (authState.status == AuthStatus.loading) {
        return location == AppConstants.routeSplash ? null : AppConstants.routeSplash;
      }

      final isAuthenticated = authState.status == AuthStatus.authenticated;
      final user = authState.user;

      // Public routes
      final isPublic = [
        AppConstants.routeLogin,
        AppConstants.routeRegister,
        AppConstants.routeForgotPassword,
      ].contains(location);

      // Unauthenticated users must always go to login (including from splash)
      if (!isAuthenticated) {
        return isPublic ? null : AppConstants.routeLogin;
      }

      if (user != null) {
        // Redirect from auth pages or splash to the verified role dashboard
        if (isPublic || location == AppConstants.routeSplash) {
          return user.role.dashboardRoute;
        }

        // Prevent cross-role access
        if (location.startsWith('/citizen') && user.role != UserRole.citizen) {
          return user.role.dashboardRoute;
        }
        if (location.startsWith('/admin') && user.role != UserRole.admin) {
          return user.role.dashboardRoute;
        }
        if (location.startsWith('/operator') && user.role != UserRole.operator) {
          return user.role.dashboardRoute;
        }
      }

      return null; // No redirect
    },
    routes: [
      GoRoute(
        path: AppConstants.routeSplash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppConstants.routeLogin,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppConstants.routeRegister,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppConstants.routeForgotPassword,
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppConstants.routeCitizenDashboard,
        builder: (_, __) => const CitizenDashboardScreen(),
      ),
      GoRoute(
        path: AppConstants.routeAdminDashboard,
        builder: (_, __) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: AppConstants.routeOperatorDashboard,
        builder: (_, __) => const OperatorDashboardScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
});

/// Bridges a [Stream] to [Listenable] for GoRouter refresh.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _sub = stream.listen((_) => notifyListeners());
  }

  late final dynamic _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
