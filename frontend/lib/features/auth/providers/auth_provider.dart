import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vidyut_vaani/core/models/app_user.dart';
import 'package:vidyut_vaani/core/services/auth_api_service.dart';
import 'package:vidyut_vaani/core/services/secure_auth_storage.dart';

// ---------------------------------------------------------------------------
// Auth state
// ---------------------------------------------------------------------------
enum AuthStatus { loading, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final AppUser? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.loading,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({AuthStatus? status, AppUser? user, String? errorMessage}) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

// ---------------------------------------------------------------------------
// Auth Notifier
// ---------------------------------------------------------------------------
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _init();
  }

  final _api = AuthApiService.instance;
  final _storage = SecureAuthStorage.instance;

  /// Called at app launch — restores session from secure storage.
  Future<void> _init() async {
    try {
      final storedUser = await _storage.getUser();
      final accessToken = await _storage.getAccessToken();
      if (storedUser != null && accessToken != null) {
        // Try to refresh the access token to verify it is still valid
        final refreshedUser = await _api.refreshSession();
        if (refreshedUser != null) {
          state = AuthState(status: AuthStatus.authenticated, user: refreshedUser);
          return;
        }
      }
    } catch (_) {
      // Fall through to unauthenticated
    }
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> login({
    required String identifier,
    required String password,
    required String role,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _api.login(
        identifier: identifier,
        password: password,
        role: role,
      );
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> logout() async {
    await _api.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (_) => AuthNotifier(),
);

/// Convenience provider — the authenticated user or null.
final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authProvider).user;
});
