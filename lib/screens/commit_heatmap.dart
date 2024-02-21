import 'package:flutter/material.dart';

import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

import 'package:commitchecker/models/commit_info.dart';
import 'package:commitchecker/components/commit_list.dart';
import 'package:commitchecker/services/github_api.dart';

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
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  List<CommitInfo>? selectedCommits;
  bool isLoading = false;
  List<String> repositories = [];
  String? selectedRepository;
  bool isRangeSelectionModeEnabled = false;

  @override
  void initState() {
    super.initState();
    fetchRepositories(widget.username);
  }

  void toggleRangeSelectionMode() {
    setState(() {
      isRangeSelectionModeEnabled = !isRangeSelectionModeEnabled;
    });
  }

  void onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (_rangeStart == null || _rangeEnd != null) {
      setState(() {
        _rangeStart = selectedDay;
        _rangeEnd = null;
        this.focusedDay = focusedDay;

        selectedCommits = commitData[selectedDay] ?? [];
      });
    } else if (selectedDay.isBefore(_rangeStart!)) {
      setState(() {
        _rangeStart = selectedDay;
        _rangeEnd = null;
        this.focusedDay = focusedDay;

        selectedCommits = commitData[selectedDay] ?? [];
      });
    } else if (_rangeStart != null && selectedDay.isAfter(_rangeStart!)) {
      setState(() {
        _rangeEnd = selectedDay;
        this.focusedDay = focusedDay;
      });

      showCommitStatsForPeriod(context, widget.username, selectedRepository);
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

    await dotenv.load();
    String? token = dotenv.get('GITHUB_TOKEN');

    final String url =
        'https://api.github.com/repos/${widget.username}/$repository/commits?since=$since&until=$until&per_page=100';

    try {
      final response = await http.get(Uri.parse(url), headers: {
        'Authorization': 'token $token',
      });

      if (response.statusCode == 200) {
        List<dynamic> commits = json.decode(response.body);
        Map<DateTime, List<CommitInfo>> newCommitData = {};

        for (var commit in commits) {
          DateTime date =
              DateTime.parse(commit['commit']['author']['date']).toUtc();
          DateTime dateKey = DateTime.utc(date.year, date.month, date.day);

          String commitMessage = commit['commit']['message'];
          String htmlUrl = commit['html_url'];

          newCommitData[dateKey] = (newCommitData[dateKey] ?? [])
            ..add(CommitInfo(
                message: commitMessage, htmlUrl: htmlUrl, date: date));
        }

        setState(() {
          commitData = newCommitData;

          if (selectedDay != null && commitData.containsKey(selectedDay)) {
            selectedCommits = commitData[selectedDay];
          }

          isLoading = false;
        });
      } else {
        throw Exception(
            'Failed to load commits with status code: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => isLoading = false);

      showErrorDialog('Error fetching commits: $e');
    }
  }

  void _showModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SizedBox(
          height: 400,
          width: 450,
          child: Column(
            children: [
              const Text(
                "Select Repository",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              ),
              Expanded(
                child: Scrollbar(
                  thumbVisibility: true,
                  thickness: 6.0,
                  radius: const Radius.circular(5),
                  child: ListView.builder(
                    itemCount: repositories.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(
                          repositories[index],
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w400),
                        ),
                        onTap: () {
                          setState(() {
                            selectedRepository = repositories[index];
                            fetchCommitsForMonth(focusedDay);
                          });
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> fetchRepositories(String username) async {
    try {
      setState(() => isLoading = true);

      List<String> repoNames = await fetchRepositoriesFromAPI(username);

      setState(() {
        isLoading = false;
        repositories = repoNames;

        WidgetsBinding.instance
            .addPostFrameCallback((_) => _showModal(context));
        selectedRepository =
            repositories.isNotEmpty ? repositories.first : null;

        fetchCommitsForMonth(focusedDay);
      });
    } catch (e) {
      setState(() => isLoading = false);

      showErrorDialog('Failed to load repositories: $e');
    }
  }

  void showErrorDialog(String message) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Error'),
              content: Text(message),
              actions: <Widget>[
                TextButton(
                  child: const Text('OK'),
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
          'Commit Heatmap',
          style: TextStyle(
              fontSize: 23, color: Colors.white, fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(
              height: 400,
              child: TableCalendar(
                headerStyle: const HeaderStyle(
                  titleCentered: true,
                ),
                selectedDayPredicate: (day) {
                  return isSameDay(selectedDay, day);
                },
                focusedDay: focusedDay,
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2025, 12, 31),
                eventLoader: (day) => commitData[day] ?? [],
                onPageChanged: (focusedDay) {
                  this.focusedDay = focusedDay;

                  fetchCommitsForMonth(focusedDay);
                },
                onDaySelected: onDaySelected,
                rangeStartDay: _rangeStart,
                rangeEndDay: _rangeEnd,
                availableCalendarFormats: const {
                  CalendarFormat.month: 'Month',
                },
                calendarStyle: const CalendarStyle(
                  selectedDecoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
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
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 10),
            SizedBox(
              height: 300,
              child: Scrollbar(
                thumbVisibility: true,
                thickness: 4.0,
                radius: const Radius.circular(5.0),
                child: CommitList(
                  commits: selectedCommits ?? [],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> showCommitStatsForPeriod(
      BuildContext context, String username, String? selectedRepository) async {
    if (selectedRepository == null ||
        _rangeStart == null ||
        _rangeEnd == null) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text(selectedRepository == null
                ? 'No repository selected'
                : 'No date range selected'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 12,
                  height: 235,
                ),
                Text(
                  "Calculating commit statistics...",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      List<CommitInfo> allCommits =
          await fetchAllCommits(username, selectedRepository);

      Map<String, int> commitCountsByMonth = {};

      for (var commit in allCommits) {
        if (commit.date.isAfter(_rangeStart!) &&
            commit.date.isBefore(_rangeEnd!.add(const Duration(days: 1)))) {
          String monthYear = DateFormat('yyyy-MM').format(commit.date);
          commitCountsByMonth[monthYear] =
              (commitCountsByMonth[monthYear] ?? 0) + 1;
        }
      }

      var sortedKeys = commitCountsByMonth.keys.toList()..sort();
      List<TableRow> tableRows = sortedKeys.map((monthYear) {
        return TableRow(
          children: [
            TableCell(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(monthYear),
              ),
            ),
            TableCell(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(commitCountsByMonth[monthYear].toString()),
              ),
            ),
          ],
        );
      }).toList();

      int totalCommits =
          commitCountsByMonth.values.fold(0, (sum, count) => sum + count);

      tableRows.add(
        TableRow(
          children: [
            const TableCell(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Total'),
              ),
            ),
            TableCell(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(totalCommits.toString()),
              ),
            ),
          ],
        ),
      );

      if (mounted) {
        Navigator.of(context).pop();
        showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: const Text('Commit Statistic'),
                  content: SingleChildScrollView(
                    child: Table(
                      border: TableBorder.all(),
                      children: [
                        const TableRow(
                          children: [
                            TableCell(
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('Month'),
                              ),
                            ),
                            TableCell(
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('Commits'),
                              ),
                            ),
                          ],
                        ),
                        ...tableRows,
                      ],
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                ));
      }
    } catch (e) {
      if (mounted) {
        showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: const Text('Error'),
                  content: Text('Failed to load commits: $e'),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'OK',
                      ),
                    ),
                  ],
                ));
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
}
