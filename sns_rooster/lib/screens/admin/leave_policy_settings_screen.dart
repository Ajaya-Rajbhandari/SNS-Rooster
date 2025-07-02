import 'package:flutter/material.dart';

class LeavePolicySettingsScreen extends StatelessWidget {
  const LeavePolicySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leave Policy Settings')),
      body: const Center(
        child: Text('Configure leave policies here.'),
      ),
    );
  }
}
