import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/api_config.dart';
import '../../widgets/admin_side_navigation.dart';

class BreakManagementScreen extends StatefulWidget {
  const BreakManagementScreen({super.key});

  @override
  State<BreakManagementScreen> createState() => _BreakManagementScreenState();
}

class _BreakManagementScreenState extends State<BreakManagementScreen> {
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _breakTypes = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchBreakTypes();
    _fetchEmployees();
  }

  Future<void> _fetchBreakTypes() async {
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
        });
      }
    } catch (e) {
      print('Error fetching break types: $e');
    }
  }

  Future<void> _fetchEmployees() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/auth/users'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final users = data['users'] as List;
        
        // Fetch break status for each employee
        List<Map<String, dynamic>> employeesWithBreakStatus = [];
        for (var user in users) {
          if (user['role'] == 'employee') {
            final breakStatus = await _fetchBreakStatus(user['_id']);
            employeesWithBreakStatus.add({
              ...user,
              'breakStatus': breakStatus,
            });
          }
        }
        
        setState(() {
          _employees = employeesWithBreakStatus;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to fetch employees';
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

  Future<Map<String, dynamic>?> _fetchBreakStatus(String userId) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/attendance/admin/break-status/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Error fetching break status for $userId: $e');
    }
    return null;
  }

  Future<void> _startBreak(String userId, String employeeName) async {
    if (_breakTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No break types available')),
      );
      return;
    }

    // Show break type selection dialog
    final selectedBreakType = await _showBreakTypeDialog();
    if (selectedBreakType == null) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/attendance/admin/start-break/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}',
        },
        body: jsonEncode({
          'breakType': selectedBreakType['name'],
          'reason': selectedBreakType['reason'] ?? '',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${data['message']}')),
        );
        _fetchEmployees(); // Refresh the list
      } else {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${data['message']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting break: $e')),
      );
    }
  }

  Future<void> _endBreak(String userId, String employeeName) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/attendance/admin/end-break/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Break ended for $employeeName')),
        );
        _fetchEmployees(); // Refresh the list
      } else {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${data['message']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error ending break: $e')),
      );
    }
  }

  Future<Map<String, dynamic>?> _showBreakTypeDialog() async {
    String? selectedReason;
    
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Select Break Type'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Choose the type of break:'),
                    const SizedBox(height: 16),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _breakTypes.length,
                        itemBuilder: (context, index) {
                          final breakType = _breakTypes[index];
                          final color = _parseColor(breakType['color'] ?? '#6B7280');
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _getIconData(breakType['icon'] ?? 'more_horiz'),
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                breakType['displayName'] ?? breakType['name'],
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(breakType['description'] ?? ''),
                                  if (breakType['minDuration'] != null || breakType['maxDuration'] != null)
                                    Text(
                                      'Duration: ${breakType['minDuration'] ?? 0}-${breakType['maxDuration'] ?? '∞'} min',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                      ),
                                    ),
                                  if (breakType['dailyLimit'] != null)
                                    Text(
                                      'Daily limit: ${breakType['dailyLimit']}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                      ),
                                    ),
                                ],
                              ),
                              trailing: breakType['requiresApproval'] == true
                                  ? const Icon(Icons.admin_panel_settings, size: 16)
                                  : null,
                              onTap: () {
                                if (breakType['requiresApproval'] == true) {
                                  // Show reason input for approval-required breaks
                                  _showReasonDialog(breakType).then((result) {
                                    if (result != null) {
                                      Navigator.of(context).pop(result);
                                    }
                                  });
                                } else {
                                  Navigator.of(context).pop({
                                    'name': breakType['name'],
                                    'displayName': breakType['displayName'],
                                  });
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _showReasonDialog(Map<String, dynamic> breakType) async {
    final reasonController = TextEditingController();
    
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${breakType['displayName']} - Reason Required'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Please provide a reason for this ${breakType['displayName'].toLowerCase()}:'),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (reasonController.text.trim().isNotEmpty) {
                  Navigator.of(context).pop({
                    'name': breakType['name'],
                    'displayName': breakType['displayName'],
                    'reason': reasonController.text.trim(),
                  });
                }
              },
              child: const Text('Start Break'),
            ),
          ],
        );
      },
    );
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
        title: const Text('Break Management'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchEmployees,
          ),
        ],
      ),
      drawer: const AdminSideNavigation(currentRoute: '/break_management'),
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
                        onPressed: _fetchEmployees,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _employees.isEmpty
                  ? const Center(
                      child: Text('No employees found'),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchEmployees,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _employees.length,
                        itemBuilder: (context, index) {
                          final employee = _employees[index];
                          final breakStatus = employee['breakStatus'];
                          final isCheckedIn = breakStatus?['isCheckedIn'] ?? false;
                          final isOnBreak = breakStatus?['isOnBreak'] ?? false;
                          final totalBreaks = breakStatus?['totalBreaks'] ?? 0;
                          final totalBreakDuration = breakStatus?['totalBreakDuration'] ?? 0;
                          
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
                                      CircleAvatar(
                                        backgroundColor: colorScheme.primary,
                                        child: Text(
                                          (employee['name'] != null && employee['name'].isNotEmpty) 
                                              ? employee['name'][0].toUpperCase() 
                                              : '?',
                                          style: TextStyle(
                                            color: colorScheme.onPrimary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              employee['name'] ?? 'Unknown User',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Text(
                                              employee['email'] ?? 'No email',
                                              style: TextStyle(
                                                color: colorScheme.onSurface.withOpacity(0.7),
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isCheckedIn
                                              ? (isOnBreak ? Colors.orange : Colors.green)
                                              : Colors.grey,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          isCheckedIn
                                              ? (isOnBreak ? 'On Break' : 'Working')
                                              : 'Not Checked In',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Total Breaks Today: $totalBreaks',
                                          style: TextStyle(
                                            color: colorScheme.onSurface.withOpacity(0.8),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        'Break Time: ${(totalBreakDuration / (1000 * 60)).round()} min',
                                        style: TextStyle(
                                          color: colorScheme.onSurface.withOpacity(0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (isCheckedIn && !isOnBreak)
                                        ElevatedButton.icon(
                                          onPressed: () => _startBreak(
                                            employee['_id'],
                                            employee['name'],
                                          ),
                                          icon: const Icon(Icons.free_breakfast, size: 16),
                                          label: const Text('Start Break'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.orange,
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                      if (isCheckedIn && isOnBreak)
                                        ElevatedButton.icon(
                                          onPressed: () => _endBreak(
                                            employee['_id'],
                                            employee['name'],
                                          ),
                                          icon: const Icon(Icons.stop_circle, size: 16),
                                          label: const Text('End Break'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                      if (!isCheckedIn)
                                        Text(
                                          'Employee must check in first',
                                          style: TextStyle(
                                            color: colorScheme.onSurface.withOpacity(0.5),
                                            fontStyle: FontStyle.italic,
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
}