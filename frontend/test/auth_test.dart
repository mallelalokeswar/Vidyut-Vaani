import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidyut_vaani/core/constants/app_constants.dart';
import 'package:vidyut_vaani/core/models/app_user.dart';
import 'package:vidyut_vaani/core/theme/app_theme.dart';
import 'package:vidyut_vaani/features/auth/providers/auth_provider.dart';
import 'package:vidyut_vaani/features/auth/screens/login_screen.dart';
import 'package:vidyut_vaani/routing/app_router.dart';

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(AuthState initial) : super() {
    state = initial;
  }
}

void main() {
  group('UserRole model', () {
    test('maps roles to expected dashboard routes', () {
      expect(UserRole.citizen.dashboardRoute, '/citizen/dashboard');
      expect(UserRole.admin.dashboardRoute, '/admin/dashboard');
      expect(UserRole.operator.dashboardRoute, '/operator/dashboard');
    });

    test('fromString throws on unknown role', () {
      expect(() => UserRole.fromString('superuser'), throwsArgumentError);
    });
  });

  group('LoginScreen widget tests', () {
    testWidgets('renders VidyuthVaani branding, role cards, and form fields',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(
              (_) => _FakeAuthNotifier(
                const AuthState(status: AuthStatus.unauthenticated),
              ),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.dark,
            home: const LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('VidyuthVaani'), findsOneWidget);
      expect(find.text('Citizen'), findsOneWidget);
      expect(find.text('Admin'), findsOneWidget);
      expect(find.text('Operator'), findsOneWidget);
      expect(find.text('Email or Username'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.text('Create Citizen Account'), findsOneWidget);
    });

    testWidgets('shows validation errors on empty submit', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(
              (_) => _FakeAuthNotifier(
                const AuthState(status: AuthStatus.unauthenticated),
              ),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.dark,
            home: const LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final loginBtn = find.text('Login');
      await tester.ensureVisible(loginBtn);
      await tester.tap(loginBtn);
      await tester.pump();

      expect(find.text('Email or username is required.'), findsOneWidget);
      expect(find.text('Password is required.'), findsOneWidget);
    });

    testWidgets('toggles password visibility', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(
              (_) => _FakeAuthNotifier(
                const AuthState(status: AuthStatus.unauthenticated),
              ),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.dark,
            home: const LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pump();
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    });
  });

  group('Route guards', () {
    testWidgets('unauthenticated user is redirected from protected route to /login',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(
            (_) => _FakeAuthNotifier(
              const AuthState(status: AuthStatus.unauthenticated),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.dark,
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      router.go(AppConstants.routeAdminDashboard);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        AppConstants.routeLogin,
      );
    });

    testWidgets('citizen is redirected away from /admin/dashboard to /citizen/dashboard',
        (tester) async {
      const citizen = AppUser(
        id: 1,
        fullName: 'Test Citizen',
        email: 'citizen@test.com',
        username: 'citizen1',
        role: UserRole.citizen,
        status: 'active',
      );
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(
            (_) => _FakeAuthNotifier(
              const AuthState(
                status: AuthStatus.authenticated,
                user: citizen,
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.dark,
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      router.go(AppConstants.routeAdminDashboard);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        AppConstants.routeCitizenDashboard,
      );
    });

    testWidgets('operator is redirected away from /admin/dashboard to /operator/dashboard',
        (tester) async {
      const op = AppUser(
        id: 2,
        fullName: 'Field Operator',
        email: 'op@test.com',
        username: 'op1',
        role: UserRole.operator,
        status: 'active',
      );
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(
            (_) => _FakeAuthNotifier(
              const AuthState(
                status: AuthStatus.authenticated,
                user: op,
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.dark,
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      router.go(AppConstants.routeAdminDashboard);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        AppConstants.routeOperatorDashboard,
      );
    });

    testWidgets('logout redirects authenticated user back to /login',
        (tester) async {
      const admin = AppUser(
        id: 3,
        fullName: 'Admin User',
        email: 'admin@test.com',
        username: 'admin1',
        role: UserRole.admin,
        status: 'active',
      );
      final fakeNotifier = _FakeAuthNotifier(
        const AuthState(
          status: AuthStatus.authenticated,
          user: admin,
        ),
      );
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((_) => fakeNotifier),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.dark,
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        AppConstants.routeAdminDashboard,
      );

      // Simulate logout
      fakeNotifier.state = const AuthState(status: AuthStatus.unauthenticated);
      await tester.pumpAndSettle();

      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        AppConstants.routeLogin,
      );
    });
  });
}
