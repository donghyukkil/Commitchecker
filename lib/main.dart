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
        debugShowCheckedModeBanner: false,
        title: 'GitHub Commit Heatmap',
        theme: ThemeData(
          primarySwatch: Colors.green,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.green,
            title: const Text(
              "Commit Checker",
              style: TextStyle(
                fontSize: 23,
              ),
            ),
          ),
          body: Column(children: [
            const SizedBox(height: 40),
            Image.asset(
              'assets/images/lawncheck.png',
              width: 300,
              height: 200,
            ),
            const Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: SizedBox(
                  width: 500,
                  child: InputPage(),
                ),
              ),
            )
          ]),
        ));
  }
}
