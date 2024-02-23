import 'package:flutter/material.dart';
import 'package:commitchecker/screens/inputpage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GitHub Commit Heatmap',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isGifShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showGifModal(context));
  }

  void _showGifModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text(
                    "Welcome to Commit Checker!",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 800,
                    height: 400,
                    child: Image.asset(
                      'assets/preview.gif',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Start'),
                  )
                ],
              ),
            ),
          ),
        );
      },
    ).then((value) => setState(() {
          _isGifShown = true;
        }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text(
          'Commit Checker',
          style: TextStyle(
              fontSize: 23, color: Colors.white, fontWeight: FontWeight.w500),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (_isGifShown)
              SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 60, horizontal: 100),
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
                    ],
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }
}
