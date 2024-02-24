import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:commitchecker/main.dart';

void main() {
  testWidgets('HomePage renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomePage()));

    expect(find.text('Commit Checker'), findsOneWidget);
  });

  testWidgets('Modal dialog shows on HomePage init',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomePage()));

    await tester.pumpAndSettle();

    expect(find.text('Welcome to Commit Checker!'), findsOneWidget);

    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Commit Checker!'), findsNothing);
  });
}
