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
        Uri.parse('${ApiConfig.baseUrl}/attendance/admin/break-types'),
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
        Uri.parse('${ApiConfig.baseUrl}/attendance/admin/break-types/$id'),
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
                          final color = _parseColor(breakType['color'] ?? '#6B7280');
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
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          _getIconData(breakType['icon'] ?? 'more_horiz'),
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    breakType['displayName'] ?? breakType['name'],
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 18,
                                                      color: isActive ? null : Colors.grey,
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: isActive ? Colors.green : Colors.grey,
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Text(
                                                    isActive ? 'Active' : 'Inactive',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              breakType['description'] ?? '',
                                              style: TextStyle(
                                                color: colorScheme.onSurface.withOpacity(0.7),
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
                                      if (breakType['minDuration'] != null || breakType['maxDuration'] != null)
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
                                          isActive ? Icons.visibility_off : Icons.visibility,
                                          size: 16,
                                        ),
                                        label: Text(isActive ? 'Deactivate' : 'Activate'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: isActive ? Colors.orange : Colors.green,
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
}