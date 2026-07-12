import '../../../../shared/models/user_role.dart';

class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.isActive,
    this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final bool? isActive;
  final DateTime? createdAt;

  factory User.fromJson(Map<String, dynamic> json) {
    final role = UserRole.fromString(json['role'] as String?);
    if (role == null) {
      throw FormatException('Unknown user role: ${json['role']}');
    }

    return User(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: role,
      isActive: json['isActive'] as bool?,
      createdAt: _parseDateTime(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.value,
      if (isActive != null) 'isActive': isActive,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value is! String || value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }
}
