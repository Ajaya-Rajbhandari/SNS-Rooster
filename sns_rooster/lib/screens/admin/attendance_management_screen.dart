import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../widgets/admin_side_navigation.dart';
import '../../providers/admin_attendance_provider.dart';
import '../../providers/employee_provider.dart';

class AttendanceManagementScreen extends StatefulWidget {
  const AttendanceManagementScreen({super.key});

  @override
  State<AttendanceManagementScreen> createState() =>
      _AttendanceManagementScreenState();
}

class _AttendanceManagementScreenState
    extends State<AttendanceManagementScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedEmployeeId;
  bool _isFiltering = false;
  final int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _selectedEmployeeId = null;
    // Fetch all attendance records when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _fetchAttendancePage(1);
      Provider.of<EmployeeProvider>(context, listen: false).getEmployees();
    });
  }

  Future<void> _fetchAttendancePage(int page) async {
    setState(() => _isFiltering = true);
    final provider =
        Provider.of<AdminAttendanceProvider>(context, listen: false);
    await provider.fetchAttendance(
      start: _startDate?.toIso8601String(),
      end: _endDate?.toIso8601String(),
      userId: _selectedEmployeeId,
      page: page,
      limit: _pageSize,
    );

    setState(() => _isFiltering = false);
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _fetchAttendancePage(1);
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    final date = DateTime.tryParse(dateString)?.toLocal();
    if (date == null) return 'N/A';
    return DateFormat('MMM dd, yyyy').format(date);
  }

  String _formatTime(String? dateTimeString) {
    if (dateTimeString == null) return 'N/A';
    final dateTime = DateTime.tryParse(dateTimeString)?.toLocal();
    if (dateTime == null) return 'N/A';
    return DateFormat('hh:mm a').format(dateTime);
  }

  String _formatMinutesToHourMin(int? minutes) {
    if (minutes == null || minutes <= 0) return '0h 0m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h}h ${m}m';
  }

  Widget _statusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'present':
        color = Colors.green;
        break;
      case 'on break':
        color = Colors.orange;
        break;
      case 'clocked in':
        color = Colors.blue;
        break;
      case 'absent':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildDateRangePicker() {
    return GestureDetector(
      onTap: _selectDateRange,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _startDate != null && _endDate != null
                    ? '${_formatDate(_startDate!.toString())} - ${_formatDate(_endDate!.toString())}'
                    : 'Date Range',
                style: TextStyle(
                  fontSize: 13,
                  color: _startDate != null && _endDate != null
                      ? Colors.black
                      : Colors.grey[600],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_startDate != null && _endDate != null)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _startDate = null;
                    _endDate = null;
                  });
                  _fetchAttendancePage(1);
                },
                child: Icon(Icons.clear, size: 14, color: Colors.grey[600]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeDropdown() {
    final employeeProvider =
        Provider.of<EmployeeProvider>(context, listen: false);
    return SizedBox(
      height: 36,
      child: DropdownButtonFormField<String>(
        value: _selectedEmployeeId,
        decoration: InputDecoration(
          labelText: 'Employee',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          isDense: true,
          labelStyle: const TextStyle(fontSize: 12),
        ),
        items: [
          const DropdownMenuItem(
            value: null,
            child: Text('All', style: TextStyle(fontSize: 12)),
          ),
          ...employeeProvider.employees.map((employee) {
            return DropdownMenuItem(
              value: employee.userId,
              child: Text(
                '${employee.firstName ?? ''} ${employee.lastName ?? ''}'.trim(),
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
        ],
        onChanged: (value) {
          setState(() {
            _selectedEmployeeId = value;
          });
          _fetchAttendancePage(1);
        },
        menuMaxHeight: 150,
        icon: const Icon(Icons.arrow_drop_down, size: 16),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, Color color, IconData icon) {
    return Card(
      elevation: 4,
      shadowColor: color.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off,
              size: 60, color: colorScheme.onSurface.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'No attendance records found.',
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceList(List<dynamic> attendanceRecords) {
    return RefreshIndicator(
      onRefresh: () async {
        await _fetchAttendancePage(1);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: attendanceRecords.length,
        itemBuilder: (context, index) {
          final record = attendanceRecords[index];
          final user = record.user;

          // Fix: Handle user as Map<String, dynamic> instead of object
          String employeeName = 'Unknown Employee';
          String employeeEmail = 'No email';

          if (user != null) {
            if (user is Map<String, dynamic>) {
              // Handle as Map
              final firstName = user['firstName'] ?? '';
              final lastName = user['lastName'] ?? '';
              employeeName = '$firstName $lastName'.trim();
              employeeEmail = user['email'] ?? 'No email';
            } else {
              // Handle as object (fallback)
              employeeName =
                  '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim();
              employeeEmail = user.email ?? 'No email';
            }
          }

          return Card(
            elevation: 3,
            shadowColor: Colors.black.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with employee info and status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.blue.shade100,
                              child: Icon(
                                Icons.person,
                                color: Colors.blue.shade700,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    employeeName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    employeeEmail,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      _statusBadge(record.status?.toString() ?? 'present'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Date and times
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Date: ${_formatDate(record.date?.toString())}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Icon(Icons.login, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Check-in: ${_formatTime(record.checkInTime?.toString())}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.logout, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Check-out: ${_formatTime(record.checkOutTime?.toString())}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Break time
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      const Text(
                        'Total Break Time: ',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        _formatMinutesToHourMin(record.totalBreakDuration),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),

                  // Breaks list if any
                  if (record.breaks != null && record.breaks.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Breaks:',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    ...record.breaks.map<Widget>((breakItem) {
                      final start = breakItem['start'] != null
                          ? DateTime.tryParse(breakItem['start'].toString())
                          : null;
                      final end = breakItem['end'] != null
                          ? DateTime.tryParse(breakItem['end'].toString())
                          : null;
                      String duration = '-';
                      if (start != null && end != null) {
                        final d = end.difference(start);
                        duration = '${d.inHours}h ${d.inMinutes % 60}m';
                      }
                      return Padding(
                        padding: const EdgeInsets.only(left: 16, top: 4),
                        child: Row(
                          children: [
                            Icon(Icons.pause,
                                size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              '${_formatTime(start?.toString())} - ${_formatTime(end?.toString())} ($duration)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Records'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _fetchAttendancePage(1),
          ),
        ],
      ),
      drawer: const AdminSideNavigation(currentRoute: '/attendance_management'),
      body: Consumer<AdminAttendanceProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final attendanceRecords = provider.attendanceRecords;

          // Calculate stats
          final totalRecords = attendanceRecords.length;
          final presentCount = attendanceRecords
              .where((record) =>
                  (record.status.toString().toLowerCase() ?? 'present') ==
                  'present')
              .length;
          final onBreakCount = attendanceRecords
              .where((record) =>
                  (record.status.toString().toLowerCase() ?? '') == 'on break')
              .length;

          return Column(
            children: [
              // Quick Stats Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.05),
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Records',
                        totalRecords.toString(),
                        Colors.blue,
                        Icons.assessment,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Present',
                        presentCount.toString(),
                        Colors.green,
                        Icons.check_circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'On Break',
                        onBreakCount.toString(),
                        Colors.orange,
                        Icons.pause_circle,
                      ),
                    ),
                  ],
                ),
              ),

              // Filter Section - Responsive Design
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmallScreen = constraints.maxWidth < 400;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.filter_list,
                                size: 18, color: Colors.grey[700]),
                            const SizedBox(width: 8),
                            Text(
                              'Filters',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Responsive date range and employee filter
                        if (isSmallScreen) ...[
                          // Stack vertically on small screens
                          Column(
                            children: [
                              _buildDateRangePicker(),
                              const SizedBox(height: 8),
                              _buildEmployeeDropdown(),
                            ],
                          ),
                        ] else ...[
                          // Side by side on larger screens
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: _buildDateRangePicker(),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 1,
                                child: _buildEmployeeDropdown(),
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 10),

                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isFiltering
                                    ? null
                                    : () {
                                        setState(() {
                                          _startDate = null;
                                          _endDate = null;
                                          _selectedEmployeeId = null;
                                        });
                                        _fetchAttendancePage(1);
                                      },
                                icon: const Icon(Icons.clear, size: 18),
                                label: const Text('Clear'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.grey[700],
                                  side: BorderSide(color: Colors.grey.shade300),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isFiltering
                                    ? null
                                    : () {
                                        // Export functionality
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'Export functionality coming soon!')),
                                        );
                                      },
                                icon: const Icon(Icons.download, size: 18),
                                label: const Text('Export'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: colorScheme.onPrimary,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Content Section
              Expanded(
                child: attendanceRecords.isEmpty
                    ? _buildEmptyState()
                    : _buildAttendanceList(attendanceRecords),
              ),
            ],
          );
        },
      ),
    );
  }
}
