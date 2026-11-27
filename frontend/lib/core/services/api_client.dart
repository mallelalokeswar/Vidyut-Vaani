import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vidyut_vaani/core/constants/app_constants.dart';
import 'package:vidyut_vaani/core/services/secure_auth_storage.dart';

/// Exception with a user-friendly message from the API.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// HTTP client wrapper that injects the JWT and handles 401 refresh.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  final _storage = SecureAuthStorage.instance;

  Future<Map<String, String>> _headers({
    bool withAuth = true,
    String? bearerToken,
  }) async {
    final headers = {'Content-Type': 'application/json'};
    if (withAuth) {
      final token = bearerToken ?? await _storage.getAccessToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<Map<String, dynamic>> get(String path) async {
    final resp = await http.get(
      Uri.parse('${AppConstants.baseUrl}$path'),
      headers: await _headers(),
    );
    return _handleResponse(resp);
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    bool withAuth = true,
    String? bearerToken,
  }) async {
    final resp = await http.post(
      Uri.parse('${AppConstants.baseUrl}$path'),
      headers: await _headers(withAuth: withAuth, bearerToken: bearerToken),
      body: jsonEncode(body),
    );
    return _handleResponse(resp);
  }

  Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body) async {
    final resp = await http.patch(
      Uri.parse('${AppConstants.baseUrl}$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _handleResponse(resp);
  }

  Future<Map<String, dynamic>> delete(String path) async {
    final resp = await http.delete(
      Uri.parse('${AppConstants.baseUrl}$path'),
      headers: await _headers(),
    );
    return _handleResponse(resp);
  }

  Map<String, dynamic> _handleResponse(http.Response resp) {
    final body = resp.body.isNotEmpty
        ? jsonDecode(resp.body) as Map<String, dynamic>
        : <String, dynamic>{};

    if (resp.statusCode >= 200 && resp.statusCode < 300) return body;

    final message = body['error'] as String? ??
        body['message'] as String? ??
        'An unexpected error occurred (${resp.statusCode}).';

    throw ApiException(message, statusCode: resp.statusCode);
  }
}
