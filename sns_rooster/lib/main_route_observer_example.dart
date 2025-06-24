import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    Provider<RouteObserver<ModalRoute<void>>>(
      create: (_) => RouteObserver<ModalRoute<void>>(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Add your routes and home here
      home: Scaffold(
        appBar: AppBar(title: Text('SNS Rooster App')),
        body: Center(child: Text('Replace with your app entry point.')),
      ),
    );
  }
}
