import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';

import 'package:commitchecker/viewmodels/commit_heatmap_viewmodel.dart';
import 'package:commitchecker/components/commit_list.dart';

class CommitHeatmap extends StatefulWidget {
  final String username;

  const CommitHeatmap({
    Key? key,
    required this.username,
  }) : super(key: key);

  @override
  _CommitHeatmapState createState() => _CommitHeatmapState();
}

class _CommitHeatmapState extends State<CommitHeatmap> {
  late ScrollController controller;
  late final CommitHeatmapViewModel viewModel;

  void _showBottomSheet(BuildContext context) {
    final viewModel = Provider.of<CommitHeatmapViewModel>(
      context,
      listen: false,
    );

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SizedBox(
          height: 300,
          child: Scrollbar(
            thumbVisibility: true,
            thickness: 5.0,
            child: ListView.builder(
              itemCount: viewModel.repositories.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Text(viewModel.repositories[index]),
                  onTap: () {
                    Navigator.pop(context);
                    viewModel.setSelectedRepository(
                      viewModel.repositories[index],
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    controller = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback(
      (_) async {
        final viewModel = Provider.of<CommitHeatmapViewModel>(
          context,
          listen: false,
        );

        viewModel.setUsername(widget.username);

        try {
          await viewModel.fetchRepositories(widget.username);
          if (viewModel.repositories.isEmpty) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('This user has no repositories.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } else {
            if (mounted) {
              _showBottomSheet(context);
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('An error occurred while fetching repositories.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
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
        actions: [
          IconButton(
            onPressed: () {
              _showBottomSheet(context);
            },
            icon: const Icon(
              Icons.folder_open,
            ),
          ),
        ],
        backgroundColor: Colors.green,
      ),
      body: Consumer<CommitHeatmapViewModel>(
        builder: (context, viewModel, child) {
          return Column(
            children: [
              TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2025, 12, 31),
                focusedDay: viewModel.focusedDay,
                rangeStartDay: viewModel.rangeStart,
                rangeEndDay: viewModel.rangeEnd,
                selectedDayPredicate: (day) => isSameDay(
                  viewModel.selectedDay,
                  day,
                ),
                onDaySelected: (selectedDay, focusedDay) {
                  viewModel.selectedDay = selectedDay;
                  viewModel.focusedDay = focusedDay;
                  viewModel.selectedCommits =
                      viewModel.commitData[selectedDay] ?? [];
                  viewModel.onDaySelected(
                    selectedDay,
                    focusedDay,
                  );
                },
                onPageChanged: (focusedDay) {
                  viewModel.setFocusedDay(focusedDay);
                },
                eventLoader: (day) => viewModel.commitData[day] ?? [],
                calendarFormat: viewModel.calendarFormat,
                onFormatChanged: (format) {
                  viewModel.setCalendarFormat(format);
                },
                calendarStyle: CalendarStyle(
                  rangeHighlightColor: Colors.blue.withOpacity(0.5),
                  rangeStartDecoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  rangeEndDecoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: const BoxDecoration(
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
                          margin: const EdgeInsets.only(
                            bottom: 3,
                          ),
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
              const SizedBox(
                height: 20,
              ),
              const Divider(
                color: Colors.grey,
                height: 1,
                thickness: 1,
              ),
              SizedBox(
                height: 80,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 17,
                        bottom: 9,
                        right: 60,
                      ),
                      child: Text(
                        'Selected Period: ${viewModel.rangeStart != null ? viewModel.rangeStart.toString().substring(0, 10) : '                     '} - ${viewModel.rangeEnd != null ? viewModel.rangeEnd.toString().substring(0, 10) : '                      '}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    FutureBuilder<int>(
                      future: viewModel.rangeStart != null &&
                              viewModel.rangeEnd != null
                          ? viewModel.calculateCommitsForRange(
                              viewModel.rangeStart!,
                              viewModel.rangeEnd!,
                            )
                          : Future.value(
                              0,
                            ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Text(
                            'Loading...',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        } else if (snapshot.hasError) {
                          return Text(
                            'Error: ${snapshot.error}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        } else {
                          return Padding(
                            padding: const EdgeInsets.only(
                              top: 5,
                              right: 30,
                            ),
                            child: Text(
                              'Total Commits: ${snapshot.data.toString()}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              const Divider(
                color: Colors.grey,
                height: 1,
                thickness: 1,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      viewModel.formatDate(
                        viewModel.selectedDay,
                      ),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Commits: ${viewModel.commitData[viewModel.selectedDay]?.length ?? 0}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: CommitList(
                  commits: viewModel.selectedCommits,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
