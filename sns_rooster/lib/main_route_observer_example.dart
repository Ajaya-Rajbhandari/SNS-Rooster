import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    Provider<RouteObserver<ModalRoute<void>>>(
      create: (_) => RouteObserver<ModalRoute<void>>(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Add your routes and home here
      home: Scaffold(
        appBar: AppBar(title: const Text('SNS Rooster App')),
        body: const Center(child: Text('Replace with your app entry point.')),
      ),
    );
  }
}
