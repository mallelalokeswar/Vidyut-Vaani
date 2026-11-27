import 'package:vidyut_vaani/core/models/app_user.dart';
import 'package:vidyut_vaani/core/services/api_client.dart';
import 'package:vidyut_vaani/core/services/secure_auth_storage.dart';

class AuthApiService {
  AuthApiService._();
  static final AuthApiService instance = AuthApiService._();

  final _client = ApiClient.instance;
  final _storage = SecureAuthStorage.instance;

  /// Login — always pass the role selected on-screen.
  /// The backend verifies it matches the stored role.
  Future<AppUser> login({
    required String identifier,
    required String password,
    required String role,
  }) async {
    final data = await _client.post(
      '/auth/login',
      {'identifier': identifier, 'password': password, 'role': role},
      withAuth: false,
    );
    final user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
    await _storage.saveTokens(
      accessToken: data['access_token'] as String,
      refreshToken: data['refresh_token'] as String,
    );
    await _storage.saveUser(user);
    return user;
  }

  Future<AppUser> register({
    required String fullName,
    required String email,
    required String username,
    required String password,
    String? phone,
    String? locality,
    String? meterNumber,
  }) async {
    final data = await _client.post(
      '/auth/register',
      {
        'full_name': fullName,
        'email': email,
        'username': username,
        'password': password,
        if (phone != null) 'phone': phone,
        if (locality != null) 'locality': locality,
        if (meterNumber != null) 'meter_number': meterNumber,
      },
      withAuth: false,
    );
    return AppUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<void> logout() async {
    try {
      await _client.delete('/auth/logout');
    } catch (_) {
      // Even if the server call fails, clear local storage
    } finally {
      await _storage.clearAll();
    }
  }

  Future<AppUser?> refreshSession() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null) return null;

      final resp = await _client.post(
        '/auth/refresh',
        {},
        bearerToken: refreshToken,
      );
      await _storage.saveTokens(
        accessToken: resp['access_token'] as String,
        refreshToken: refreshToken,
      );
      return _storage.getUser();
    } catch (_) {
      await _storage.clearAll();
      return null;
    }
  }

  Future<void> forgotPassword(String email) async {
    await _client.post('/auth/forgot-password', {'email': email}, withAuth: false);
  }
}
