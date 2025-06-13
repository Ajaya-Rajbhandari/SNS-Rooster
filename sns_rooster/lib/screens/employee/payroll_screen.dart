import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/payroll_provider.dart';
import 'package:intl/intl.dart';
import '../../widgets/app_drawer.dart';

class PayrollScreen extends StatefulWidget {
  const PayrollScreen({super.key});

  @override
  State<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<PayrollScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch payroll slips when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PayrollProvider>(context, listen: false).fetchPayrollSlips();
    });
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

            return ListView(
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
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 28),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  slip['payPeriod'] ?? '-',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Chip(
                                label: Text(
                                    'Net Pay: ${slip['netPay'].toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
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
                                  style:
                                      Theme.of(context).textTheme.bodyMedium),
                              const SizedBox(width: 16),
                              Icon(Icons.remove_circle,
                                  color: Colors.red[700], size: 22),
                              const SizedBox(width: 6),
                              Text(
                                  'Deductions: -${slip['deductions'].toStringAsFixed(2)}',
                                  style:
                                      Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                              'Issued: ${DateFormat('MMM d, y').format(DateTime.parse(slip['issueDate']))}',
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
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            );
          }
        },
      ),
    );
  }
}
