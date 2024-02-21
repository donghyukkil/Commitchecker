import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:commitchecker/models/commit_info.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<List<CommitInfo>> fetchAllCommits(
    String username, String repository) async {
  List<CommitInfo> allCommits = [];
  int page = 1;
  bool hasMore = true;

  await dotenv.load();
  String? token = dotenv.get('GITHUB_TOKEN');

  while (hasMore) {
    final String url =
        'https://api.github.com/repos/$username/$repository/commits?per_page=100&page=$page';
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

Future<Map<DateTime, List<CommitInfo>>> fetchCommitsForRange(
    String username, String repository, DateTime start, DateTime end) async {
  String since = start.toIso8601String();
  String until = end.toIso8601String();

  await dotenv.load();
  String? token = dotenv.get('GITHUB_TOKEN');

  final String url =
      'https://api.github.com/repos/$username/$repository/commits?since=$since&until=$until&per_page=100';
  final response = await http.get(Uri.parse(url), headers: {
    'Authorization': 'token $token',
  });

  if (response.statusCode == 200) {
    List<dynamic> commits = json.decode(response.body);
    Map<DateTime, List<CommitInfo>> commitData = {};

    for (var commit in commits) {
      DateTime date =
          DateTime.parse(commit['commit']['author']['date']).toUtc();
      DateTime dateKey = DateTime.utc(date.year, date.month, date.day);

      String message = commit['commit']['message'];
      String htmlUrl = commit['html_url'];

      if (!commitData.containsKey(dateKey)) {
        commitData[dateKey] = [];
      }

      commitData[dateKey]!
          .add(CommitInfo(message: message, htmlUrl: htmlUrl, date: date));
    }

    return commitData;
  } else {
    throw Exception('Failed to fetch commits: ${response.statusCode}');
  }
}
