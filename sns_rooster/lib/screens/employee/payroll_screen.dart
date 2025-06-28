import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/payroll_provider.dart';
import 'package:intl/intl.dart';
import '../../widgets/app_drawer.dart';
// Import to access the RouteObserver

class PayrollScreen extends StatefulWidget {
  const PayrollScreen({super.key});

  @override
  State<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<PayrollScreen> with RouteAware {
  RouteObserver<ModalRoute<void>>? _routeObserver;

  void _refreshPayroll() {
    print('PayrollScreen: _refreshPayroll called');
    final provider = Provider.of<PayrollProvider>(context, listen: false);
    provider.clearPayrollData();
    provider.fetchPayrollSlips();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _routeObserver = Provider.of<RouteObserver<ModalRoute<void>>>(context);
    _routeObserver?.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    _routeObserver?.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPush() {
    print('PayrollScreen: didPush called');
    _refreshPayroll();
  }

  @override
  void didPopNext() {
    print('PayrollScreen: didPopNext called');
    _refreshPayroll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payroll'),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu), // Hamburger icon
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
      ),
      drawer: const AppDrawer(),
      body: Consumer<PayrollProvider>(
        builder: (context, payrollProvider, child) {
          if (payrollProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (payrollProvider.error != null) {
            return Center(
              child: Text('Error: ${payrollProvider.error}'),
            );
          } else if (payrollProvider.payrollSlips.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No payroll slips available.',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Your payslips will appear here when available.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.grey[500])),
                ],
              ),
            );
          } else {
            // --- Payroll Summary ---
            final totalNetPay = payrollProvider.payrollSlips
                .fold<double>(0, (sum, slip) => sum + (slip['netPay'] ?? 0));
            final mostRecentSlip = payrollProvider.payrollSlips.first;
            final lastPayPeriod = mostRecentSlip['payPeriod'] ?? '-';
            final lastPaymentDate = mostRecentSlip['issueDate'] != null
                ? DateFormat('MMM d, y')
                    .format(DateTime.parse(mostRecentSlip['issueDate']))
                : '-';

            return RefreshIndicator(
              onRefresh: () async {
                _refreshPayroll();
                // Wait for provider to finish loading
                while (Provider.of<PayrollProvider>(context, listen: false)
                    .isLoading) {
                  await Future.delayed(const Duration(milliseconds: 100));
                }
              },
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // --- Summary Card ---
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: Theme.of(context).colorScheme.primary,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 20, horizontal: 24),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.white,
                            radius: 28,
                            child: Icon(Icons.account_balance_wallet,
                                color: Theme.of(context).colorScheme.primary,
                                size: 28),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Total Net Pay',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        )),
                                Text(totalNetPay.toStringAsFixed(2),
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        )),
                                const SizedBox(height: 8),
                                Text('Last Pay Period: $lastPayPeriod',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: Colors.white70)),
                                Text('Last Payment: $lastPaymentDate',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: Colors.white70)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // --- Payslip Cards ---
                  ...payrollProvider.payrollSlips.map((slip) {
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.calendar_month,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    size: 28),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    slip['payPeriod']?.toString() ?? '-',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Chip(
                                  label: Text(
                                      'Net Pay: ' +
                                          (slip['netPay'] != null
                                              ? (slip['netPay'] is num
                                                  ? slip['netPay']
                                                      .toStringAsFixed(2)
                                                  : slip['netPay'].toString())
                                              : '-'),
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold)),
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                ),
                                _buildStatusIndicator(
                                    slip['status']?.toString()),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(Icons.payments,
                                    color: Colors.green[700], size: 22),
                                const SizedBox(width: 6),
                                Text(
                                    'Gross: ' +
                                        (slip['grossPay'] != null
                                            ? (slip['grossPay'] is num
                                                ? slip['grossPay']
                                                    .toStringAsFixed(2)
                                                : slip['grossPay'].toString())
                                            : '-'),
                                    style:
                                        Theme.of(context).textTheme.bodyMedium),
                                const SizedBox(width: 16),
                                Icon(Icons.remove_circle,
                                    color: Colors.red[700], size: 22),
                                const SizedBox(width: 6),
                                Text(
                                    'Deductions: -' +
                                        (slip['deductions'] != null
                                            ? (slip['deductions'] is num
                                                ? slip['deductions']
                                                    .toStringAsFixed(2)
                                                : slip['deductions'].toString())
                                            : '-'),
                                    style:
                                        Theme.of(context).textTheme.bodyMedium),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                                'Issued: ${slip['issueDate'] != null ? DateFormat('MMM d, y').format(DateTime.tryParse(slip['issueDate']) ?? DateTime(1970)) : '-'}',
                                style: Theme.of(context).textTheme.bodySmall),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  // TODO: Implement PDF view/download functionality
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('PDF download coming soon!')),
                                  );
                                },
                                icon: const Icon(Icons.download),
                                label: const Text('Download Payslip (PDF)'),
                              ),
                            ),
                            if ((slip['status']?.toString() ?? '') ==
                                    'needs_review' &&
                                (slip['employeeComment']?.toString() ?? '')
                                    .isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                    'Your Comment: ${slip['employeeComment']}',
                                    style: const TextStyle(color: Colors.red)),
                              ),
                            if (((slip['status']?.toString() ?? '') ==
                                        'pending' ||
                                    (slip['status']?.toString() ?? '') ==
                                        'needs_review') &&
                                (slip['adminResponse'] ?? '').isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  'Admin Response: ${slip['adminResponse']}',
                                  style: const TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            if ((slip['status']?.toString() ?? '') == 'pending')
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.check),
                                    label: const Text('Acknowledge'),
                                    onPressed: () async {
                                      await payrollProvider.updatePayslipStatus(
                                          slip['_id'], 'approved');
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content:
                                                Text('Payslip acknowledged.')),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.help),
                                    label: const Text('Request Clarification'),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red),
                                    onPressed: () async {
                                      final comment = await showDialog<String>(
                                        context: context,
                                        builder: (context) {
                                          String tempComment = '';
                                          return AlertDialog(
                                            title: const Text(
                                                'Request Clarification'),
                                            content: TextField(
                                              autofocus: true,
                                              decoration: const InputDecoration(
                                                  labelText: 'Comment'),
                                              onChanged: (val) =>
                                                  tempComment = val,
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: const Text('Cancel'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () => Navigator.pop(
                                                    context, tempComment),
                                                child: const Text('Submit'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                      if (comment != null &&
                                          comment.trim().isNotEmpty) {
                                        await payrollProvider
                                            .updatePayslipStatus(
                                                slip['_id'], 'needs_review',
                                                comment: comment.trim());
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'Clarification requested.')),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildStatusIndicator(String? status) {
    if (status == 'approved') {
      return const Row(children: [
        Icon(Icons.check_circle, color: Colors.green, size: 20),
        SizedBox(width: 4),
        Text('Approved',
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
      ]);
    } else if (status == 'needs_review') {
      return const Row(children: [
        Icon(Icons.error, color: Colors.red, size: 20),
        SizedBox(width: 4),
        Text('Needs Review',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
      ]);
    } else {
      return const Row(children: [
        Icon(Icons.access_time, color: Colors.orange, size: 20),
        SizedBox(width: 4),
        Text('Pending',
            style:
                TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
      ]);
    }
  }
}
