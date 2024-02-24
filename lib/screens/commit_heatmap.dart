import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

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
  DateTime focusedDay = DateTime.now();
  DateTime? selectedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  Map<DateTime, List<CommitInfo>> commitData = {};
  List<CommitInfo>? selectedCommits;
  List<String> repositories = [];
  bool isLoading = false;
  String? selectedRepository;
  String? mostActiveDay;
  String? mostActiveTime;
  late ScrollController controller;
  final httpClient = http.Client();

  @override
  void initState() {
    super.initState();
    controller = ScrollController();
    fetchRepositories(widget.username);
  }

  @override
  void dispose() {
    controller.dispose();
    httpClient.close();
    super.dispose();
  }

  Future<void> fetchRepositories(String username) async {
    try {
      List<String> repoNames = await fetchRepositoriesFromAPI(
        username,
        client: httpClient,
      );

      setState(() {
        repositories = repoNames;
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _showModal(context));
        selectedRepository =
            repositories.isNotEmpty ? repositories.first : null;
        fetchCommitsForMonth(focusedDay);
      });
    } catch (e) {
      showErrorDialog(
        'Failed to load repositories. \nPlease enter the correct user',
      );
    }
  }

  void fetchCommitsForMonth(DateTime targetDate) async {
    String? repository = selectedRepository;

    if (repository == null) {
      return;
    }

    DateTime startOfMonth = DateTime(targetDate.year, targetDate.month, 1);
    DateTime endOfMonth = DateTime(targetDate.year, targetDate.month + 1, 1)
        .subtract(const Duration(days: 1));

    try {
      Map<DateTime, List<CommitInfo>> newCommitData = {};

      List<CommitInfo> commits = await fetchAllCommits(
        widget.username,
        repository,
        startOfMonth: startOfMonth,
        endOfMonth: endOfMonth,
        client: httpClient,
      );

      for (var commit in commits) {
        DateTime dateKey =
            DateTime.utc(commit.date.year, commit.date.month, commit.date.day);

        if (!newCommitData.containsKey(dateKey)) {
          newCommitData[dateKey] = [];
        }

        newCommitData[dateKey]!.add(commit);
      }

      setState(() {
        commitData = newCommitData;
        selectedCommits = commitData[selectedDay] ?? [];
      });
    } catch (e) {
      showErrorDialog('Error fetching commits: $e');
    }
  }

  String formatDate(DateTime? date) {
    if (date == null) {
      return 'No Date Selected';
    }

    return DateFormat('yyyy-MM-dd EEEE').format(date);
  }

  void onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (_rangeStart == null || _rangeEnd != null) {
      setState(() {
        this.selectedDay = selectedDay;
        _rangeStart = selectedDay;

        selectedCommits = commitData[selectedDay] ?? [];
      });
    } else if (selectedDay.isBefore(_rangeStart!)) {
      setState(() {
        this.selectedDay = selectedDay;
        _rangeStart = selectedDay;

        selectedCommits = commitData[selectedDay] ?? [];
      });
    } else if (_rangeStart != null && selectedDay.isAfter(_rangeStart!)) {
      setState(() {
        _rangeEnd = selectedDay;
      });

      showCommitStatsForPeriod(
        context,
        widget.username,
        selectedRepository,
      );
    }
  }

  Future<void> showCommitStatsForPeriod(
      BuildContext context, String username, String? selectedRepository) async {
    if (repositories.isEmpty) {
      _rangeStart = null;
      _rangeEnd = null;
      selectedDay = null;

      showErrorDialog(
        'No repositories found. \nPlease enter the correct user.',
      );

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
      List<CommitInfo> allCommits = await fetchAllCommits(
          username, selectedRepository!,
          client: httpClient);

      List<CommitInfo> filteredCommits = allCommits.where((commit) {
        return commit.date.isAfter(_rangeStart!) &&
            commit.date.isBefore(_rangeEnd!.add(const Duration(days: 1)));
      }).toList();

      String? mostActiveDay = calculateMostActiveDay(selectedCommits!);
      String? mostActiveTime = calculateMostActiveTime(selectedCommits!);

      Map<String, int> commitCountsByMonth = {};

      for (var commit in filteredCommits) {
        String monthYear = DateFormat('yyyy-MM').format(commit.date);
        commitCountsByMonth[monthYear] =
            (commitCountsByMonth[monthYear] ?? 0) + 1;
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

      int totalCommits = filteredCommits.length;

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
                  title: const Text('Commits Statistic'),
                  content: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Most Active Day: $mostActiveDay'),
                        const SizedBox(height: 5),
                        Text('Most Active Time: $mostActiveTime'),
                        const SizedBox(height: 20),
                        Table(
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
                      ],
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _rangeStart = null;
                          _rangeEnd = null;
                          selectedCommits = null;
                          selectedDay = null;
                        });
                        Navigator.of(context).pop();
                      },
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
                  content: const Text(
                    'Failed to load commits',
                  ),
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
    }
  }

  String calculateMostActiveDay(List<CommitInfo> commits) {
    Map<int, int> commitCountByWeekday = {
      DateTime.monday: 0,
      DateTime.tuesday: 0,
      DateTime.wednesday: 0,
      DateTime.thursday: 0,
      DateTime.friday: 0,
      DateTime.saturday: 0,
      DateTime.sunday: 0,
    };

    for (var commit in commits) {
      int weekday = commit.date.weekday;
      commitCountByWeekday[weekday] = (commitCountByWeekday[weekday] ?? 0) + 1;
    }

    int maxCommitCount = 0;
    int mostActiveWeekday = DateTime.monday;
    commitCountByWeekday.forEach((weekday, commitCount) {
      if (commitCount > maxCommitCount) {
        maxCommitCount = commitCount;
        mostActiveWeekday = weekday;
      }
    });

    return _weekdayToString(mostActiveWeekday);
  }

  String calculateMostActiveTime(List<CommitInfo> commits) {
    Map<int, int> commitCountByHour = {};

    for (int i = 0; i < 24; i++) {
      commitCountByHour[i] = 0;
    }

    for (var commit in commits) {
      int hour = commit.date.hour;
      commitCountByHour[hour] = (commitCountByHour[hour] ?? 0) + 1;
    }

    int maxCommitCount = 0;
    int mostActiveHour = 0;
    commitCountByHour.forEach((hour, commitCount) {
      if (commitCount > maxCommitCount) {
        maxCommitCount = commitCount;
        mostActiveHour = hour;
      }
    });

    return '$mostActiveHour:00';
  }

  String _weekdayToString(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      default:
        return '';
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
                            selectedDay = null;
                            _rangeStart = null;
                            _rangeEnd = null;
                            focusedDay = DateTime.now();
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Commit Heatmap',
          style: TextStyle(
            fontSize: 23,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            onPressed: () {
              _showModal(context);
            },
            icon: const Icon(Icons.folder_open),
          ),
        ],
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
                    color: Colors.purple,
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
                          width: 9.0,
                          height: 9.0,
                        ),
                      );
                    }

                    return null;
                  },
                ),
              ),
            ),
            if (_rangeStart != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formatDate(_rangeStart),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Commits: ${commitData[_rangeStart]?.length ?? 0}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 10),
            SizedBox(
              height: 300,
              child: CommitList(
                commits: selectedDay == null ? null : selectedCommits,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
