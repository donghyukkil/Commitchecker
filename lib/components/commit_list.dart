import 'package:flutter/material.dart';
import 'package:commitchecker/models/commit_info.dart';
import 'package:commitchecker/screens/web_view_page.dart';

class CommitList extends StatelessWidget {
  final List<CommitInfo> commits;

  const CommitList({Key? key, required this.commits}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: commits.length,
      itemBuilder: (context, index) {
        final commit = commits[index];

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(5),
          ),
          margin: const EdgeInsets.symmetric(vertical: 2),
          child: ListTile(
            title: Text(
              commit.message,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
              ),
            ),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => WebViewPage(url: commit.htmlUrl)));
            },
          ),
        );
      },
    );
  }
}
