import 'package:flutter/material.dart';

import 'package:commitchecker/models/commit_info.dart';
import 'package:commitchecker/screens/web_view_page.dart';

class CommitList extends StatelessWidget {
  final List<CommitInfo>? commits;

  const CommitList({
    Key? key,
    required this.commits,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (commits == null) {
      return const Padding(
        padding: EdgeInsets.only(top: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              'Select a date',
              style: TextStyle(fontSize: 18.0),
            ),
          ],
        ),
      );
    }

    if (commits!.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              'No commits',
              style: TextStyle(fontSize: 18.0),
            ),
          ],
        ),
      );
    }

    return Scrollbar(
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
              title: Text(
                commit.message,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                ),
              ),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            WebViewPage(url: commit.htmlUrl)));
              },
            ),
          );
        },
      ),
    );
  }
}
