import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';

import 'package:buildwatch_ng/core/auth/auth_service.dart';
import 'package:buildwatch_ng/core/auth/user_role.dart';
import 'package:buildwatch_ng/main.dart';

void main() {
  // Prevent GoogleFonts from trying to fetch fonts over the network during
  // tests (there is no network access in CI/test sandboxes, and repeated
  // failed fetch attempts can otherwise stall pumpAndSettle indefinitely).
  GoogleFonts.config.allowRuntimeFetching = false;

  late Directory tempDir;
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  // Hive/AuthService do real file I/O. Under the widget test binding that
  // must happen inside `runAsync`, otherwise the real Future never resolves
  // and any later `pumpAndSettle` hangs forever waiting on it.
  setUp(() async {
    await binding.runAsync(() async {
      tempDir = Directory.systemTemp.createTempSync('buildwatch_widget_test');
      Hive.init(tempDir.path);
      await AuthService.instance.init();
    });
  });

  tearDown(() async {
    await binding.runAsync(() async {
      await Hive.deleteFromDisk();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });
  });

  testWidgets('App boots to the splash screen, then the login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const BuildWatchApp());
    await tester.pump();

    expect(find.text('BuildWatch NG'), findsOneWidget);

    // Let the splash delay elapse and the fade transition settle.
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('Signing up routes straight into the home page', (WidgetTester tester) async {
    await tester.pumpWidget(const BuildWatchApp());
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.tap(find.byType(TextButton));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Full name'), 'Test User');
    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'test@example.com');
    await tester.enterText(find.widgetWithText(TextFormField, 'Password (min 6 characters)'), 'password1');

    // AuthService.signUp does real (Hive) file I/O, so the tap that triggers
    // it must run inside `runAsync` for that real Future to actually
    // complete under the widget test binding's fake clock.
    await tester.runAsync(() async {
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create account'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();

    expect(find.text('What you can do'), findsOneWidget);
  });

  testWidgets('Add sheet opens from the app bar once logged in', (WidgetTester tester) async {
    await tester.runAsync(() => AuthService.instance.signUp(
          name: 'Existing User',
          email: 'existing@example.com',
          password: 'password1',
          role: UserRole.diasporaOwner,
        ));

    await tester.pumpWidget(const BuildWatchApp());
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('What you can do'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Add New'), findsOneWidget);
  });
}
