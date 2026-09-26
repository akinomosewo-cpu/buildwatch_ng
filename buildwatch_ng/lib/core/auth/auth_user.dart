import 'user_role.dart';

/// A locally-registered account. There is no backend: credentials live only
/// on this device, in Hive.
class AuthUser {
  final String name;
  final String email;
  final UserRole role;

  const AuthUser({required this.name, required this.email, required this.role});

  factory AuthUser.fromMap(Map<dynamic, dynamic> map) => AuthUser(
        name: map['name'] as String? ?? '',
        email: map['email'] as String? ?? '',
        role: UserRole.fromStorage(map['role'] as String?),
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'role': role.storageValue,
      };
}
