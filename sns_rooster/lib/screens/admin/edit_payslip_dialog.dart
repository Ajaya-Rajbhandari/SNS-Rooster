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
  DateTime? _issueDate;

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
    _issueDate =
        data['issueDate'] != null ? DateTime.tryParse(data['issueDate']) : null;
  }

  @override
  void dispose() {
    _payPeriodController.dispose();
    _grossPayController.dispose();
    _deductionsController.dispose();
    _netPayController.dispose();
    super.dispose();
  }

  void _updateNetPay() {
    final gross = double.tryParse(_grossPayController.text) ?? 0;
    final deductions = double.tryParse(_deductionsController.text) ?? 0;
    final net = gross - deductions;
    _netPayController.text = net.toStringAsFixed(2);
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
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _issueDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _issueDate = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Issue Date'),
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
              TextFormField(
                controller: _grossPayController,
                decoration: const InputDecoration(labelText: 'Gross Pay'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                onChanged: (_) => setState(_updateNetPay),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _deductionsController,
                decoration: const InputDecoration(labelText: 'Deductions'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                onChanged: (_) => setState(_updateNetPay),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _netPayController,
                decoration: const InputDecoration(labelText: 'Net Pay'),
                keyboardType: TextInputType.number,
                readOnly: true,
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
            if (_formKey.currentState!.validate() && _issueDate != null) {
              widget.onSave({
                'payPeriod': _payPeriodController.text,
                'issueDate': _issueDate!.toIso8601String(),
                'grossPay': double.tryParse(_grossPayController.text) ?? 0,
                'deductions': double.tryParse(_deductionsController.text) ?? 0,
                'netPay': double.tryParse(_netPayController.text) ?? 0,
              });
              Navigator.pop(context);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
