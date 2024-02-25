import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import 'package:commitchecker/models/commit_info.dart';
import 'package:commitchecker/repositories/github_api.dart';

class CommitHeatmapViewModel extends ChangeNotifier {
  String? selectedRepository;
  String? mostActiveDay;
  String? mostActiveTime;
  String _username;
  String errorMessage = '';
  String commitStatsMessage = "";
  DateTime focusedDay = DateTime.now();
  DateTime? selectedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  DateTime? get rangeStart => _rangeStart;
  DateTime? get rangeEnd => _rangeEnd;
  Map<DateTime, List<CommitInfo>> commitData = {};
  List<CommitInfo>? selectedCommits;
  List<String> repositories = [];
  bool isLoading = false;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  CalendarFormat get calendarFormat => _calendarFormat;
  final GitHubRepository _gitHubRepository;
  Function(String)? onError;

  CommitHeatmapViewModel(
    this._gitHubRepository,
    this._username, {
    this.onError,
  });

  Future<void> fetchCommitsForMonth(DateTime targetDate) async {
    if (selectedRepository == null || _username.isEmpty) {
      return;
    }

    try {
      DateTime startOfMonth = DateTime(
        targetDate.year,
        targetDate.month,
        1,
      );
      DateTime endOfMonth = DateTime(
        targetDate.year,
        targetDate.month + 1,
        0,
      ).subtract(
        const Duration(days: 1),
      );

      List<CommitInfo> commits = await _gitHubRepository.fetchAllCommits(
        _username,
        selectedRepository!,
        startOfMonth: startOfMonth,
        endOfMonth: endOfMonth,
      );

      commitData = {};

      for (var commit in commits) {
        DateTime dateKey = DateTime.utc(
          commit.date.year,
          commit.date.month,
          commit.date.day,
        );

        if (!commitData.containsKey(dateKey)) {
          commitData[dateKey] = [];
        }

        commitData[dateKey]!.add(commit);
      }

      selectedCommits = commitData[selectedDay] ?? [];
    } catch (e) {
      onError?.call(
        'Failed to load repositories. \nPlease enter the correct user',
      );
    } finally {
      notifyListeners();
    }
  }

  Future<void> fetchRepositories([String? username]) async {
    try {
      repositories = await _gitHubRepository.fetchRepositories(username ?? '');

      fetchCommitsForMonth(focusedDay);
    } catch (e) {
      onError?.call(
        'Error fetching repositories',
      );
    } finally {
      notifyListeners();
    }
  }

  Future<void> setSelectedRepository(String repository) async {
    selectedRepository = repository;
    _rangeStart = null;
    _rangeEnd = null;
    selectedDay = null;
    focusedDay = DateTime.now();

    await fetchCommitsForMonth(focusedDay);

    return;
  }

  Future<int> calculateCommitsForRange(DateTime start, DateTime end) async {
    int totalCommits = 0;

    try {
      DateTime adjustedEndDate = end.add(
        const Duration(days: 1),
      );

      List<CommitInfo> commits = await _gitHubRepository.fetchAllCommits(
        _username,
        selectedRepository!,
        startOfMonth: start,
        endOfMonth: adjustedEndDate,
      );

      totalCommits = commits.length;
    } catch (e) {
      onError?.call(
        'Failed to calculate commits for the selected range',
      );
    }

    return totalCommits;
  }

  void setUsername(String username) {
    _username = username;

    fetchRepositories(username);
  }

  void setCalendarFormat(CalendarFormat format) {
    _calendarFormat = format;

    notifyListeners();
  }

  void setFocusedDay(DateTime focusedDay) {
    this.focusedDay = focusedDay;

    fetchCommitsForMonth(focusedDay);

    notifyListeners();
  }

  void onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    this.focusedDay = focusedDay;

    if (_rangeStart == null || _rangeEnd != null) {
      _rangeStart = selectedDay;
      _rangeEnd = null;

      selectedCommits = commitData[selectedDay] ?? [];

      notifyListeners();
    } else if (selectedDay.isBefore(_rangeStart!)) {
      _rangeStart = selectedDay;

      selectedCommits = commitData[selectedDay] ?? [];

      notifyListeners();
    } else if (_rangeStart != null && selectedDay.isAfter(_rangeStart!)) {
      _rangeEnd = selectedDay;

      notifyListeners();
    }
  }

  String formatDate(DateTime? date) {
    if (date == null) return '';

    return DateFormat('yyyy-MM-dd').format(
      date,
    );
  }

  void toggleTwoWeeksFormat() {
    _calendarFormat = (_calendarFormat == CalendarFormat.twoWeeks)
        ? CalendarFormat.month
        : CalendarFormat.twoWeeks;

    notifyListeners();
  }
}
