import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:commitchecker/services/github_api.dart';
import 'package:commitchecker/models/commit_info.dart';
import './http_client_mock.mocks.dart';

void main() {
  group(
    'GitHub API Tests',
    () {
      late MockClient client;

      setUp(
        () {
          client = MockClient();
        },
      );

      test(
        'should successfully fetch commits from GitHub API',
        () async {
          final jsonResponse = jsonEncode(
            [
              {
                "sha": "04b77764cd173ede21cf1274ba18edfbe1ca0b97",
                "commit": {
                  "author": {"date": "2024-02-03T12:09:32Z"},
                  "message": "docs: README 8차 수정"
                },
                "html_url":
                    "https://github.com/donghyukkil/SyncNotePad-client/commit/04b77764cd173ede21cf1274ba18edfbe1ca0b97",
              },
            ],
          );

          when(
            client.get(
              any,
              headers: anyNamed('headers'),
            ),
          ).thenAnswer(
            (_) async => http.Response(jsonResponse, 200),
          );

          final commits = await fetchAllCommits(
            'donghyukkil',
            'SyncNotePad-client',
            client: client,
          );

          expect(
            commits,
            isA<List<CommitInfo>>(),
          );
          expect(
            commits.isNotEmpty,
            true,
          );
          expect(
            commits.first.message,
            "docs: README 8차 수정",
          );
        },
      );

      test(
          'should correctly filter commits by a specific date in fetchAllCommits',
          () async {
        final jsonResponse = jsonEncode(
          [
            {
              "sha": "04b77764cd173ede21cf1274ba18edfbe1ca0b97",
              "commit": {
                "author": {"date": "2024-02-03T12:09:32Z"},
                "message": "docs: README 8차 수정"
              },
              "html_url":
                  "https://github.com/donghyukkil/SyncNotePad-client/commit/04b77764cd173ede21cf1274ba18edfbe1ca0b97",
            },
            {
              "sha": "c95346357ada9562f758761cb0e8f4e613759bd7",
              "commit": {
                "author": {"date": "2024-02-01T10:07:08Z"},
                "message": "docs: README 7차 수정"
              },
              "html_url":
                  "https://github.com/donghyukkil/SyncNotePad-client/commit/c95346357ada9562f758761cb0e8f4e613759bd7",
            },
          ],
        );

        when(
          client.get(
            any,
            headers: anyNamed('headers'),
          ),
        ).thenAnswer(
          (_) async => http.Response(jsonResponse, 200),
        );

        final DateTime startOfMonth = DateTime(2024, 2, 1);
        final DateTime endOfMonth = DateTime(2024, 2, 28);
        final commits = await fetchAllCommits(
          'donghyukkil',
          'SyncNotePad-client',
          startOfMonth: startOfMonth,
          endOfMonth: endOfMonth,
          client: client,
        );

        expect(
          commits.length,
          2,
        );
        expect(
          commits[0].message,
          "docs: README 8차 수정",
        );
        expect(
          commits[1].message,
          "docs: README 7차 수정",
        );
      });

      test(
        'should throw an appropriate exception when a 404 error is returned from the GitHub API',
        () async {
          when(client.get(
            any,
            headers: anyNamed('headers'),
          )).thenAnswer(
            (_) async => http.Response('Not Found', 404),
          );

          expect(
            fetchAllCommits('donghyukkil', 'NonexistentRepo', client: client),
            throwsException,
          );
        },
      );
    },
  );
}
