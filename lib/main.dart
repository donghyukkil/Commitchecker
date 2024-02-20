import 'package:flutter/material.dart';

import 'package:commitchecker/screens/inputpage.dart';

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
            'Commit Checker',
            style: TextStyle(
                fontSize: 23, color: Colors.white, fontWeight: FontWeight.w500),
          ),
        ),
        body: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: SingleChildScrollView(
            child: Column(children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 60, horizontal: 100),
                child: Image.asset(
                  'assets/images/lawncheck.png',
                  width: 400,
                  height: 300,
                ),
              ),
              const SizedBox(
                width: 400,
                height: 200,
                child: InputPage(),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
