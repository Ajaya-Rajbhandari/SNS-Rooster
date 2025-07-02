import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EditPayslipDialog extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final void Function(Map<String, dynamic> payslip) onSave;

  const EditPayslipDialog({super.key, this.initialData, required this.onSave});

  @override
  State<EditPayslipDialog> createState() => _EditPayslipDialogState();
}

class _EditPayslipDialogState extends State<EditPayslipDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _payPeriodController;
  late TextEditingController _grossPayController;
  late TextEditingController _deductionsController;
  late TextEditingController _netPayController;
  late TextEditingController _totalHoursController;
  late TextEditingController _overtimeHoursController;
  late TextEditingController _adminResponseController;
  DateTime? _issueDate;
  DateTime? _periodStart;
  DateTime? _periodEnd;

  // Deductions logic
  final List<String> _defaultDeductionTypes = [
    'Tax',
    'Provident Fund',
    'Insurance',
    'Other',
  ];
  List<Map<String, dynamic>> _deductionsList = [];

  // Income logic
  final List<String> _defaultIncomeTypes = [
    'Basic Salary',
    'Allowance',
    'Bonus',
    'TDA',
    'Other',
  ];
  List<Map<String, dynamic>> _incomesList = [];

  @override
  void initState() {
    super.initState();
    final data = widget.initialData ?? {};
    _payPeriodController = TextEditingController(text: data['payPeriod'] ?? '');
    _grossPayController =
        TextEditingController(text: data['grossPay']?.toString() ?? '');
    _deductionsController =
        TextEditingController(text: data['deductions']?.toString() ?? '');
    _netPayController =
        TextEditingController(text: data['netPay']?.toString() ?? '');
    _totalHoursController =
        TextEditingController(text: data['totalHours']?.toString() ?? '');
    _overtimeHoursController =
        TextEditingController(text: data['overtimeHours']?.toString() ?? '0');
    _adminResponseController =
        TextEditingController(text: data['adminResponse'] ?? '');
    _issueDate = data['issueDate'] != null
        ? DateTime.tryParse(data['issueDate'])
        : DateTime.now();
    final now = DateTime.now();
    _periodStart = data['periodStart'] != null
        ? DateTime.tryParse(data['periodStart'])
        : DateTime(now.year, now.month, 1);
    _periodEnd = data['periodEnd'] != null
        ? DateTime.tryParse(data['periodEnd'])
        : DateTime(now.year, now.month + 1, 0); // Last day of month
    // Load deductions from initialData if present
    if (data['deductionsList'] != null && data['deductionsList'] is List) {
      _deductionsList = List<Map<String, dynamic>>.from(data['deductionsList']);
    } else {
      _deductionsList = [];
    }
    // Load incomes from initialData if present
    if (data['incomesList'] != null && data['incomesList'] is List) {
      _incomesList = List<Map<String, dynamic>>.from(data['incomesList']);
    } else {
      _incomesList = [
        {'type': _defaultIncomeTypes.first, 'amount': ''},
      ];
    }
    _updateGrossPay();
    _updateTotalHours();
  }

  @override
  void dispose() {
    _payPeriodController.dispose();
    _grossPayController.dispose();
    _deductionsController.dispose();
    _netPayController.dispose();
    _totalHoursController.dispose();
    _overtimeHoursController.dispose();
    _adminResponseController.dispose();
    super.dispose();
  }

  void _updateNetPay() {
    final gross = double.tryParse(_grossPayController.text) ?? 0;
    final deductions = double.tryParse(_deductionsController.text) ?? 0;
    final net = gross - deductions;
    _netPayController.text = net.toStringAsFixed(2);
  }

  void _updateTotalHours() {
    if (_periodStart != null && _periodEnd != null) {
      int total = 0;
      DateTime d = _periodStart!;
      while (!d.isAfter(_periodEnd!)) {
        if (d.weekday != DateTime.saturday && d.weekday != DateTime.sunday) {
          total += 8; // 8 hours per weekday
        }
        d = d.add(const Duration(days: 1));
      }
      _totalHoursController.text = total.toString();
      _updateGrossPay();
    }
  }

  void _updateDeductionsTotal() {
    double total = 0;
    for (final item in _deductionsList) {
      total += double.tryParse(item['amount']?.toString() ?? '0') ?? 0;
    }
    _deductionsController.text = total.toStringAsFixed(2);
    _updateNetPay();
  }

  void _addDeductionRow() {
    setState(() {
      _deductionsList.add({'type': _defaultDeductionTypes.first, 'amount': ''});
    });
  }

  void _removeDeductionRow(int idx) {
    setState(() {
      _deductionsList.removeAt(idx);
      _updateDeductionsTotal();
    });
  }

  void _setDeductionType(int idx, String? type) {
    setState(() {
      _deductionsList[idx]['type'] = type;
    });
  }

  void _setDeductionAmount(int idx, String value) {
    setState(() {
      _deductionsList[idx]['amount'] = value;
      _updateDeductionsTotal();
    });
  }

  void _updateGrossPay() {
    double total = 0;
    for (final item in _incomesList) {
      total += double.tryParse(item['amount']?.toString() ?? '0') ?? 0;
    }

    // Include overtime pay if present
    final otHours = double.tryParse(_overtimeHoursController.text) ?? 0;
    if (otHours > 0) {
      final ratePerHour =
          total / (double.tryParse(_totalHoursController.text) ?? 1);
      final multiplier = double.tryParse(
              widget.initialData?['overtimeMultiplier']?.toString() ?? '1.5') ??
          1.5;
      total += otHours * ratePerHour * multiplier;
    }

    _grossPayController.text = total.toStringAsFixed(2);
    _updateNetPay();
  }

  void _addIncomeRow() {
    setState(() {
      _incomesList.add({'type': _defaultIncomeTypes.first, 'amount': ''});
    });
  }

  void _removeIncomeRow(int idx) {
    setState(() {
      _incomesList.removeAt(idx);
      _updateGrossPay();
    });
  }

  void _setIncomeType(int idx, String? type) {
    setState(() {
      _incomesList[idx]['type'] = type;
    });
  }

  void _setIncomeAmount(int idx, String value) {
    setState(() {
      _incomesList[idx]['amount'] = value;
      _updateGrossPay();
    });
  }

  Future<DateTime?> showCustomDatePicker(
      BuildContext context, DateTime initialDate) {
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
                textStyle:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(widget.initialData == null ? 'Add Payslip' : 'Edit Payslip'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _payPeriodController,
                decoration: const InputDecoration(
                    labelText: 'Pay Period (e.g. May 2024)'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Pay Period is required' : null,
              ),
              const SizedBox(height: 12),
              // Period Start
              InkWell(
                onTap: () async {
                  final picked = await showCustomDatePicker(
                      context, _periodStart ?? DateTime.now());
                  if (picked != null) {
                    setState(() {
                      _periodStart = picked;
                      _updateTotalHours();
                    });
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Period Start'),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_periodStart != null
                          ? DateFormat('MMM d, y').format(_periodStart!)
                          : 'Select date'),
                      const Icon(Icons.calendar_today, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Period End
              InkWell(
                onTap: () async {
                  final picked = await showCustomDatePicker(
                      context, _periodEnd ?? DateTime.now());
                  if (picked != null) {
                    setState(() {
                      _periodEnd = picked;
                      _updateTotalHours();
                    });
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Period End'),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_periodEnd != null
                          ? DateFormat('MMM d, y').format(_periodEnd!)
                          : 'Select date'),
                      const Icon(Icons.calendar_today, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Total Hours
              TextFormField(
                controller: _totalHoursController,
                decoration: const InputDecoration(labelText: 'Total Hours'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _overtimeHoursController,
                decoration: const InputDecoration(labelText: 'Overtime Hours'),
                keyboardType: TextInputType.number,
                onChanged: (_) => _updateGrossPay(),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final picked = await showCustomDatePicker(
                      context, _issueDate ?? DateTime.now());
                  if (picked != null) setState(() => _issueDate = picked);
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Issue Date',
                    errorText: _issueDate == null &&
                            _formKey.currentState?.validate() == false
                        ? 'Issue Date is required'
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_issueDate != null
                          ? DateFormat('MMM d, y').format(_issueDate!)
                          : 'Select date'),
                      const Icon(Icons.calendar_today, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Income Section
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Income', style: theme.textTheme.titleMedium),
              ),
              const SizedBox(height: 8),
              Column(
                children: [
                  for (int i = 0; i < _incomesList.length; i++)
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<String>(
                            value: _incomesList[i]['type'],
                            items: _defaultIncomeTypes
                                .map((type) => DropdownMenuItem(
                                      value: type,
                                      child: Text(type),
                                    ))
                                .toList(),
                            onChanged: (val) => _setIncomeType(i, val),
                            decoration: const InputDecoration(
                              labelText: 'Type',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            initialValue:
                                _incomesList[i]['amount']?.toString() ?? '',
                            decoration:
                                const InputDecoration(labelText: 'Amount'),
                            keyboardType: TextInputType.number,
                            onChanged: (val) => _setIncomeAmount(i, val),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.remove_circle,
                              color: Colors.red),
                          onPressed: () => _removeIncomeRow(i),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          splashRadius: 18,
                        ),
                      ],
                    ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _addIncomeRow,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Income'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Deductions Section
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Deductions', style: theme.textTheme.titleMedium),
              ),
              const SizedBox(height: 8),
              Column(
                children: [
                  for (int i = 0; i < _deductionsList.length; i++)
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<String>(
                            value: _deductionsList[i]['type'],
                            items: _defaultDeductionTypes
                                .map((type) => DropdownMenuItem(
                                      value: type,
                                      child: Text(type),
                                    ))
                                .toList(),
                            onChanged: (val) => _setDeductionType(i, val),
                            decoration: const InputDecoration(
                              labelText: 'Type',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            initialValue:
                                _deductionsList[i]['amount']?.toString() ?? '',
                            decoration:
                                const InputDecoration(labelText: 'Amount'),
                            keyboardType: TextInputType.number,
                            onChanged: (val) => _setDeductionAmount(i, val),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.remove_circle,
                              color: Colors.red),
                          onPressed: () => _removeDeductionRow(i),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          splashRadius: 18,
                        ),
                      ],
                    ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _addDeductionRow,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Deduction'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Total Deductions (read-only)
              TextFormField(
                controller: _deductionsController,
                decoration:
                    const InputDecoration(labelText: 'Total Deductions'),
                readOnly: true,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _netPayController,
                decoration: const InputDecoration(labelText: 'Net Pay'),
                keyboardType: TextInputType.number,
                readOnly: true,
              ),
              // Admin Response (only if needs_review)
              if ((widget.initialData?['status'] ?? '') == 'needs_review')
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: TextFormField(
                    controller: _adminResponseController,
                    decoration: const InputDecoration(
                      labelText: 'Admin Response (visible to employee)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final valid = _formKey.currentState!.validate();
            if (!valid || _issueDate == null) {
              setState(() {}); // To show error
              return;
            }
            final payload = {
              'payPeriod': _payPeriodController.text,
              'issueDate': _issueDate!.toIso8601String(),
              'periodStart': _periodStart!.toIso8601String(),
              'periodEnd': _periodEnd!.toIso8601String(),
              'totalHours': double.tryParse(_totalHoursController.text) ?? 0,
              'overtimeHours':
                  double.tryParse(_overtimeHoursController.text) ?? 0,
              'overtimeMultiplier':
                  widget.initialData?['overtimeMultiplier'] ?? 1.5,
              'grossPay': double.tryParse(_grossPayController.text) ?? 0,
              'incomesList': _incomesList,
              'deductions': double.tryParse(_deductionsController.text) ?? 0,
              'deductionsList': _deductionsList,
              'netPay': double.tryParse(_netPayController.text) ?? 0,
              'adminResponse': _adminResponseController.text,
            };
            print('DEBUG: Admin Edit Payslip Payload:');
            print(payload);
            Navigator.pop(context, payload); // Just pop with the data
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
