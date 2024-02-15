import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('GitHub Commit Heatmap'),
        ),
        body: const CommitHeatmap(),
      ),
    );
  }
}

class CommitHeatmap extends StatefulWidget {
  const CommitHeatmap({super.key});

  @override
  _CommitHeatmapState createState() => _CommitHeatmapState();
}

class _CommitHeatmapState extends State<CommitHeatmap> {
  final TextEditingController _usernameController = TextEditingController();
  Map<DateTime, List> commitData = {};
  DateTime focusedDay = DateTime.now();
  bool isLoading = false;

  List<String> repositories = [];
  String? selectedRepository;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  void updateRepositories(String username) async {
    try {
      List<String> repoNames = await fetchRepositories(username);
      setState(() {
        repositories = repoNames;
        selectedRepository =
            repositories.isNotEmpty ? repositories.first : null;
      });
    } catch (e) {
      showErrorDialog("Failed to load repositories: $e");
    }
  }

  Future<List<String>> fetchRepositories(String username) async {
    final String url = 'https://api.github.com/users/$username/repos';
    final response = await http.get(
      Uri.parse(url),
    );

    if (response.statusCode == 200) {
      final List<dynamic> reposJson = json.decode(response.body);
      List<String> repositoryNames =
          reposJson.map((repo) => repo['name'].toString()).toList();

      return repositoryNames;
    } else {
      throw Exception('Failed to load repositories');
    }
  }

  void fetchCommitsForMonth(DateTime month) async {
    setState(() {
      isLoading = true;
    });

    String username = _usernameController.text;
    String? repository = selectedRepository;

    if (repository == null || username.isEmpty) {
      setState(() {
        isLoading = false;
      });

      return;
    }

    DateTime startOfMonth = DateTime(month.year, month.month, 1);
    DateTime endOfMonth = DateTime(month.year, month.month + 1, 0);

    String since = startOfMonth.toIso8601String();
    String until = endOfMonth.toIso8601String();

    final String url =
        "https://api.github.com/repos/$username/$repository/commits?since=$since&until=$until&per_page=100";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        List<dynamic> commits = json.decode(response.body);
        Map<DateTime, List> newCommitData = {};

        for (var commit in commits) {
          DateTime date =
              DateTime.parse(commit["commit"]["author"]["date"]).toUtc();
          DateTime dateKey = DateTime.utc(date.year, date.month, date.day);

          if (!newCommitData.containsKey(dateKey)) {
            newCommitData[dateKey] = [];
          }

          newCommitData[dateKey]!.add(commit["commit"]["message"]);
        }

        setState(() {
          commitData.addAll(newCommitData);
          isLoading = false;
        });
      } else {
        throw Exception(
            'Failed to load commits with status code: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
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

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 700,
      child: Column(
        children: [
          const SizedBox(height: 40),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : TableCalendar(
                    focusedDay: focusedDay,
                    firstDay: DateTime.utc(2023, 1, 1),
                    lastDay: DateTime.utc(2024, 12, 31),
                    eventLoader: (day) => commitData[day] ?? [],
                    onPageChanged: (focusedDay) {
                      setState(() {
                        this.focusedDay = focusedDay;
                      });
                      fetchCommitsForMonth(focusedDay);
                    },
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, date, events) {
                        if (events.isNotEmpty) {
                          return _buildEventMarker(date, events);
                        }

                        return null;
                      },
                    ),
                    availableCalendarFormats: const {
                      CalendarFormat.month: 'Month',
                    },
                    onDaySelected: (selectedDay, focusedDay) {
                      if (commitData[selectedDay] != null &&
                          commitData[selectedDay]!.isNotEmpty) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(
                                "Commits on ${selectedDay.toIso8601String().split('T')[0]}"),
                            content: SingleChildScrollView(
                              child: ListBody(
                                children: commitData[selectedDay]!
                                    .asMap()
                                    .entries
                                    .map((entry) => Text(
                                        '${entry.key + 1}. ${entry.value}'))
                                    .toList(),
                              ),
                            ),
                            actions: <Widget>[
                              TextButton(
                                child: const Text('Close'),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'GitHub Username'),
              onSubmitted: (value) => updateRepositories(value),
            ),
          ),
          DropdownButton<String>(
            value: selectedRepository,
            onChanged: (String? newValue) {
              setState(() {
                selectedRepository = newValue;
              });
              if (newValue != null) {
                fetchCommitsForMonth(focusedDay);
              }
            },
            items: repositories.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEventMarker(DateTime date, List events) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: getColorForCommitCount(events.length),
      ),
      width: 16.0,
      height: 16.0,
      child: Center(
        child: Text(
          '${events.length}',
          style: const TextStyle().copyWith(
            color: Colors.white,
            fontSize: 12.0,
          ),
        ),
      ),
    );
  }

  Color getColorForCommitCount(int count) {
    if (count == 0) return Colors.grey;
    if (count == 1) return Colors.yellow.shade700;
    if (count >= 2 && count <= 4) return Colors.blue.shade400;
    if (count > 4) return Colors.red.shade800;

    return Colors.grey;
  }
}
