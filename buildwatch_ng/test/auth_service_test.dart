import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:buildwatch_ng/core/auth/auth_service.dart';
import 'package:buildwatch_ng/core/auth/user_role.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('buildwatch_auth_test');
    Hive.init(tempDir.path);
    await AuthService.instance.init();
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('AuthService local auth', () {
    test('sign up creates an account, persists role, and logs the user in', () async {
      final user = await AuthService.instance.signUp(
        name: 'Ada Obi',
        email: 'Ada@Example.com',
        password: 'secret123',
        role: UserRole.diasporaOwner,
      );

      expect(user.name, 'Ada Obi');
      expect(user.email, 'ada@example.com'); // normalized to lowercase
      expect(user.role, UserRole.diasporaOwner);
      expect(AuthService.instance.isLoggedIn, isTrue);
      expect(AuthService.instance.currentUser()?.email, 'ada@example.com');
    });

    test('signing up twice with the same email throws', () async {
      await AuthService.instance.signUp(
        name: 'Chidi',
        email: 'chidi@example.com',
        password: 'password1',
        role: UserRole.siteSupervisor,
      );

      expect(
        () => AuthService.instance.signUp(
          name: 'Chidi Again',
          email: 'chidi@example.com',
          password: 'password2',
          role: UserRole.siteSupervisor,
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('login succeeds with correct credentials and preserves role', () async {
      await AuthService.instance.signUp(
        name: 'Bola Site',
        email: 'bola@example.com',
        password: 'buildersite',
        role: UserRole.siteSupervisor,
      );
      await AuthService.instance.logout();
      expect(AuthService.instance.isLoggedIn, isFalse);

      final loggedIn = await AuthService.instance.login(email: 'bola@example.com', password: 'buildersite');
      expect(loggedIn.role, UserRole.siteSupervisor);
      expect(AuthService.instance.isLoggedIn, isTrue);
    });

    test('login fails with wrong password or unknown email', () async {
      await AuthService.instance.signUp(
        name: 'Femi',
        email: 'femi@example.com',
        password: 'correcthorse',
        role: UserRole.diasporaOwner,
      );
      await AuthService.instance.logout();

      expect(
        () => AuthService.instance.login(email: 'femi@example.com', password: 'wrongpass'),
        throwsA(isA<AuthException>()),
      );
      expect(
        () => AuthService.instance.login(email: 'nobody@example.com', password: 'whatever'),
        throwsA(isA<AuthException>()),
      );
      expect(AuthService.instance.isLoggedIn, isFalse);
    });

    test('logout clears the session but keeps the account', () async {
      await AuthService.instance.signUp(
        name: 'Ngozi',
        email: 'ngozi@example.com',
        password: 'topsecret',
        role: UserRole.diasporaOwner,
      );
      await AuthService.instance.logout();

      expect(AuthService.instance.currentUser(), isNull);
      final relogin = await AuthService.instance.login(email: 'ngozi@example.com', password: 'topsecret');
      expect(relogin.name, 'Ngozi');
    });

    test('passwords are stored salted and hashed, never in plaintext', () async {
      await AuthService.instance.signUp(
        name: 'Salty Sam',
        email: 'sam@example.com',
        password: 'plaintextpassword',
        role: UserRole.siteSupervisor,
      );

      final box = await Hive.openBox('auth_users');
      final record = box.get('sam@example.com') as Map;

      expect(record['passwordHash'], isNot(equals('plaintextpassword')));
      expect((record['salt'] as String).isNotEmpty, isTrue);
      expect((record['passwordHash'] as String).length, 64); // SHA-256 hex digest
    });
  });
}
