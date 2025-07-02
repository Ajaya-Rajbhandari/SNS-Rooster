import 'package:flutter/material.dart';

class PayrollCycleSettingsScreen extends StatelessWidget {
  const PayrollCycleSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payroll Cycle Settings')),
      body: const Center(
        child: Text('Configure payroll cycles here.'),
      ),
    );
  }
}
