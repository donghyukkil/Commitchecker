import 'package:flutter/material.dart';

import 'package:webview_flutter/webview_flutter.dart';

class WebViewPage extends StatefulWidget {
  final String url;

  const WebViewPage({Key? key, required this.url}) : super(key: key);

  @override
  _WebViewPageState createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late WebViewController controller;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    final url = widget.url;

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..loadRequest(Uri.parse(url))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (request) => setState(
            () => isLoading = true,
          ),
          onPageFinished: (request) => setState(
            () => isLoading = false,
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(
      context,
    ).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Commit Checker',
          style: TextStyle(
            fontSize: 23,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.green,
      ),
      body: Stack(
        children: [
          Opacity(
            opacity: isLoading ? 0.0 : 1.0,
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: WebViewWidget(controller: controller),
            ),
          ),
          Center(
            child: Visibility(
              visible: isLoading,
              child: const CircularProgressIndicator(),
            ),
          ),
        ],
      ),
    );
  }
}
