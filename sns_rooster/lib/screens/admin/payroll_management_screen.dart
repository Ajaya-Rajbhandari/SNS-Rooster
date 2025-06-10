import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'edit_payslip_dialog.dart';

class PayrollManagementScreen extends StatefulWidget {
  const PayrollManagementScreen({super.key});

  @override
  State<PayrollManagementScreen> createState() =>
      _PayrollManagementScreenState();
}

class _PayrollManagementScreenState extends State<PayrollManagementScreen> {
  // Mock employee list
  final List<Map<String, String>> _employees = [
    {'id': '1', 'name': 'John Doe'},
    {'id': '2', 'name': 'Jane Smith'},
    {'id': '3', 'name': 'Alice Johnson'},
  ];
  String _selectedEmployeeId = '1';

  // Mock payslips per employee
  final Map<String, List<Map<String, dynamic>>> _mockPayslips = {
    '1': [
      {
        'payPeriod': 'May 2024',
        'issueDate': '2024-05-31',
        'grossPay': 3500.00,
        'deductions': 500.00,
        'netPay': 3000.00,
      },
      {
        'payPeriod': 'Apr 2024',
        'issueDate': '2024-04-30',
        'grossPay': 3500.00,
        'deductions': 450.00,
        'netPay': 3050.00,
      },
    ],
    '2': [
      {
        'payPeriod': 'May 2024',
        'issueDate': '2024-05-31',
        'grossPay': 4000.00,
        'deductions': 600.00,
        'netPay': 3400.00,
      },
    ],
    '3': [],
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final payslips = _mockPayslips[_selectedEmployeeId] ?? [];

    void _addPayslip() async {
      await showDialog(
        context: context,
        builder: (context) => EditPayslipDialog(
          onSave: (newPayslip) {
            setState(() {
              _mockPayslips[_selectedEmployeeId]!.insert(0, newPayslip);
            });
          },
        ),
      );
    }

    void _editPayslip(int idx) async {
      final payslip = payslips[idx];
      await showDialog(
        context: context,
        builder: (context) => EditPayslipDialog(
          initialData: payslip,
          onSave: (updatedPayslip) {
            setState(() {
              _mockPayslips[_selectedEmployeeId]![idx] = updatedPayslip;
            });
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payroll Management'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Employee selector
            Row(
              children: [
                const Text('Select Employee:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _selectedEmployeeId,
                  items: _employees
                      .map((emp) => DropdownMenuItem(
                            value: emp['id'],
                            child: Text(emp['name']!),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedEmployeeId = val);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Payslip list
            Expanded(
              child: payslips.isEmpty
                  ? Center(
                      child: Text('No payslips for this employee.',
                          style: theme.textTheme.bodyLarge),
                    )
                  : ListView.builder(
                      itemCount: payslips.length,
                      itemBuilder: (context, idx) {
                        final slip = payslips[idx];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          child: Padding(
                            padding: const EdgeInsets.all(18.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.calendar_month,
                                        color: theme.colorScheme.primary,
                                        size: 28),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        slip['payPeriod'] ?? '-',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                                fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Chip(
                                      label: Text(
                                          'Net Pay: ${slip['netPay'].toStringAsFixed(2)}',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold)),
                                      backgroundColor:
                                          theme.colorScheme.primary,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Icon(Icons.payments,
                                        color: Colors.green[700], size: 22),
                                    const SizedBox(width: 6),
                                    Text(
                                        'Gross: ${slip['grossPay'].toStringAsFixed(2)}',
                                        style: theme.textTheme.bodyMedium),
                                    const SizedBox(width: 16),
                                    Icon(Icons.remove_circle,
                                        color: Colors.red[700], size: 22),
                                    const SizedBox(width: 6),
                                    Text(
                                        'Deductions: -${slip['deductions'].toStringAsFixed(2)}',
                                        style: theme.textTheme.bodyMedium),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                    'Issued: ${DateFormat('MMM d, y').format(DateTime.parse(slip['issueDate']))}',
                                    style: theme.textTheme.bodySmall),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'Download coming soon!')),
                                        );
                                      },
                                      icon: const Icon(Icons.download),
                                      label: const Text('Download'),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton.icon(
                                      onPressed: () => _editPayslip(idx),
                                      icon: const Icon(Icons.edit),
                                      label: const Text('Edit'),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content:
                                                  Text('Delete coming soon!')),
                                        );
                                      },
                                      icon: const Icon(Icons.delete),
                                      label: const Text('Delete'),
                                      style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            // Add Payslip button
            Align(
              alignment: Alignment.bottomRight,
              child: FloatingActionButton.extended(
                onPressed: _addPayslip,
                icon: const Icon(Icons.add),
                label: const Text('Add Payslip'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
