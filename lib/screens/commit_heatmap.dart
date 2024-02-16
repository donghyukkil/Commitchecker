import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class CommitHeatmap extends StatefulWidget {
  final String username;
  const CommitHeatmap({Key? key, required this.username}) : super(key: key);

  @override
  _CommitHeatmapState createState() => _CommitHeatmapState();
}

class _CommitHeatmapState extends State<CommitHeatmap> {
  Map<DateTime, List<String>> commitData = {};
  DateTime focusedDay = DateTime.now();
  DateTime? selectedDay;
  List<String>? selectedCommits;
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
        Map<DateTime, List<String>> newCommitData = {};

        for (var commit in commits) {
          DateTime date =
              DateTime.parse(commit["commit"]["author"]["date"]).toUtc();
          DateTime dateKey = DateTime.utc(date.year, date.month, date.day);
          newCommitData[dateKey] = (newCommitData[dateKey] ?? [])
            ..add(commit["commit"]["message"]);
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
    if (date == null) return 'No Date Selected';

    return DateFormat('yyyy-MM-dd EEEE').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Commit Heatmap"),
      ),
      body: Column(
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
                child: const Text('Today'),
              ),
              const SizedBox(width: 20),
              DropdownButton<String>(
                value: selectedRepository,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedRepository = newValue;
                  });
                  fetchCommitsForMonth(focusedDay);
                },
                items:
                    repositories.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ],
          ),
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
                    return Positioned(
                      right: 27,
                      bottom: 1,
                      child: Container(
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
              child: Text(
                formatDate(selectedDay),
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          Expanded(
            flex: 3,
            child: Scrollbar(
              thumbVisibility: true, //
              thickness: 4.0,
              radius: const Radius.circular(5.0),
              child: ListView.builder(
                itemCount: selectedCommits?.length ?? 0,
                itemBuilder: (context, index) => ListTile(
                  title: Text(selectedCommits![index]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
