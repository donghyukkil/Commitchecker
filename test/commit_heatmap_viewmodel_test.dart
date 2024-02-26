import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:commitchecker/models/commit_info.dart';
import 'package:commitchecker/components/commit_list.dart';
import 'package:commitchecker/viewmodels/commit_heatmap_viewmodel.dart';
import 'package:commitchecker/views/commit_heatmap.dart';
import './commit_heatmap_viewmodel_test.mocks.dart';

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

@GenerateMocks([CommitHeatmapViewModel])
void main() {
  group(
    'viewmodel Tests',
    () {
      late MockCommitHeatmapViewModel mockViewModel;

      Map<DateTime, List<CommitInfo>> fakeCommitData = {
        DateTime.utc(2024, 2, 26): [
          CommitInfo(
            message: "Initial commit",
            htmlUrl: "https://github.com/example/repo/commit/1",
            date: DateTime.utc(2024, 2, 26),
          ),
        ],
        DateTime.utc(2024, 2, 27): [
          CommitInfo(
            message: "Added new feature",
            htmlUrl: "https://github.com/example/repo/commit/2",
            date: DateTime.utc(2024, 2, 27),
          ),
        ],
      };

      List<CommitInfo> allCommits = [];
      fakeCommitData.forEach(
        (
          date,
          commits,
        ) {
          allCommits.addAll(
            commits,
          );
        },
      );

      setUp(
        () {
          mockViewModel = MockCommitHeatmapViewModel();

          when(mockViewModel.repositories).thenReturn(
            [
              'Repo1',
              'Repo2',
            ],
          );
          when(mockViewModel.focusedDay).thenReturn(
            DateTime.now(),
          );
          when(mockViewModel.rangeStart).thenReturn(
            DateTime.now(),
          );
          when(mockViewModel.rangeEnd).thenReturn(
            DateTime.now().add(
              const Duration(days: 1),
            ),
          );
          when(
            mockViewModel.calendarFormat,
          ).thenReturn(
            CalendarFormat.month,
          );
          when(mockViewModel.calculateCommitsForRange(
            any,
            any,
          )).thenAnswer(
            (_) => Future.value(15),
          );
          when(
            mockViewModel.selectedDay,
          ).thenReturn(
            DateTime.now(),
          );
          when(mockViewModel.formatDate(any)).thenReturn(
            "formattedDate",
          );
          when(
            mockViewModel.commitData,
          ).thenReturn(
            fakeCommitData,
          );
          when(
            mockViewModel.selectedCommits,
          ).thenReturn(
            allCommits,
          );
        },
      );

      testWidgets(
        'Should test the modal bottom sheet when selecting a repository',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: ChangeNotifierProvider<CommitHeatmapViewModel>.value(
                value: mockViewModel,
                child: const CommitHeatmap(
                  username: 'testuser',
                ),
              ),
            ),
          );

          await tester.tap(
            find.byIcon(
              Icons.folder_open,
            ),
          );
          await tester.pumpAndSettle();

          expect(
            find.byType(BottomSheet),
            findsOneWidget,
          );

          expect(
            find.text('Repo1'),
            findsOneWidget,
          );
          expect(
            find.text('Repo2'),
            findsOneWidget,
          );
        },
      );

      testWidgets('Calendar selection updates selected commits',
          (WidgetTester tester) async {
        final selectedDate = DateTime.utc(
          2024,
          2,
          27,
        );

        when(mockViewModel.selectedDay).thenReturn(
          selectedDate,
        );
        when(
          mockViewModel.selectedCommits,
        ).thenReturn(
          fakeCommitData[selectedDate]!,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider<CommitHeatmapViewModel>.value(
              value: mockViewModel,
              child: const CommitHeatmap(
                username: 'testuser',
              ),
            ),
          ),
        );

        await tester.tap(
          find.text(
            '27',
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byType(CommitList),
          findsOneWidget,
        );
        final expectedCommitMessage =
            fakeCommitData[selectedDate]!.first.message;
        expect(
          find.text(expectedCommitMessage),
          findsOneWidget,
        );
      });

      testWidgets(
        'Should display the default message when no date is selected',
        (WidgetTester tester) async {
          when(
            mockViewModel.selectedDay,
          ).thenReturn(
            null,
          );
          when(
            mockViewModel.selectedCommits,
          ).thenReturn(
            null,
          );

          await tester.pumpWidget(
            MaterialApp(
              home: ChangeNotifierProvider<CommitHeatmapViewModel>.value(
                value: mockViewModel,
                child: const CommitHeatmap(
                  username: 'testuser',
                ),
              ),
            ),
          );

          expect(
            find.text(
              'Select a date',
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'Should Display selected commits',
        (WidgetTester tester) async {
          final List<CommitInfo> selectedCommits = [
            CommitInfo(
              message: "Fix issue #123",
              htmlUrl: "https://github.com/example/repo/commit/123",
              date: DateTime.utc(
                2024,
                2,
                26,
              ),
            ),
            CommitInfo(
              message: "Implement feature XYZ",
              htmlUrl: "https://github.com/example/repo/commit/456",
              date: DateTime.utc(
                2024,
                2,
                27,
              ),
            ),
          ];

          when(mockViewModel.selectedDay).thenReturn(
            DateTime.utc(
              2024,
              2,
              26,
            ),
          );
          when(mockViewModel.selectedCommits).thenReturn(
            selectedCommits,
          );

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: ChangeNotifierProvider<CommitHeatmapViewModel>.value(
                  value: mockViewModel,
                  child: CommitList(
                    commits: mockViewModel.selectedCommits,
                  ),
                ),
              ),
            ),
          );

          expect(
            find.text(
              'Fix issue #123',
            ),
            findsOneWidget,
          );
          expect(
            find.text(
              'Implement feature XYZ',
            ),
            findsOneWidget,
          );

          List<String> tappedUrls = [];

          await tester.tap(
            find.text(
              'Fix issue #123',
            ),
          );
          tappedUrls.add(
            selectedCommits[0].htmlUrl,
          );
          await tester.tap(
            find.text(
              'Implement feature XYZ',
            ),
          );
          tappedUrls.add(
            selectedCommits[1].htmlUrl,
          );

          expect(
            tappedUrls,
            equals(
              [
                selectedCommits[0].htmlUrl,
                selectedCommits[1].htmlUrl,
              ],
            ),
          );
        },
      );
    },
  );
}
