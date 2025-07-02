import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/api_config.dart';
import '../../widgets/admin_side_navigation.dart';

class BreakTypesScreen extends StatefulWidget {
  const BreakTypesScreen({super.key});

  @override
  State<BreakTypesScreen> createState() => _BreakTypesScreenState();
}

class _BreakTypesScreenState extends State<BreakTypesScreen> {
  List<Map<String, dynamic>> _breakTypes = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchBreakTypes();
  }

  Future<void> _fetchBreakTypes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/admin/break-types'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _breakTypes = List<Map<String, dynamic>>.from(data['breakTypes']);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to fetch break types';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleBreakTypeStatus(String id, bool currentStatus) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/admin/break-types/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}',
        },
        body: jsonEncode({
          'isActive': !currentStatus,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentStatus ? 'Break type deactivated' : 'Break type activated',
            ),
          ),
        );
        _fetchBreakTypes();
      } else {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${data['message']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'restaurant':
        return Icons.restaurant;
      case 'local_cafe':
        return Icons.local_cafe;
      case 'person':
        return Icons.person;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'smoking_rooms':
        return Icons.smoking_rooms;
      default:
        return Icons.more_horiz;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Break Types Management'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchBreakTypes,
          ),
        ],
      ),
      drawer: const AdminSideNavigation(currentRoute: '/break_types'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: colorScheme.error),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchBreakTypes,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _breakTypes.isEmpty
                  ? const Center(
                      child: Text('No break types found'),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchBreakTypes,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _breakTypes.length,
                        itemBuilder: (context, index) {
                          final breakType = _breakTypes[index];
                          final color =
                              _parseColor(breakType['color'] ?? '#6B7280');
                          final isActive = breakType['isActive'] ?? true;

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: isActive ? color : Colors.grey,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          _getIconData(breakType['icon'] ??
                                              'more_horiz'),
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    breakType['displayName'] ??
                                                        breakType['name'],
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 18,
                                                      color: isActive
                                                          ? null
                                                          : Colors.grey,
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: isActive
                                                        ? Colors.green
                                                        : Colors.grey,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  child: Text(
                                                    isActive
                                                        ? 'Active'
                                                        : 'Inactive',
                                                    style: TextStyle(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onPrimary,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.edit,
                                                      size: 18),
                                                  tooltip: 'Edit',
                                                  padding: EdgeInsets.zero,
                                                  constraints:
                                                      const BoxConstraints(),
                                                  onPressed: () =>
                                                      _showBreakTypeDialog(
                                                          breakType: breakType),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              breakType['description'] ?? '',
                                              style: TextStyle(
                                                color: colorScheme.onSurface
                                                    .withOpacity(0.7),
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      if (breakType['minDuration'] != null ||
                                          breakType['maxDuration'] != null)
                                        _buildInfoChip(
                                          'Duration: ${breakType['minDuration'] ?? 0}-${breakType['maxDuration'] ?? '∞'} min',
                                          Icons.timer,
                                          colorScheme,
                                        ),
                                      if (breakType['dailyLimit'] != null)
                                        _buildInfoChip(
                                          'Daily: ${breakType['dailyLimit']}',
                                          Icons.today,
                                          colorScheme,
                                        ),
                                      if (breakType['weeklyLimit'] != null)
                                        _buildInfoChip(
                                          'Weekly: ${breakType['weeklyLimit']}',
                                          Icons.date_range,
                                          colorScheme,
                                        ),
                                      if (breakType['requiresApproval'] == true)
                                        _buildInfoChip(
                                          'Requires Approval',
                                          Icons.admin_panel_settings,
                                          colorScheme,
                                        ),
                                      if (breakType['isPaid'] == true)
                                        _buildInfoChip(
                                          'Paid',
                                          Icons.attach_money,
                                          colorScheme,
                                        ),
                                      if (breakType['isPaid'] == false)
                                        _buildInfoChip(
                                          'Unpaid',
                                          Icons.money_off,
                                          colorScheme,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton.icon(
                                        onPressed: () => _toggleBreakTypeStatus(
                                          breakType['_id'],
                                          isActive,
                                        ),
                                        icon: Icon(
                                          isActive
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          size: 16,
                                        ),
                                        label: Text(isActive
                                            ? 'Deactivate'
                                            : 'Activate'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: isActive
                                              ? Colors.orange
                                              : Colors.green,
                                        ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBreakTypeDialog(),
        tooltip: 'Add Break Type',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showBreakTypeDialog({Map<String, dynamic>? breakType}) async {
    final isEdit = breakType != null;
    final formKey = GlobalKey<FormState>();
    String displayName = breakType?['displayName'] ?? '';
    String name = breakType?['name'] ?? '';
    String description = breakType?['description'] ?? '';
    String icon = breakType?['icon'] ?? 'more_horiz';
    String color = breakType?['color'] ?? '#6B7280';
    int? minDuration = breakType?['minDuration'];
    int? maxDuration = breakType?['maxDuration'];
    int? dailyLimit = breakType?['dailyLimit'];
    int? weeklyLimit = breakType?['weeklyLimit'];
    bool isPaid = breakType?['isPaid'] ?? true;
    bool requiresApproval = breakType?['requiresApproval'] ?? false;
    bool isActive = breakType?['isActive'] ?? true;
    bool showAdvanced = false;

    String generateName(String displayName) {
      return displayName
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    }

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEdit ? 'Edit Break Type' : 'Add Break Type'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        initialValue: displayName,
                        decoration:
                            const InputDecoration(labelText: 'Display Name *'),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                        onChanged: (v) => setState(() {
                          displayName = v;
                          name = generateName(v);
                        }),
                      ),
                      if (isEdit)
                        TextFormField(
                          initialValue: name,
                          decoration: const InputDecoration(
                              labelText: 'Name (auto-generated)'),
                          enabled: false,
                        ),
                      TextFormField(
                        initialValue: description,
                        decoration:
                            const InputDecoration(labelText: 'Description'),
                        onChanged: (v) => setState(() => description = v),
                      ),
                      // Icon picker grid
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Icon',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 12,
                              children: [
                                {
                                  'icon': 'restaurant',
                                  'widget': Icons.restaurant
                                },
                                {
                                  'icon': 'local_cafe',
                                  'widget': Icons.local_cafe
                                },
                                {'icon': 'person', 'widget': Icons.person},
                                {
                                  'icon': 'local_hospital',
                                  'widget': Icons.local_hospital
                                },
                                {
                                  'icon': 'smoking_rooms',
                                  'widget': Icons.smoking_rooms
                                },
                                {
                                  'icon': 'more_horiz',
                                  'widget': Icons.more_horiz
                                },
                              ].map((item) {
                                final selected = icon == item['icon'];
                                return GestureDetector(
                                  onTap: () => setState(
                                      () => icon = item['icon'] as String),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: selected
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                            : Colors.grey,
                                        width: selected ? 3 : 1,
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(8),
                                    child: Icon(
                                      item['widget'] as IconData,
                                      color: selected
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : Colors.grey,
                                      size: 32,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      // Color picker row (use Wrap to avoid overflow)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Color',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                ...[
                                  '#10B981', // green
                                  '#F59E42', // orange
                                  '#3B82F6', // blue
                                  '#EF4444', // red
                                  '#6366F1', // purple
                                  '#6B7280', // gray
                                ].map((c) {
                                  final selected =
                                      color.toLowerCase() == c.toLowerCase();
                                  return GestureDetector(
                                    onTap: () => setState(() => color = c),
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 2),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: selected
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                              : Colors.grey,
                                          width: selected ? 3 : 1,
                                        ),
                                      ),
                                      width: 32,
                                      height: 32,
                                      child: Center(
                                        child: Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: Color(int.parse(
                                                c.replaceFirst('#', '0xFF'))),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                                // Manual hex input
                                SizedBox(
                                  width: 80,
                                  child: TextFormField(
                                    initialValue: color,
                                    decoration:
                                        const InputDecoration(labelText: 'Hex'),
                                    onChanged: (v) => setState(() => color = v),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Advanced options
                      ExpansionTile(
                        title: const Text('Advanced Options'),
                        initiallyExpanded: showAdvanced,
                        onExpansionChanged: (expanded) =>
                            setState(() => showAdvanced = expanded),
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: minDuration?.toString() ?? '',
                                  decoration: const InputDecoration(
                                      labelText: 'Min Duration (min)'),
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) => setState(
                                      () => minDuration = int.tryParse(v)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  initialValue: maxDuration?.toString() ?? '',
                                  decoration: const InputDecoration(
                                      labelText: 'Max Duration (min)'),
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) => setState(
                                      () => maxDuration = int.tryParse(v)),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: dailyLimit?.toString() ?? '',
                                  decoration: const InputDecoration(
                                      labelText: 'Daily Limit'),
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) => setState(
                                      () => dailyLimit = int.tryParse(v)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  initialValue: weeklyLimit?.toString() ?? '',
                                  decoration: const InputDecoration(
                                      labelText: 'Weekly Limit'),
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) => setState(
                                      () => weeklyLimit = int.tryParse(v)),
                                ),
                              ),
                            ],
                          ),
                          SwitchListTile(
                            value: isPaid,
                            onChanged: (v) => setState(() => isPaid = v),
                            title: const Text('Paid'),
                          ),
                          SwitchListTile(
                            value: requiresApproval,
                            onChanged: (v) =>
                                setState(() => requiresApproval = v),
                            title: const Text('Requires Approval'),
                          ),
                          if (isEdit)
                            SwitchListTile(
                              value: isActive,
                              onChanged: (v) => setState(() => isActive = v),
                              title: const Text('Active'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final authProvider =
                        Provider.of<AuthProvider>(context, listen: false);
                    final body = {
                      'displayName': displayName.trim(),
                      'name': generateName(displayName),
                      'description': description.trim(),
                      'icon': icon,
                      'color': color,
                      'minDuration': minDuration,
                      'maxDuration': maxDuration,
                      'dailyLimit': dailyLimit,
                      'weeklyLimit': weeklyLimit,
                      'isPaid': isPaid,
                      'requiresApproval': requiresApproval,
                      'isActive': isActive,
                    };
                    try {
                      http.Response response;
                      if (isEdit) {
                        response = await http.put(
                          Uri.parse(
                              '${ApiConfig.baseUrl}/admin/break-types/${breakType['_id']}'),
                          headers: {
                            'Content-Type': 'application/json',
                            'Authorization': 'Bearer ${authProvider.token}',
                          },
                          body: jsonEncode(body),
                        );
                      } else {
                        response = await http.post(
                          Uri.parse('${ApiConfig.baseUrl}/admin/break-types'),
                          headers: {
                            'Content-Type': 'application/json',
                            'Authorization': 'Bearer ${authProvider.token}',
                          },
                          body: jsonEncode(body),
                        );
                      }
                      if (response.statusCode == 200 ||
                          response.statusCode == 201) {
                        Navigator.of(context).pop();
                        _fetchBreakTypes();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(isEdit
                                  ? 'Break type updated'
                                  : 'Break type added')),
                        );
                      } else {
                        final data = jsonDecode(response.body);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Error: ${data['message'] ?? 'Unknown error'}')),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  },
                  child: Text(isEdit ? 'Update' : 'Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
