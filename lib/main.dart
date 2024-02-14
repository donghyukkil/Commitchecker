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
  Map<DateTime, List> commitData = {};
  DateTime focusedDay = DateTime.now();
  bool isLoading = true;
  bool isHeatmapView = false;

  @override
  void initState() {
    super.initState();
    fetchCommits();
  }

  fetchCommits() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse(
          "https://api.github.com/repos/donghyukkil/hello-legalpad-client/commits?author=donghyukkil&since=2023-02-01T00:00:00Z&until=2024-02-15T23:59:59Z&per_page=1000"));

      if (response.statusCode == 200) {
        List<dynamic> commits = json.decode(response.body);
        Map<DateTime, List> newCommitData = {};

        for (var commit in commits) {
          DateTime date =
              DateTime.parse(commit["commit"]["author"]["date"]).toUtc();
          DateTime datekey = DateTime.utc(date.year, date.month, date.day);
          String message = commit["commit"]["message"];

          if (newCommitData[datekey] == null) {
            newCommitData[datekey] = [];
          }

          newCommitData[datekey]!.add(message);
        }

        setState(() {
          commitData = newCommitData;
          isLoading = false;
        });
      } else {
        showErrorDialog("Failed to laod commits");
      }
    } catch (e) {
      showErrorDialog("Error: $e");
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
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : TableCalendar(
            focusedDay: focusedDay,
            firstDay: DateTime.utc(2023, 1, 1),
            lastDay: DateTime.utc(2024, 12, 31),
            eventLoader: (day) {
              return commitData[day] ?? [];
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isNotEmpty) {
                  return _buildEventMarker(date, events);
                }
                return null;
              },
            ),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                this.focusedDay = focusedDay;
              });

              if (commitData[selectedDay] != null &&
                  commitData[selectedDay]!.isNotEmpty) {
                showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                          title: Text(
                              "Commits on ${selectedDay.toIso8601String().split("T")[0]}"),
                          content: SingleChildScrollView(
                            child: ListBody(
                              children: commitData[selectedDay]!
                                  .asMap()
                                  .entries
                                  .map((entry) {
                                int idx = entry.key;
                                String message = entry.value;
                                return Text("${idx + 1}. $message");
                              }).toList(),
                            ),
                          ),
                          actions: <Widget>[
                            TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text("OK"))
                          ],
                        ));
              }
            },
            calendarStyle: const CalendarStyle(
              cellMargin: EdgeInsets.all(4),
              cellPadding: EdgeInsets.all(5),
            ),
          );
  }

  Widget _buildEventMarker(DateTime date, List events) {
    return AnimatedContainer(
      duration: const Duration(microseconds: 300),
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        color: getColorForCommitCount(events.length),
      ),
      width: 16.0,
      height: 16.0,
      child: Center(
          child: Text(
        "${events.length}",
        style: const TextStyle().copyWith(
          color: Colors.white,
          fontSize: 12.0,
        ),
      )),
    );
  }

  Color getColorForCommitCount(int count) {
    if (count == 0) return Colors.grey;
    if (count == 1) return Colors.green.shade200;
    if (count >= 2 && count <= 4) return Colors.yellow.shade800;
    if (count > 4) return Colors.red.shade800;
    return Colors.grey;
  }
}
