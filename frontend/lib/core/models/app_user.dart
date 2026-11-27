/// User role enumeration — mirrors backend UserRole.
enum UserRole {
  citizen('citizen', 'Citizen'),
  admin('admin', 'Administrator'),
  operator('operator', 'Field Operator');

  const UserRole(this.value, this.label);

  final String value;
  final String label;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (r) => r.value == value,
      orElse: () => throw ArgumentError('Unknown role: $value'),
    );
  }

  String get dashboardRoute {
    switch (this) {
      case UserRole.citizen:
        return '/citizen/dashboard';
      case UserRole.admin:
        return '/admin/dashboard';
      case UserRole.operator:
        return '/operator/dashboard';
    }
  }
}

/// Authenticated user model returned from the API.
class AppUser {
  final int id;
  final String fullName;
  final String email;
  final String username;
  final UserRole role;
  final String status;
  final String? phone;
  final String? locality;
  final String? meterNumber;

  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.username,
    required this.role,
    required this.status,
    this.phone,
    this.locality,
    this.meterNumber,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as int,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      username: json['username'] as String,
      role: UserRole.fromString(json['role'] as String),
      status: json['status'] as String,
      phone: json['phone'] as String?,
      locality: json['locality'] as String?,
      meterNumber: json['meter_number'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'email': email,
        'username': username,
        'role': role.value,
        'status': status,
        'phone': phone,
        'locality': locality,
        'meter_number': meterNumber,
      };
}
