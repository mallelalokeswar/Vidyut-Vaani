import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

// Core constants for VidyuthVaani
class AppConstants {
  AppConstants._();

  static const String appName = 'VidyuthVaani';
  static const String appTagline =
      'Smart Electricity Services for Every Citizen';

  // Backend base URL — uses 10.0.2.2 on Android emulator, 127.0.0.1 elsewhere
  static String get baseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000/api';
    }
    return 'http://127.0.0.1:5000/api';
  }

  // Secure storage keys
  static const String accessTokenKey = 'vv_access_token';
  static const String refreshTokenKey = 'vv_refresh_token';
  static const String userDataKey = 'vv_user_data';

  // Route names
  static const String routeLogin = '/login';
  static const String routeRegister = '/register';
  static const String routeForgotPassword = '/forgot-password';
  static const String routeCitizenDashboard = '/citizen/dashboard';
  static const String routeAdminDashboard = '/admin/dashboard';
  static const String routeOperatorDashboard = '/operator/dashboard';
  static const String routeSplash = '/';

  // Roles
  static const String roleCitizen = 'citizen';
  static const String roleAdmin = 'admin';
  static const String roleOperator = 'operator';
}
