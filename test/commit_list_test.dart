import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:commitchecker/components/commit_list.dart';
import 'package:commitchecker/models/commit_info.dart';

void main() {
  group(
    'commitList Tests',
    () {
      testWidgets(
        'Should test CommitList with no commits',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            const MaterialApp(
              home: Scaffold(
                body: CommitList(
                  commits: [],
                ),
              ),
            ),
          );

          expect(
            find.text('No commits'),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'Should test CommitList with null commits',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            const MaterialApp(
              home: Scaffold(
                body: CommitList(
                  commits: null,
                ),
              ),
            ),
          );

          expect(
            find.text('Select a date'),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'Should test CommitList with commits',
        (WidgetTester tester) async {
          final List<CommitInfo> fakeCommits = [
            CommitInfo(
              message: "Initial commit",
              htmlUrl: "https://github.com/example/repo/commit/1",
              date: DateTime.utc(
                2024,
                2,
                26,
              ),
            ),
            CommitInfo(
              message: "Added new feature",
              htmlUrl: "https://github.com/example/repo/commit/2",
              date: DateTime.utc(
                2024,
                2,
                27,
              ),
            ),
          ];

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: CommitList(
                  commits: fakeCommits,
                ),
              ),
            ),
          );

          expect(
            find.byType(ListTile),
            findsNWidgets(
              fakeCommits.length,
            ),
          );
        },
      );
    },
  );
}
