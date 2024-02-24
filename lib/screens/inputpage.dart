import 'package:flutter/material.dart';

import 'package:commitchecker/screens/commit_heatmap.dart';

class InputPage extends StatefulWidget {
  const InputPage({super.key});

  @override
  _InputPageState createState() => _InputPageState();
}

class _InputPageState extends State<InputPage> {
  final TextEditingController _usernameController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  void _navigateToCommitHeatmap() {
    if (_usernameController.text.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              CommitHeatmap(username: _usernameController.text),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 70),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'GitHub Username',
                hintText: 'Enter your GitHub ID',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              onSubmitted: (String value) {
                _navigateToCommitHeatmap();
              },
              textInputAction: TextInputAction.go,
            ),
          ],
        ),
      ),
    );
  }
}
