import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tax_settings_provider.dart';

class TaxSettingsScreen extends StatefulWidget {
  const TaxSettingsScreen({super.key});

  @override
  State<TaxSettingsScreen> createState() => _TaxSettingsScreenState();
}

class _TaxSettingsScreenState extends State<TaxSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  // Basic settings
  bool _taxEnabled = false;
  bool _incomeTaxEnabled = false;
  bool _socialSecurityEnabled = false;
  String _currency = 'NPR';
  String _currencySymbol = 'Rs.';
  String _taxCalculationMethod = 'percentage';

  // Social Security settings
  double _socialSecurityRate = 0.0;
  double? _socialSecurityCap;

  // Income tax brackets (progressive)
  List<Map<String, dynamic>> _incomeTaxBrackets = [];

  // Flat tax rates
  List<Map<String, dynamic>> _flatTaxRates = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final provider = Provider.of<TaxSettingsProvider>(context, listen: false);
    await provider.load();
    final s = provider.settings;
    if (s != null && mounted) {
      setState(() {
        _taxEnabled = s['enabled'] ?? _taxEnabled;
        _incomeTaxEnabled = s['incomeTaxEnabled'] ?? _incomeTaxEnabled;
        _socialSecurityEnabled =
            s['socialSecurityEnabled'] ?? _socialSecurityEnabled;
        _currency = s['currency'] ?? _currency;
        _currencySymbol = s['currencySymbol'] ?? _currencySymbol;
        _taxCalculationMethod =
            s['taxCalculationMethod'] ?? _taxCalculationMethod;
        _socialSecurityRate =
            (s['socialSecurityRate'] ?? _socialSecurityRate).toDouble();
        _socialSecurityCap = s['socialSecurityCap']?.toDouble();

        // Load income tax brackets
        if (s['incomeTaxBrackets'] != null && s['incomeTaxBrackets'] is List) {
          _incomeTaxBrackets =
              List<Map<String, dynamic>>.from(s['incomeTaxBrackets']);
        } else {
          _incomeTaxBrackets = [];
        }

        // Load flat tax rates
        if (s['flatTaxRates'] != null && s['flatTaxRates'] is List) {
          _flatTaxRates = List<Map<String, dynamic>>.from(s['flatTaxRates']);
        } else {
          _flatTaxRates = [];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Tax Configuration')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary banner
              _buildSummaryCard(theme),
              const SizedBox(height: 16),

              // Basic Settings
              _buildBasicSettings(theme),
              const Divider(height: 32),

              // Currency Settings
              if (_taxEnabled) ...[
                _buildCurrencySettings(theme),
                const Divider(height: 32),
              ],

              // Income Tax Settings
              if (_taxEnabled && _incomeTaxEnabled) ...[
                _buildIncomeTaxSettings(theme),
                const Divider(height: 32),
              ],

              // Social Security Settings
              if (_taxEnabled && _socialSecurityEnabled) ...[
                _buildSocialSecuritySettings(theme),
                const Divider(height: 32),
              ],

              // Flat Tax Rates
              if (_taxEnabled) ...[
                _buildFlatTaxRates(theme),
                const Divider(height: 32),
              ],

              // Save Button
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Tax Settings'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(ThemeData theme) {
    return Card(
      color: theme.colorScheme.surfaceVariant,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(_taxEnabled ? Icons.check_circle : Icons.info_outline,
                size: 20),
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
    );
  }

  Widget _buildBasicSettings(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('General Tax Settings', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('Enable Tax Calculations'),
          subtitle: const Text('Turn on automatic tax deductions in payroll'),
          value: _taxEnabled,
          onChanged: (v) => setState(() => _taxEnabled = v),
        ),
        if (_taxEnabled) ...[
          CheckboxListTile(
            title: const Text('Income Tax'),
            subtitle: const Text('Progressive tax brackets based on income'),
            value: _incomeTaxEnabled,
            onChanged: (v) => setState(() => _incomeTaxEnabled = v ?? false),
          ),
          CheckboxListTile(
            title: const Text('Social Security Contributions'),
            subtitle: const Text('Flat rate social security deductions'),
            value: _socialSecurityEnabled,
            onChanged: (v) =>
                setState(() => _socialSecurityEnabled = v ?? false),
          ),
        ],
      ],
    );
  }

  Widget _buildCurrencySettings(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Currency Settings', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: _currency,
                decoration: const InputDecoration(labelText: 'Currency Code'),
                onSaved: (v) => _currency = v ?? 'NPR',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                initialValue: _currencySymbol,
                decoration: const InputDecoration(labelText: 'Currency Symbol'),
                onSaved: (v) => _currencySymbol = v ?? 'Rs.',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIncomeTaxSettings(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Income Tax Brackets', style: theme.textTheme.titleLarge),
            TextButton.icon(
              onPressed: _addIncomeTaxBracket,
              icon: const Icon(Icons.add),
              label: const Text('Add Bracket'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_incomeTaxBrackets.isEmpty)
          Text(
            'No tax brackets configured. Add a bracket to start.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          ..._buildIncomeTaxBracketsList(),
      ],
    );
  }

  List<Widget> _buildIncomeTaxBracketsList() {
    return _incomeTaxBrackets.asMap().entries.map((entry) {
      final index = entry.key;
      final bracket = entry.value;

      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: bracket['minAmount']?.toString() ?? '0',
                      decoration: InputDecoration(
                        labelText: 'Min Amount ($_currencySymbol)',
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => _updateIncomeTaxBracket(
                          index, 'minAmount', double.tryParse(v) ?? 0),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      initialValue: bracket['maxAmount']?.toString() ?? '',
                      decoration: InputDecoration(
                        labelText: 'Max Amount ($_currencySymbol)',
                        hintText: 'Leave empty for unlimited',
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => _updateIncomeTaxBracket(index,
                          'maxAmount', v.isEmpty ? null : double.tryParse(v)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      initialValue: bracket['rate']?.toString() ?? '0',
                      decoration: const InputDecoration(
                        labelText: 'Rate (%)',
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => _updateIncomeTaxBracket(
                          index, 'rate', double.tryParse(v) ?? 0),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeIncomeTaxBracket(index),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: bracket['description'] ?? '',
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  isDense: true,
                ),
                onChanged: (v) =>
                    _updateIncomeTaxBracket(index, 'description', v),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildSocialSecuritySettings(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Social Security Settings', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: _socialSecurityRate.toString(),
                decoration: const InputDecoration(
                    labelText: 'Social Security Rate (%)'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final num? rate = double.tryParse(v);
                  if (rate == null || rate < 0 || rate > 100)
                    return 'Must be between 0 and 100';
                  return null;
                },
                onSaved: (v) => _socialSecurityRate = double.tryParse(v!) ?? 0,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                initialValue: _socialSecurityCap?.toString() ?? '',
                decoration: InputDecoration(
                  labelText: 'Annual Cap ($_currencySymbol)',
                  hintText: 'Leave empty for no cap',
                ),
                keyboardType: TextInputType.number,
                onSaved: (v) => _socialSecurityCap =
                    v?.isNotEmpty == true ? double.tryParse(v!) : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFlatTaxRates(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Additional Tax Rates', style: theme.textTheme.titleLarge),
            TextButton.icon(
              onPressed: _addFlatTaxRate,
              icon: const Icon(Icons.add),
              label: const Text('Add Rate'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_flatTaxRates.isEmpty)
          Text(
            'No additional tax rates configured.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          ..._buildFlatTaxRatesList(),
      ],
    );
  }

  List<Widget> _buildFlatTaxRatesList() {
    return _flatTaxRates.asMap().entries.map((entry) {
      final index = entry.key;
      final rate = entry.value;

      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  initialValue: rate['name'] ?? '',
                  decoration: const InputDecoration(
                    labelText: 'Tax Name',
                    isDense: true,
                  ),
                  onChanged: (v) => _updateFlatTaxRate(index, 'name', v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: rate['rate']?.toString() ?? '0',
                  decoration: const InputDecoration(
                    labelText: 'Rate (%)',
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _updateFlatTaxRate(
                      index, 'rate', double.tryParse(v) ?? 0),
                ),
              ),
              const SizedBox(width: 8),
              Checkbox(
                value: rate['enabled'] ?? true,
                onChanged: (v) =>
                    _updateFlatTaxRate(index, 'enabled', v ?? true),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _removeFlatTaxRate(index),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  void _addIncomeTaxBracket() {
    setState(() {
      _incomeTaxBrackets.add({
        'minAmount': 0,
        'maxAmount': null,
        'rate': 0,
        'description': '',
      });
    });
  }

  void _removeIncomeTaxBracket(int index) {
    setState(() {
      _incomeTaxBrackets.removeAt(index);
    });
  }

  void _updateIncomeTaxBracket(int index, String key, dynamic value) {
    setState(() {
      _incomeTaxBrackets[index][key] = value;
    });
  }

  void _addFlatTaxRate() {
    setState(() {
      _flatTaxRates.add({
        'name': '',
        'rate': 0,
        'enabled': true,
      });
    });
  }

  void _removeFlatTaxRate(int index) {
    setState(() {
      _flatTaxRates.removeAt(index);
    });
  }

  void _updateFlatTaxRate(int index, String key, dynamic value) {
    setState(() {
      _flatTaxRates[index][key] = value;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final data = {
      'enabled': _taxEnabled,
      'incomeTaxEnabled': _incomeTaxEnabled,
      'socialSecurityEnabled': _socialSecurityEnabled,
      'currency': _currency,
      'currencySymbol': _currencySymbol,
      'taxCalculationMethod': _taxCalculationMethod,
      'socialSecurityRate': _socialSecurityRate,
      'socialSecurityCap': _socialSecurityCap,
      'incomeTaxBrackets': _incomeTaxBrackets,
      'flatTaxRates': _flatTaxRates,
    };

    final provider = Provider.of<TaxSettingsProvider>(context, listen: false);
    final success = await provider.save(data);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'Tax settings saved!'
            : 'Failed to save: ${provider.error}'),
        duration: const Duration(seconds: 3),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  String _buildSummaryText() {
    if (!_taxEnabled) {
      return 'Tax calculations are disabled. Enable to configure tax settings.';
    }

    final parts = <String>[];
    if (_incomeTaxEnabled) {
      parts.add('Income Tax (${_incomeTaxBrackets.length} brackets)');
    }
    if (_socialSecurityEnabled) {
      parts.add('Social Security (${_socialSecurityRate.toStringAsFixed(1)}%)');
    }
    if (_flatTaxRates.isNotEmpty) {
      final enabled = _flatTaxRates.where((r) => r['enabled'] == true).length;
      parts.add('Additional Taxes ($enabled rates)');
    }

    return parts.isNotEmpty
        ? 'Active: ${parts.join(', ')}'
        : 'Tax enabled but no specific taxes configured';
  }
}
