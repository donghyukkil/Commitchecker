import 'package:flutter/material.dart';

import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

import "package:commitchecker/screens/web_view_page.dart";
import 'package:commitchecker/models/commit_info.dart';

class CommitHeatmap extends StatefulWidget {
  final String username;
  const CommitHeatmap({Key? key, required this.username}) : super(key: key);

  @override
  _CommitHeatmapState createState() => _CommitHeatmapState();
}

class _CommitHeatmapState extends State<CommitHeatmap> {
  Map<DateTime, List<CommitInfo>> commitData = {};
  DateTime focusedDay = DateTime.now();
  DateTime? selectedDay;
  List<CommitInfo>? selectedCommits;
  bool isLoading = false;
  List<String> repositories = [];
  String? selectedRepository;

  @override
  void initState() {
    super.initState();
    fetchRepositories(widget.username);
  }

  Future<void> fetchRepositories(String username) async {
    try {
      setState(() => isLoading = true);

      List<String> repoNames = await fetchRepositoriesFromAPI(username);

      setState(() {
        isLoading = false;
        repositories = repoNames;
        selectedRepository =
            repositories.isNotEmpty ? repositories.first : null;
        fetchCommitsForMonth(focusedDay);
      });
    } catch (e) {
      setState(() => isLoading = false);
      showErrorDialog("Failed to load repositories: $e");
    }
  }

  Future<List<String>> fetchRepositoriesFromAPI(String username) async {
    final String url = 'https://api.github.com/users/$username/repos';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<dynamic> reposJson = json.decode(response.body);

      return reposJson
          .map(
            (repo) => repo['name'].toString(),
          )
          .toList();
    } else {
      throw Exception('Failed to load repositories');
    }
  }

  void fetchCommitsForMonth(DateTime targetDate) async {
    setState(() => isLoading = true);
    String? repository = selectedRepository;

    if (repository == null) {
      setState(() => isLoading = false);

      return;
    }

    DateTime startOfMonth = DateTime(targetDate.year, targetDate.month, 1);
    DateTime endOfMonth = DateTime(targetDate.year, targetDate.month + 1, 0);
    String since = startOfMonth.toIso8601String();
    String until = endOfMonth.toIso8601String();
    final String url =
        "https://api.github.com/repos/${widget.username}/$repository/commits?since=$since&until=$until&per_page=100";

    try {
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

        setState(() {
          commitData = newCommitData;
          isLoading = false;
        });
      } else {
        throw Exception(
            'Failed to load commits with status code: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => isLoading = false);
      showErrorDialog("Error fetching commits: $e");
    }
  }

  void showErrorDialog(String message) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text("Error"),
              content: Text(message),
              actions: <Widget>[
                TextButton(
                  child: const Text("OK"),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ));
  }

  String formatDate(DateTime? date) {
    if (date == null) {
      return 'No Date Selected';
    }

    return DateFormat('yyyy-MM-dd EEEE').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Commit Heatmap",
          style: TextStyle(
            fontSize: 23,
          ),
        ),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      focusedDay = DateTime.now();
                    });
                    fetchCommitsForMonth(focusedDay);
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 15.0),
                  ),
                  child: const Text(
                    'Today',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(width: 60),
                DropdownButton<String>(
                  value: selectedRepository,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedRepository = newValue;
                    });
                    fetchCommitsForMonth(focusedDay);
                  },
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                  ),
                  underline: Container(
                    height: 2,
                    color: Colors.green,
                  ),
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: Colors.green,
                  ),
                  items: repositories.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          value,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Expanded(
              flex: 4,
              child: TableCalendar(
                focusedDay: focusedDay,
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2025, 12, 31),
                eventLoader: (day) => commitData[day] ?? [],
                onPageChanged: (focusedDay) {
                  this.focusedDay = focusedDay;
                  fetchCommitsForMonth(focusedDay);
                },
                availableCalendarFormats: const {
                  CalendarFormat.month: 'Month',
                },
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    if (events.isNotEmpty) {
                      return Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: events.length > 5
                                ? Colors.red
                                : (events.length > 2
                                    ? Colors.orange
                                    : Colors.green),
                          ),
                          width: 8.0,
                          height: 8.0,
                        ),
                      );
                    }

                    return null;
                  },
                ),
                headerStyle: const HeaderStyle(
                  titleCentered: true,
                ),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    this.selectedDay = selectedDay;
                    selectedCommits = commitData[selectedDay] ?? [];
                  });
                },
              ),
            ),
            if (selectedCommits != null && selectedDay != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    formatDate(selectedDay),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            Expanded(
              flex: 2,
              child: Scrollbar(
                thumbVisibility: true,
                thickness: 4.0,
                radius: const Radius.circular(5.0),
                child: ListView.builder(
                  itemCount: selectedCommits?.length ?? 0,
                  itemBuilder: (context, index) {
                    final commitInfo = selectedCommits![index];

                    return MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        child: ListTile(
                          title: Text(commitInfo.message,
                              style: const TextStyle(fontSize: 13)),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    WebViewPage(url: commitInfo.htmlUrl),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
