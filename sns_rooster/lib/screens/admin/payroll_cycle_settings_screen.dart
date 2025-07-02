import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/payroll_cycle_settings_provider.dart';

class PayrollCycleSettingsScreen extends StatefulWidget {
  const PayrollCycleSettingsScreen({super.key});

  @override
  State<PayrollCycleSettingsScreen> createState() =>
      _PayrollCycleSettingsScreenState();
}

class _PayrollCycleSettingsScreenState
    extends State<PayrollCycleSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form fields
  String _frequency = 'Monthly';
  int _cutoffDay = 25; // day-of-month when period ends
  int _payDay = 30; // day-of-month employees are paid
  int _payOffset = 0; // extra days offset
  bool _overtimeEnabled = true;
  double _overtimeMultiplier = 1.5;
  bool _autoGenerate = true;
  bool _notifyCycleClose = true;
  bool _notifyPayslip = true;

  @override
  void initState() {
    super.initState();
    // Load existing settings
    Future.microtask(() async {
      final provider =
          Provider.of<PayrollCycleSettingsProvider>(context, listen: false);
      await provider.load();
      final s = provider.settings;
      if (s != null && mounted) {
        setState(() {
          _frequency = s['frequency'] ?? _frequency;
          _cutoffDay = s['cutoffDay'] ?? _cutoffDay;
          _payDay = s['payDay'] ?? _payDay;
          _payOffset = s['payOffset'] ?? _payOffset;
          _overtimeEnabled = s['overtimeEnabled'] ?? _overtimeEnabled;
          _overtimeMultiplier =
              (s['overtimeMultiplier'] ?? _overtimeMultiplier).toDouble();
          _autoGenerate = s['autoGenerate'] ?? _autoGenerate;
          _notifyCycleClose = s['notifyCycleClose'] ?? _notifyCycleClose;
          _notifyPayslip = s['notifyPayslip'] ?? _notifyPayslip;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Payroll Cycle Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary banner
              Card(
                color: theme.colorScheme.surfaceVariant,
                elevation: 1,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _buildSummaryText(),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('General', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              _buildFrequencyField(),
              const SizedBox(height: 12),
              if (_frequency == 'Monthly' || _frequency == 'Semi-Monthly') ...[
                _buildNumberField(
                    label: 'Cut-off Day',
                    initial: _cutoffDay,
                    onSaved: (v) => _cutoffDay = v),
                const SizedBox(height: 12),
                _buildNumberField(
                    label: 'Pay Day',
                    initial: _payDay,
                    onSaved: (v) => _payDay = v),
              ],
              const SizedBox(height: 12),
              _buildNumberField(
                  label: 'Pay Day Offset (days)',
                  initial: _payOffset,
                  onSaved: (v) => _payOffset = v,
                  min: 0,
                  max: 31),
              const Divider(height: 32),
              Text('Overtime', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Enable Overtime'),
                value: _overtimeEnabled,
                onChanged: (v) => setState(() => _overtimeEnabled = v),
              ),
              if (_overtimeEnabled) ...[
                _buildDecimalField(
                    label: 'Overtime Multiplier',
                    initial: _overtimeMultiplier,
                    onSaved: (v) => _overtimeMultiplier = v,
                    min: 1.0,
                    max: 3.0),
              ],
              const Divider(height: 32),
              Text('Automation', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Auto-Generate Payslips'),
                value: _autoGenerate,
                onChanged: (v) => setState(() => _autoGenerate = v),
              ),
              const Divider(height: 32),
              Text('Notifications', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              CheckboxListTile(
                title: const Text('Notify employees on Cycle Close'),
                value: _notifyCycleClose,
                onChanged: (v) => setState(() => _notifyCycleClose = v ?? true),
              ),
              CheckboxListTile(
                title: const Text('Notify employees on Payslip Publication'),
                value: _notifyPayslip,
                onChanged: (v) => setState(() => _notifyPayslip = v ?? true),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Settings'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFrequencyField() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(labelText: 'Payroll Frequency'),
      value: _frequency,
      items: const [
        DropdownMenuItem(value: 'Monthly', child: Text('Monthly')),
        DropdownMenuItem(value: 'Semi-Monthly', child: Text('Semi-Monthly')),
        DropdownMenuItem(value: 'Bi-Weekly', child: Text('Bi-Weekly')),
        DropdownMenuItem(value: 'Weekly', child: Text('Weekly')),
      ],
      onChanged: (v) => setState(() => _frequency = v ?? 'Monthly'),
    );
  }

  Widget _buildNumberField({
    required String label,
    required int initial,
    required void Function(int) onSaved,
    int min = 1,
    int max = 31,
  }) {
    final controller = TextEditingController(text: initial.toString());
    return TextFormField(
      decoration: InputDecoration(labelText: label),
      keyboardType: TextInputType.number,
      controller: controller,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Required';
        final num? n = int.tryParse(value);
        if (n == null) return 'Invalid number';
        if (n < min || n > max) return 'Must be between $min and $max';
        return null;
      },
      onSaved: (v) => onSaved(int.parse(v!)),
    );
  }

  Widget _buildDecimalField({
    required String label,
    required double initial,
    required void Function(double) onSaved,
    double min = 0.0,
    double max = 10.0,
  }) {
    final controller = TextEditingController(text: initial.toString());
    return TextFormField(
      decoration: InputDecoration(labelText: label),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      controller: controller,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Required';
        final num? n = double.tryParse(value);
        if (n == null) return 'Invalid number';
        if (n < min || n > max) return 'Must be between $min and $max';
        return null;
      },
      onSaved: (v) => onSaved(double.parse(v!)),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    // TODO: Integrate with provider / backend API. For now, just show summary.
    final summary = {
      'frequency': _frequency,
      'cutoffDay': _cutoffDay,
      'payDay': _payDay,
      'payOffset': _payOffset,
      'overtimeEnabled': _overtimeEnabled,
      'overtimeMultiplier': _overtimeMultiplier,
      'autoGenerate': _autoGenerate,
      'notifyCycleClose': _notifyCycleClose,
      'notifyPayslip': _notifyPayslip,
    };

    final provider =
        Provider.of<PayrollCycleSettingsProvider>(context, listen: false);
    final success = await provider.save(summary);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Settings saved!' : 'Failed to save'),
        duration: const Duration(seconds: 3),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  String _buildSummaryText() {
    final buf = StringBuffer();
    buf.write(_frequency);
    if (_frequency.toLowerCase() == 'weekly') {
      buf.write(
          ' • Pay every ${_weekdayName((DateTime.monday + _payDay - 1) % 7 + 1)}');
    } else {
      buf.write(' • Pay Day $_payDay');
    }
    buf.write(' • OT ×$_overtimeMultiplier');
    return buf.toString();
  }

  String _weekdayName(int weekday) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[weekday - 1];
  }
}
