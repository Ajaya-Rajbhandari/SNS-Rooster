import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/api_config.dart';
import '../../widgets/admin_side_navigation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:csv/csv.dart';
import 'dart:io';
import '../../services/attendance_service.dart';

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
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchBreakTypes();
    _fetchEmployees();
  }

  Future<void> _fetchBreakTypes() async {
    print('DEBUG: Entered _fetchBreakTypes');
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
        print('DEBUG breakTypes response: ' + data.toString());
        setState(() {
          _breakTypes = List<Map<String, dynamic>>.from(data['breakTypes']);
        });
      }
    } catch (e) {
      print('DEBUG: Caught error in _fetchBreakTypes: $e');
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
      final attendanceService = AttendanceService(authProvider);
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/auth/users'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}',
        },
      );

      if (response.statusCode == 200) {
        final users = jsonDecode(response.body) as List;
        print('DEBUG users response: ' + users.toString());

        // Fetch break status for each employee using AttendanceService
        List<Map<String, dynamic>> employeesWithBreakStatus = [];
        for (var user in users) {
          if (user['role'] == 'employee') {
            // Fetch attendance for today for this user
            Map<String, dynamic>? attendance;
            try {
              attendance = await attendanceService
                  .getAttendanceStatusWithData(user['_id']);
            } catch (e) {
              attendance = null;
            }
            // Extract break information from attendance data
            Map<String, dynamic>? breakStatus;
            if (attendance != null && attendance['attendance'] != null) {
              final att = attendance['attendance'];
              print('DEBUG: Attendance for ${user['email']}: $att');
              final breaks = att['breaks'] as List<dynamic>? ?? [];
              final isOnBreak = breaks.any((b) => b['end'] == null);
              final totalBreaks = breaks.length;
              final totalBreakDuration = breaks.fold<int>(0, (sum, b) {
                if (b['start'] != null && b['end'] != null) {
                  final start = DateTime.parse(b['start']);
                  final end = DateTime.parse(b['end']);
                  return sum + end.difference(start).inMinutes;
                }
                return sum;
              });
              breakStatus = {
                'isOnBreak': isOnBreak,
                'isCheckedIn': att['checkInTime'] != null,
                'checkOutTime': att['checkOutTime'],
                'totalBreaks': totalBreaks,
                'totalBreakDuration': totalBreakDuration,
                'currentBreak': isOnBreak
                    ? breaks.firstWhere((b) => b['end'] == null,
                        orElse: () => null)
                    : null,
              };
            }
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
      print('DEBUG: Caught error in _fetchEmployees: $e');
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
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
      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/attendance/end-break'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}',
        },
        body: jsonEncode({'userId': userId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
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
                          final color =
                              _parseColor(breakType['color'] ?? '#6B7280');

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
                                  _getIconData(
                                      breakType['icon'] ?? 'more_horiz'),
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                breakType['displayName'] ?? breakType['name'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(breakType['description'] ?? ''),
                                  if (breakType['minDuration'] != null ||
                                      breakType['maxDuration'] != null)
                                    Text(
                                      'Duration: ${breakType['minDuration'] ?? 0}-${breakType['maxDuration'] ?? '∞'} min',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.6),
                                      ),
                                    ),
                                  if (breakType['dailyLimit'] != null)
                                    Text(
                                      'Daily limit: ${breakType['dailyLimit']}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.6),
                                      ),
                                    ),
                                ],
                              ),
                              trailing: breakType['requiresApproval'] == true
                                  ? const Icon(Icons.admin_panel_settings,
                                      size: 16)
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

  Future<Map<String, dynamic>?> _showReasonDialog(
      Map<String, dynamic> breakType) async {
    final reasonController = TextEditingController();

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${breakType['displayName']} - Reason Required'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  'Please provide a reason for this ${breakType['displayName'].toLowerCase()}:'),
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

  Future<String?> _exportBreaksToCSV() async {
    try {
      Directory? dir;
      if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Download');
      } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        dir = await getDownloadsDirectory();
      }
      dir ??= await getApplicationDocumentsDirectory();
      final path = '${dir.path}/break-management-export.csv';
      final csvData = [
        ['Name', 'Email', 'Break Status', 'Total Breaks', 'Break Time'],
        ..._employees.map((emp) => [
              ((emp['firstName'] != null && emp['lastName'] != null)
                  ? (emp['firstName'] + ' ' + emp['lastName'])
                  : emp['email'] ?? 'Unknown User'),
              emp['email'] ?? '',
              emp['breakStatus']?['isOnBreak'] == true
                  ? 'On Break'
                  : (emp['breakStatus']?['isCheckedIn'] == true
                      ? 'Checked In'
                      : 'Not Checked In'),
              emp['breakStatus']?['totalBreaks']?.toString() ?? '0',
              emp['breakStatus']?['totalBreakDuration']?.toString() ?? '0',
            ]),
      ];
      final csvString = const ListToCsvConverter().convert(csvData);
      final file = File(path);
      await file.writeAsString(csvString);
      return path;
    } catch (e) {
      return null;
    }
  }

  Future<String?> _exportBreaksToPDF() async {
    try {
      final pdf = pw.Document();
      final headers = [
        'Name',
        'Email',
        'Break Status',
        'Total Breaks',
        'Break Time'
      ];
      final data = _employees
          .map((emp) => [
                ((emp['firstName'] != null && emp['lastName'] != null)
                    ? (emp['firstName'] + ' ' + emp['lastName'])
                    : emp['email'] ?? 'Unknown User'),
                emp['email'] ?? '',
                emp['breakStatus']?['isOnBreak'] == true
                    ? 'On Break'
                    : (emp['breakStatus']?['isCheckedIn'] == true
                        ? 'Checked In'
                        : 'Not Checked In'),
                emp['breakStatus']?['totalBreaks']?.toString() ?? '0',
                emp['breakStatus']?['totalBreakDuration']?.toString() ?? '0',
              ])
          .toList();
      pdf.addPage(
        pw.Page(
          build: (context) => pw.Table.fromTextArray(
            headers: headers,
            data: data,
            cellStyle: pw.TextStyle(fontSize: 10),
            headerStyle:
                pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
            headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
            border: null,
            cellAlignment: pw.Alignment.centerLeft,
          ),
        ),
      );
      Directory? dir;
      if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Download');
      } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        dir = await getDownloadsDirectory();
      }
      dir ??= await getApplicationDocumentsDirectory();
      final path = '${dir.path}/break-management-export.pdf';
      final file = File(path);
      await file.writeAsBytes(await pdf.save());
      return path;
    } catch (e) {
      return null;
    }
  }

  Future<void> _showBreakHistoryModal(
      String userId, String employeeName) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final attendanceService = AttendanceService(authProvider);
    Map<String, dynamic>? attendance;
    try {
      final result =
          await attendanceService.getAttendanceStatusWithData(userId);
      attendance = result['attendance'];
    } catch (e) {
      attendance = null;
    }
    final breaks = attendance != null
        ? (attendance['breaks'] as List<dynamic>? ?? [])
        : [];
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Break History for $employeeName'),
          content: attendance == null
              ? const Text('No attendance data for today.')
              : breaks.isEmpty
                  ? const Text('No breaks taken today.')
                  : SizedBox(
                      width: 350,
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: breaks.length,
                        separatorBuilder: (context, i) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final br = breaks[index];
                          final breakType = br['breakTypeName'] ?? 'Break';
                          final start = br['start'] != null
                              ? DateTime.tryParse(br['start'])
                              : null;
                          final end = br['end'] != null
                              ? DateTime.tryParse(br['end'])
                              : null;
                          final duration = (start != null && end != null)
                              ? end.difference(start).inMinutes
                              : null;
                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            child: ListTile(
                              leading: const Icon(Icons.free_breakfast,
                                  color: Colors.orange),
                              title: Text(breakType,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Start: ' +
                                      (start != null
                                          ? _formatDateTime(start)
                                          : '-')),
                                  Text('End: ' +
                                      (end != null
                                          ? _formatDateTime(end)
                                          : 'Ongoing')),
                                  if (duration != null)
                                    Text('Duration: $duration min'),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Filter employees by search query
    final filteredEmployees = _searchQuery.isEmpty
        ? _employees
        : _employees.where((emp) {
            final name =
                ((emp['firstName'] ?? '') + ' ' + (emp['lastName'] ?? ''))
                    .toLowerCase();
            final email = (emp['email'] ?? '').toLowerCase();
            final query = _searchQuery.toLowerCase();
            return name.contains(query) || email.contains(query);
          }).toList();

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
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'Export CSV') {
                final filePath = await _exportBreaksToCSV();
                if (filePath != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('CSV exported to: $filePath')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to export CSV')),
                  );
                }
              } else if (value == 'Export PDF') {
                final filePath = await _exportBreaksToPDF();
                if (filePath != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('PDF exported to: $filePath')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to export PDF')),
                  );
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: 'Export CSV', child: Text('Export to CSV')),
              const PopupMenuItem(
                  value: 'Export PDF', child: Text('Export to PDF')),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  const Icon(Icons.download, color: Colors.white),
                  const SizedBox(width: 4),
                  const Text('Export', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
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
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Search employees',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: filteredEmployees.length,
                        itemBuilder: (context, index) {
                          final employee = filteredEmployees[index];
                          final breakStatus = employee['breakStatus'];
                          final isCheckedIn =
                              breakStatus?['isCheckedIn'] ?? false;
                          final isOnBreak = breakStatus?['isOnBreak'] ?? false;
                          final totalBreaks = breakStatus?['totalBreaks'] ?? 0;
                          final totalBreakDuration =
                              breakStatus?['totalBreakDuration'] ?? 0;

                          bool canEndBreak = isOnBreak &&
                              isCheckedIn &&
                              breakStatus['checkOutTime'] == null;

                          return GestureDetector(
                            onTap: () => _showBreakHistoryModal(
                                employee['_id'],
                                ((employee['firstName'] != null &&
                                        employee['lastName'] != null)
                                    ? (employee['firstName'] +
                                        ' ' +
                                        employee['lastName'])
                                    : employee['email'] ?? 'Unknown User')),
                            child: Card(
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
                                            ((employee['firstName'] != null &&
                                                    employee['firstName']
                                                        .isNotEmpty)
                                                ? employee['firstName'][0]
                                                    .toUpperCase()
                                                : (employee['email'] != null &&
                                                        employee['email']
                                                            .isNotEmpty)
                                                    ? employee['email'][0]
                                                        .toUpperCase()
                                                    : '?'),
                                            style: TextStyle(
                                              color: colorScheme.onPrimary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                ((employee['firstName'] !=
                                                            null &&
                                                        employee['lastName'] !=
                                                            null)
                                                    ? (employee['firstName'] +
                                                        ' ' +
                                                        employee['lastName'])
                                                    : employee['email'] ??
                                                        'Unknown User'),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              Text(
                                                employee['email'] ?? 'No email',
                                                style: TextStyle(
                                                  color: colorScheme.onSurface
                                                      .withOpacity(0.7),
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
                                                ? (isOnBreak
                                                    ? Colors.orange
                                                    : Colors.green)
                                                : Colors.grey,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            isCheckedIn
                                                ? (isOnBreak
                                                    ? 'On Break'
                                                    : 'Working')
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
                                              color: colorScheme.onSurface
                                                  .withOpacity(0.8),
                                            ),
                                          ),
                                        ),
                                        Text(
                                          'Break Time: ${(totalBreakDuration / (1000 * 60)).round()} min',
                                          style: TextStyle(
                                            color: colorScheme.onSurface
                                                .withOpacity(0.8),
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
                                              ((employee['firstName'] != null &&
                                                      employee['lastName'] !=
                                                          null)
                                                  ? (employee['firstName'] +
                                                      ' ' +
                                                      employee['lastName'])
                                                  : employee['email'] ??
                                                      'Unknown User'),
                                            ),
                                            icon: const Icon(
                                                Icons.free_breakfast,
                                                size: 16),
                                            label: const Text('Start Break'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.orange,
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                        if (canEndBreak)
                                          ElevatedButton.icon(
                                            onPressed: () => _endBreak(
                                              employee['_id'],
                                              ((employee['firstName'] != null &&
                                                      employee['lastName'] !=
                                                          null)
                                                  ? (employee['firstName'] +
                                                      ' ' +
                                                      employee['lastName'])
                                                  : employee['email'] ??
                                                      'Unknown User'),
                                            ),
                                            icon: const Icon(Icons.stop_circle,
                                                size: 16),
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
                                              color: colorScheme.onSurface
                                                  .withOpacity(0.5),
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
