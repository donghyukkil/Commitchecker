import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

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
  Map<DateTime, List> commitData = {
    DateTime.utc(2024, 2, 5): ['Commit'],
    DateTime.utc(2024, 2, 6): ['Commit', 'Commit'],
  };

  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      firstDay: DateTime.utc(2023, 1, 1),
      lastDay: DateTime.utc(2024, 12, 31),
      focusedDay: DateTime.now(),
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, day, focusedDay) {
          var commitCount =
              commitData[day] != null ? commitData[day]!.length : 0;
          return Center(
            child: Text(
              '${day.day}',
              style: TextStyle(color: getColorForCommitCount(commitCount)),
            ),
          );
        },
      ),
    );
  }

  Color getColorForCommitCount(int count) {
    if (count == 0) return Colors.grey;
    if (count == 1) return Colors.green.shade200;
    if (count >= 2) return Colors.green.shade400;
    return Colors.grey;
  }
}
