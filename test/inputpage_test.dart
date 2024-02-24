import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:commitchecker/screens/inputpage.dart';

void main() {
  group('InputPage Widget Tests', () {
    testWidgets('InputPage builds correctly', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => const InputPage(),
        ),
      ));

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('GitHub Username'), findsOneWidget);
      expect(find.text('Enter your GitHub ID'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });
  });
}
