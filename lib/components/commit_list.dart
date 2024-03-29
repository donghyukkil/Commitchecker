import 'package:flutter/material.dart';

import 'package:commitchecker/models/commit_info.dart';
import 'package:commitchecker/views/web_view_page.dart';

class CommitList extends StatelessWidget {
  final List<CommitInfo>? commits;

  const CommitList({
    Key? key,
    required this.commits,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (commits == null || commits!.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 20.0),
        child: Text(
          commits == null ? 'Select a date' : 'No commits',
          style: const TextStyle(fontSize: 18.0),
        ),
      );
    }

    return Scrollbar(
      thumbVisibility: true,
      thickness: 5.0,
      child: ListView.builder(
        itemCount: commits!.length,
        itemBuilder: (context, index) {
          final commit = commits![index];

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(5),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                vertical: 1.0,
                horizontal: 16.0,
              ),
              title: Text(
                commit.message,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 12.5,
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WebViewPage(
                      url: commit.htmlUrl,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
