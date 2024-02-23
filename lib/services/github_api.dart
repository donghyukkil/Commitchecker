import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:commitchecker/models/commit_info.dart';

Future<List<CommitInfo>> fetchAllCommits(String username, String repository,
    {DateTime? startOfMonth, DateTime? endOfMonth}) async {
  List<CommitInfo> allCommits = [];
  int page = 1;
  bool hasMore = true;
  String? since = startOfMonth?.toIso8601String();
  String? until = endOfMonth?.toIso8601String();

  await dotenv.load();
  String? token = dotenv.get('GITHUB_TOKEN');

  while (hasMore) {
    String url =
        'https://api.github.com/repos/$username/$repository/commits?per_page=100&page=$page';

    if (since != null && until != null) {
      url += '&since=$since&until=$until';
    }

    final response = await http.get(Uri.parse(url), headers: {
      'Authorization': 'token $token',
    });

    if (response.statusCode == 200) {
      List<dynamic> commits = json.decode(response.body);

      for (var commit in commits) {
        DateTime date =
            DateTime.parse(commit['commit']['author']['date']).toUtc();
        String message = commit['commit']['message'];
        String htmlUrl = commit['html_url'];
        allCommits
            .add(CommitInfo(message: message, htmlUrl: htmlUrl, date: date));
      }

      if (commits.length < 100) {
        hasMore = false;
      } else {
        page++;
      }
    } else {
      throw Exception('Failed to load commits: ${response.statusCode}');
    }
  }

  return allCommits;
}

Future<List<String>> fetchRepositoriesFromAPI(String username) async {
  await dotenv.load();
  String? token = dotenv.get('GITHUB_TOKEN');

  final String url = 'https://api.github.com/users/$username/repos';
  final response = await http.get(Uri.parse(url), headers: {
    'Authorization': 'token $token',
  });

  if (response.statusCode == 200) {
    final List<dynamic> reposJson = json.decode(response.body);

    return reposJson.map((repo) => repo['name'].toString()).toList();
  } else {
    throw Exception('Failed to load repositories');
  }
}
