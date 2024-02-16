import 'package:flutter/material.dart';
import "package:commitchecker/screens/inputpage.dart";

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
          body: const InputPage()),
    );
  }
}
