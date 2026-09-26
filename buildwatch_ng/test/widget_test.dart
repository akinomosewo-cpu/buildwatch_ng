import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:buildwatch_ng/main.dart';

void main() {
  testWidgets('App boots to the home page', (WidgetTester tester) async {
    await tester.pumpWidget(const BuildWatchApp());
    await tester.pumpAndSettle();

    expect(find.text('BuildWatch NG'), findsOneWidget);
    expect(find.text('What you can do'), findsOneWidget);
  });

  testWidgets('Add sheet opens from the app bar', (WidgetTester tester) async {
    await tester.pumpWidget(const BuildWatchApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Add New'), findsOneWidget);
  });
}
