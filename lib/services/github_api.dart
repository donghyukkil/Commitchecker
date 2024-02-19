import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:commitchecker/models/commit_info.dart';

Future<List<String>> fetchRepositoriesFromAPI(String username) async {
  final String url = 'https://api.github.com/users/$username/repos';
  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    final List<dynamic> reposJson = json.decode(response.body);

    return reposJson.map((repo) => repo['name'].toString()).toList();
  } else {
    throw Exception('Failed to load repositories');
  }
}

Future<Map<DateTime, List<CommitInfo>>> fetchCommitsForMonth(String username,
    String repository, DateTime startOfMonth, DateTime endOfMonth) async {
  String since = startOfMonth.toIso8601String();
  String until = endOfMonth.toIso8601String();

  final String url =
      "https://api.github.com/repos/$username/$repository/commits?since=$since&until=$until&per_page=100";
  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    List<dynamic> commits = json.decode(response.body);
    Map<DateTime, List<CommitInfo>> newCommitData = {};

    for (var commit in commits) {
      DateTime date =
          DateTime.parse(commit["commit"]["author"]["date"]).toUtc();
      DateTime dateKey = DateTime.utc(date.year, date.month, date.day);
      String commitMessage = commit["commit"]["message"];
      String htmlUrl = commit["html_url"];

      newCommitData[dateKey] = (newCommitData[dateKey] ?? [])
        ..add(CommitInfo(message: commitMessage, htmlUrl: htmlUrl));
    }

    return newCommitData;
  } else {
    throw Exception(
        'Failed to load commits with status code: ${response.statusCode}');
  }
}
