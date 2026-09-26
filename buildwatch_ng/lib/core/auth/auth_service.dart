import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'auth_user.dart';
import 'user_role.dart';

/// Local-only authentication. There is no backend for this app, so accounts
/// (name + email + role + a salted password hash) are stored on-device in
/// Hive, and the "logged in" session is just a pointer to one of those
/// accounts, also persisted in Hive so it survives app restarts.
///
/// The password hashing here is a simple salted digest meant to avoid
/// storing plaintext passwords on disk — it is not a substitute for a real
/// backend + proper credential storage, which this offline demo app has no
/// way to provide.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _usersBoxName = 'auth_users';
  static const _sessionBoxName = 'auth_session';
  static const _sessionKey = 'current_email';

  Box? _usersBox;
  Box? _sessionBox;

  bool get isInitialized => _usersBox != null && _sessionBox != null;

  Future<void> init() async {
    _usersBox = await Hive.openBox(_usersBoxName);
    _sessionBox = await Hive.openBox(_sessionBoxName);
  }

  String _normalize(String email) => email.trim().toLowerCase();

  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode('$salt::$password');
    return sha256.convert(bytes).toString();
  }

  String _newSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  /// Registers a new local account. Throws [AuthException] if the email is
  /// already taken or the input is invalid.
  Future<AuthUser> signUp({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    _ensureInit();
    final normalizedEmail = _normalize(email);
    if (name.trim().isEmpty) {
      throw const AuthException('Please enter your name.');
    }
    if (!normalizedEmail.contains('@') || !normalizedEmail.contains('.')) {
      throw const AuthException('Please enter a valid email address.');
    }
    if (password.length < 6) {
      throw const AuthException('Password must be at least 6 characters.');
    }
    if (_usersBox!.containsKey(normalizedEmail)) {
      throw const AuthException('An account with this email already exists.');
    }
    final salt = _newSalt();
    final user = AuthUser(name: name.trim(), email: normalizedEmail, role: role);
    await _usersBox!.put(normalizedEmail, {
      ...user.toMap(),
      'salt': salt,
      'passwordHash': _hashPassword(password, salt),
    });
    await _persistSession(normalizedEmail);
    return user;
  }

  /// Validates credentials against the locally-stored account. Throws
  /// [AuthException] if the account doesn't exist or the password is wrong.
  Future<AuthUser> login({required String email, required String password}) async {
    _ensureInit();
    final normalizedEmail = _normalize(email);
    final record = _usersBox!.get(normalizedEmail) as Map?;
    if (record == null) {
      throw const AuthException('No account found for this email.');
    }
    final salt = record['salt'] as String? ?? '';
    final expectedHash = record['passwordHash'] as String? ?? '';
    if (_hashPassword(password, salt) != expectedHash) {
      throw const AuthException('Incorrect password.');
    }
    await _persistSession(normalizedEmail);
    return AuthUser.fromMap(record);
  }

  Future<void> _persistSession(String email) async {
    await _sessionBox!.put(_sessionKey, email);
  }

  /// Returns the currently logged-in user, or `null` if nobody is logged in.
  AuthUser? currentUser() {
    _ensureInit();
    final email = _sessionBox!.get(_sessionKey) as String?;
    if (email == null) return null;
    final record = _usersBox!.get(email) as Map?;
    if (record == null) return null;
    return AuthUser.fromMap(record);
  }

  bool get isLoggedIn => currentUser() != null;

  Future<void> logout() async {
    _ensureInit();
    await _sessionBox!.delete(_sessionKey);
  }

  void _ensureInit() {
    if (!isInitialized) {
      throw StateError('AuthService.init() must be called before use.');
    }
  }
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  @override
  String toString() => message;
}
