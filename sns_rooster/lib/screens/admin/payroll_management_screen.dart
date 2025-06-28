import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_payroll_provider.dart';
import '../../providers/auth_provider.dart';
import 'edit_payslip_dialog.dart';
import '../../widgets/admin_side_navigation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../../config/api_config.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class PayrollManagementScreen extends StatefulWidget {
  const PayrollManagementScreen({super.key});

  @override
  State<PayrollManagementScreen> createState() =>
      _PayrollManagementScreenState();
}

class _PayrollManagementScreenState extends State<PayrollManagementScreen> {
  String? _selectedEmployeeId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminPayrollProvider>(context, listen: false)
          .fetchEmployees();
    });
  }

  void _onEmployeeChanged(String? employeeId) {
    if (employeeId == null) return;
    setState(() => _selectedEmployeeId = employeeId);
    Provider.of<AdminPayrollProvider>(context, listen: false)
        .fetchPayslips(employeeId);
  }

  void _addPayslip(BuildContext context, AdminPayrollProvider provider) async {
    final newPayslip = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => EditPayslipDialog(
        onSave: (_) {}, // No-op, dialog just pops with data now
      ),
    );
    if (newPayslip != null && _selectedEmployeeId != null) {
      await provider.addPayslip(newPayslip, _selectedEmployeeId!);
      await provider.fetchPayslips(_selectedEmployeeId!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payslip added successfully.')),
      );
    }
  }

  void _editPayslip(BuildContext scaffoldContext, AdminPayrollProvider provider,
      int idx) async {
    final payslip = provider.payslips[idx];
    final updatedPayslip = await showDialog<Map<String, dynamic>>(
      context: scaffoldContext,
      builder: (dialogContext) => EditPayslipDialog(
        initialData: payslip,
        onSave: (_) {}, // No-op, dialog just pops with data now
      ),
    );

    if (!mounted || updatedPayslip == null) return;
    try {
      await provider.editPayslip(payslip['_id'], updatedPayslip);
      if (_selectedEmployeeId != null) {
        await provider.fetchPayslips(_selectedEmployeeId!);
      }
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        const SnackBar(content: Text('Payslip updated successfully.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        SnackBar(content: Text('Error updating payslip: $e')),
      );
    }
  }

  void _deletePayslip(
      BuildContext context, AdminPayrollProvider provider, int idx) async {
    final payslip = provider.payslips[idx];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payslip'),
        content: const Text('Are you sure you want to delete this payslip?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await provider.deletePayslip(payslip['_id']);
        if (_selectedEmployeeId != null) {
          await provider.fetchPayslips(_selectedEmployeeId!);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Payslip deleted.'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () async {
                // Optionally, implement undo by re-adding the payslip (requires storing its data)
                await provider.addPayslip(payslip, _selectedEmployeeId!);
                await provider.fetchPayslips(_selectedEmployeeId!);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payslip restored.')),
                );
              },
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting payslip: $e')),
        );
      }
    }
  }

  Future<void> _downloadPayslipPdf(
      BuildContext context, String payslipId, String token) async {
    try {
      final url = '${ApiConfig.baseUrl}/payroll/$payslipId/pdf';
      final response = await http.get(Uri.parse(url), headers: {
        'Authorization': 'Bearer $token',
      });
      if (response.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/payslip-$payslipId.pdf');
        await file.writeAsBytes(response.bodyBytes);
        await OpenFile.open(file.path);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to download PDF: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error downloading PDF: $e')),
      );
    }
  }

  Future<void> _downloadAllPayslips(
      BuildContext context, String employeeId, String token,
      {bool asCsv = false}) async {
    try {
      final url = asCsv
          ? '${ApiConfig.baseUrl}/payroll/employee/$employeeId/csv'
          : '${ApiConfig.baseUrl}/payroll/employee/$employeeId/pdf';
      final response = await http.get(Uri.parse(url), headers: {
        'Authorization': 'Bearer $token',
      });
      if (response.statusCode == 200) {
        Directory? downloadsDir;
        if (!kIsWeb && Platform.isAndroid) {
          downloadsDir = Directory('/storage/emulated/0/Download');
        } else if (!kIsWeb &&
            (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
          downloadsDir = await getDownloadsDirectory();
        }
        downloadsDir ??= await getTemporaryDirectory();
        final ext = asCsv ? 'csv' : 'pdf';
        final file = File('${downloadsDir.path}/all-payslips-$employeeId.$ext');
        await file.writeAsBytes(response.bodyBytes);
        await OpenFile.open(file.path);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File saved to: ${file.path}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error downloading: $e')),
      );
    }
  }

  Widget _buildStatusIndicator(String? status, String? comment) {
    if (status == 'approved') {
      return const Row(children: [
        Icon(Icons.check_circle, color: Colors.green, size: 22),
        SizedBox(width: 4),
        Text('Approved',
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
      ]);
    } else if (status == 'needs_review') {
      return const Row(children: [
        Icon(Icons.error, color: Colors.red, size: 22),
        SizedBox(width: 4),
        Text('Needs Review',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
      ]);
    } else {
      return const Row(children: [
        Icon(Icons.access_time, color: Colors.orange, size: 22),
        SizedBox(width: 4),
        Text('Pending',
            style:
                TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaffoldContext = context;
    return Consumer<AdminPayrollProvider>(
      builder: (context, provider, child) {
        final employees = provider.employees;
        final payslips = provider.payslips;
        final isLoading = provider.isLoading;
        final error = provider.error;

        // Auto-select first employee if none is selected and employees are loaded
        if (_selectedEmployeeId == null && employees.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_selectedEmployeeId == null && employees.isNotEmpty) {
              setState(() {
                _selectedEmployeeId = employees.first['_id'] as String;
              });
              Provider.of<AdminPayrollProvider>(context, listen: false)
                  .fetchPayslips(_selectedEmployeeId!);
            }
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Payroll Management'),
          ),
          drawer:
              const AdminSideNavigation(currentRoute: '/payroll_management'),
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
                    if (isLoading && employees.isEmpty)
                      const CircularProgressIndicator(),
                    if (!isLoading && employees.isNotEmpty)
                      DropdownButton<String>(
                        value: _selectedEmployeeId ??
                            employees.first['_id'] as String,
                        items: employees
                            .map((emp) => DropdownMenuItem<String>(
                                  value: emp['_id'] as String,
                                  child: Text(
                                      emp['firstName'] + ' ' + emp['lastName']),
                                ))
                            .toList(),
                        onChanged: (val) {
                          _onEmployeeChanged(val);
                        },
                      ),
                  ],
                ),
                if (_selectedEmployeeId != null && employees.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: isLoading
                                ? null
                                : () async {
                                    final authProvider =
                                        Provider.of<AuthProvider>(context,
                                            listen: false);
                                    final token = authProvider.token;
                                    if (token == null || token.isEmpty) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Auth token is missing. Cannot download.')),
                                      );
                                      return;
                                    }
                                    await _downloadAllPayslips(
                                        context, _selectedEmployeeId!, token,
                                        asCsv: false);
                                  },
                            icon: const Icon(Icons.picture_as_pdf),
                            label: const Text('Download All (PDF)'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: isLoading
                                ? null
                                : () async {
                                    final authProvider =
                                        Provider.of<AuthProvider>(context,
                                            listen: false);
                                    final token = authProvider.token;
                                    if (token == null || token.isEmpty) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Auth token is missing. Cannot download.')),
                                      );
                                      return;
                                    }
                                    await _downloadAllPayslips(
                                        context, _selectedEmployeeId!, token,
                                        asCsv: true);
                                  },
                            icon: const Icon(Icons.table_chart),
                            label: const Text('Download All (CSV)'),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text('Error: $error',
                        style: const TextStyle(color: Colors.red)),
                  ),
                const SizedBox(height: 24),
                // Payslip list
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : payslips.isEmpty
                          ? Center(
                              child: Text('No payslips for this employee.',
                                  style: theme.textTheme.bodyLarge),
                            )
                          : RefreshIndicator(
                              onRefresh: () async {
                                if (_selectedEmployeeId != null) {
                                  await Provider.of<AdminPayrollProvider>(
                                          context,
                                          listen: false)
                                      .fetchPayslips(_selectedEmployeeId!);
                                }
                              },
                              child: ListView.builder(
                                itemCount: payslips.length,
                                itemBuilder: (context, idx) {
                                  final slip = payslips[idx];
                                  // Get employee name if available
                                  String empName = '';
                                  final emp = slip['employee'];
                                  if (emp is Map &&
                                      emp['firstName'] != null &&
                                      emp['lastName'] != null) {
                                    empName =
                                        '${emp['firstName']} ${emp['lastName']}';
                                  }
                                  return Card(
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    elevation: 3,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(18.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.calendar_month,
                                                  color:
                                                      theme.colorScheme.primary,
                                                  size: 28),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  slip['payPeriod']
                                                          ?.toString() ??
                                                      '-',
                                                  style: theme
                                                      .textTheme.titleMedium
                                                      ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.bold),
                                                ),
                                              ),
                                              Chip(
                                                label: Text(
                                                    'Net Pay: ' +
                                                        (slip['netPay'] != null
                                                            ? (slip['netPay']
                                                                    is num
                                                                ? slip['netPay']
                                                                    .toStringAsFixed(
                                                                        2)
                                                                : slip['netPay']
                                                                    .toString())
                                                            : '-'),
                                                    style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold)),
                                                backgroundColor:
                                                    theme.colorScheme.primary,
                                              ),
                                              _buildStatusIndicator(
                                                  slip['status']?.toString(),
                                                  slip['employeeComment']
                                                      ?.toString()),
                                            ],
                                          ),
                                          // Show employee name if available
                                          if (empName.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 6.0),
                                              child: Text(
                                                'Employee: $empName',
                                                style: const TextStyle(
                                                  color: Colors.black87,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          const SizedBox(height: 10),
                                          Row(
                                            children: [
                                              Icon(Icons.payments,
                                                  color: Colors.green[700],
                                                  size: 22),
                                              const SizedBox(width: 6),
                                              Text(
                                                  'Gross: ' +
                                                      (slip['grossPay'] != null
                                                          ? (slip['grossPay']
                                                                  is num
                                                              ? slip['grossPay']
                                                                  .toStringAsFixed(
                                                                      2)
                                                              : slip['grossPay']
                                                                  .toString())
                                                          : '-'),
                                                  style: theme
                                                      .textTheme.bodyMedium),
                                              const SizedBox(width: 16),
                                              Icon(Icons.remove_circle,
                                                  color: Colors.red[700],
                                                  size: 22),
                                              const SizedBox(width: 6),
                                              Text(
                                                  'Deductions: -' +
                                                      (slip['deductions'] !=
                                                              null
                                                          ? (slip['deductions']
                                                                  is num
                                                              ? slip['deductions']
                                                                  .toStringAsFixed(
                                                                      2)
                                                              : slip['deductions']
                                                                  .toString())
                                                          : '-'),
                                                  style: theme
                                                      .textTheme.bodyMedium),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                              'Issued: ${slip['issueDate'] != null ? DateFormat('MMM d, y').format(DateTime.tryParse(slip['issueDate']) ?? DateTime(1970)) : '-'}',
                                              style: theme.textTheme.bodySmall),
                                          const SizedBox(height: 16),
                                          // Always show employee comment if present
                                          if ((slip['employeeComment']
                                                      ?.toString() ??
                                                  '')
                                              .isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 8.0),
                                              child: Text(
                                                  'Employee Comment: ${slip['employeeComment']}',
                                                  style: const TextStyle(
                                                      color: Colors.red,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                            ),
                                          if (((slip['status']?.toString() ??
                                                          '') ==
                                                      'pending' ||
                                                  (slip['status']?.toString() ??
                                                          '') ==
                                                      'needs_review') &&
                                              (slip['adminResponse'] ?? '')
                                                  .isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 8.0),
                                              child: Text(
                                                'Admin Response: ${slip['adminResponse']}',
                                                style: const TextStyle(
                                                    color: Colors.blue,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                          Row(
                                            children: [
                                              OutlinedButton.icon(
                                                onPressed: () {
                                                  final authProvider =
                                                      Provider.of<AuthProvider>(
                                                          context,
                                                          listen: false);
                                                  final payslipId = slip['_id'];
                                                  final token =
                                                      authProvider.token;
                                                  if (payslipId == null ||
                                                      payslipId
                                                          .toString()
                                                          .isEmpty) {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                          content: Text(
                                                              'Payslip ID is missing. Cannot download PDF.')),
                                                    );
                                                    return;
                                                  }
                                                  if (token == null ||
                                                      token.isEmpty) {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                          content: Text(
                                                              'Auth token is missing. Cannot download PDF.')),
                                                    );
                                                    return;
                                                  }
                                                  _downloadPayslipPdf(
                                                      context,
                                                      payslipId.toString(),
                                                      token);
                                                },
                                                icon:
                                                    const Icon(Icons.download),
                                                label: const Text('Download'),
                                              ),
                                              const SizedBox(width: 8),
                                              OutlinedButton.icon(
                                                onPressed: (slip['status']
                                                                ?.toString() ==
                                                            'approved' ||
                                                        slip['status']
                                                                ?.toString() ==
                                                            'acknowledged')
                                                    ? null
                                                    : () => _editPayslip(
                                                        scaffoldContext,
                                                        provider,
                                                        idx),
                                                icon: const Icon(Icons.edit),
                                                label: const Text('Edit'),
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
                ),
                // Add Payslip button
                Align(
                  alignment: Alignment.bottomRight,
                  child: FloatingActionButton.extended(
                    onPressed: isLoading || _selectedEmployeeId == null
                        ? null
                        : () => _addPayslip(context, provider),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Payslip'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
