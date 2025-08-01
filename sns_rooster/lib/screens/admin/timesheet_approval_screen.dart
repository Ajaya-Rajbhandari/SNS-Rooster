import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../config/api_config.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/admin_side_navigation.dart';
import '../../services/global_notification_service.dart';

class TimesheetApprovalScreen extends StatefulWidget {
  const TimesheetApprovalScreen({super.key});

  @override
  State<TimesheetApprovalScreen> createState() =>
      _TimesheetApprovalScreenState();
}

class _TimesheetApprovalScreenState extends State<TimesheetApprovalScreen> {
  List<Map<String, dynamic>> _pendingTimesheets = [];
  bool _isLoading = true;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;
  final int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _fetchPendingTimesheets();
  }

  Future<void> _fetchPendingTimesheets() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      final response = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}/attendance/pending?page=$_currentPage&limit=$_pageSize'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _pendingTimesheets =
              List<Map<String, dynamic>>.from(data['timesheets']);
          _totalPages = data['totalPages'];
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to fetch pending timesheets');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _approveTimesheet(String attendanceId, {String? comment}) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/attendance/$attendanceId/approve'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'adminComment': comment ?? '',
        }),
      );

      if (response.statusCode == 200) {
        Provider.of<GlobalNotificationService>(context, listen: false)
            .showSuccess('Timesheet approved successfully');
        _fetchPendingTimesheets();
      } else {
        throw Exception('Failed to approve timesheet');
      }
    } catch (e) {
      Provider.of<GlobalNotificationService>(context, listen: false)
          .showError('Error approving timesheet: $e');
    }
  }

  Future<void> _rejectTimesheet(String attendanceId, String reason) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/attendance/$attendanceId/reject'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'adminComment': reason,
        }),
      );

      if (response.statusCode == 200) {
        Provider.of<GlobalNotificationService>(context, listen: false)
            .showSuccess('Timesheet rejected successfully');
        _fetchPendingTimesheets();
      } else {
        throw Exception('Failed to reject timesheet');
      }
    } catch (e) {
      Provider.of<GlobalNotificationService>(context, listen: false)
          .showError('Error rejecting timesheet: $e');
    }
  }

  void _showRejectDialog(String attendanceId, String employeeName) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Timesheet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Reject timesheet for $employeeName?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for rejection',
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
              if (reasonController.text.trim().isEmpty) {
                Provider.of<GlobalNotificationService>(context, listen: false)
                    .showError('Please provide a reason for rejection');
                return;
              }
              Navigator.of(context).pop();
              _rejectTimesheet(attendanceId, reasonController.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timesheet Approvals'),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchPendingTimesheets,
          ),
        ],
      ),
      drawer: const AdminSideNavigation(currentRoute: '/timesheet_approval'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_error',
                          style: TextStyle(color: theme.colorScheme.error)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchPendingTimesheets,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _pendingTimesheets.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle,
                              size: 64, color: Colors.green),
                          const SizedBox(height: 16),
                          Text(
                            'No pending timesheets',
                            style: theme.textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'All timesheets have been reviewed',
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _pendingTimesheets.length,
                            itemBuilder: (context, index) {
                              final timesheet = _pendingTimesheets[index];
                              final user =
                                  timesheet['user'] as Map<String, dynamic>?;
                              final userName = user != null
                                  ? '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'
                                      .trim()
                                  : 'Unknown User';

                              // Check if this is the current user's own timesheet
                              final currentUserId = Provider.of<AuthProvider>(
                                      context,
                                      listen: false)
                                  .user?['_id'];
                              final timesheetUserId = user?['_id'];
                              final isOwnTimesheet =
                                  currentUserId == timesheetUserId;
                              final date =
                                  DateTime.tryParse(timesheet['date'] ?? '');
                              final checkInTime = timesheet['checkInTime'];
                              final checkOutTime = timesheet['checkOutTime'];
                              final totalBreakDuration =
                                  timesheet['totalBreakDuration'] ?? 0;

                              // Format times for display
                              String formatTime(String? timeString) {
                                if (timeString == null || timeString.isEmpty) {
                                  return '--';
                                }
                                try {
                                  final time = DateTime.parse(timeString);
                                  return DateFormat('h:mm a').format(time);
                                } catch (e) {
                                  return timeString;
                                }
                              }

                              // Format break duration
                              String formatBreakDuration(int milliseconds) {
                                if (milliseconds <= 0) return '0m';
                                final minutes =
                                    (milliseconds / (1000 * 60)).round();
                                if (minutes < 60) {
                                  return '${minutes}m';
                                } else {
                                  final hours = minutes ~/ 60;
                                  final remainingMinutes = minutes % 60;
                                  return remainingMinutes > 0
                                      ? '${hours}h ${remainingMinutes}m'
                                      : '${hours}h';
                                }
                              }

                              // Calculate total work time
                              String calculateWorkTime() {
                                if (checkInTime == null ||
                                    checkOutTime == null) {
                                  return '--';
                                }
                                try {
                                  final checkIn = DateTime.parse(checkInTime);
                                  final checkOut = DateTime.parse(checkOutTime);
                                  final totalMs = checkOut
                                      .difference(checkIn)
                                      .inMilliseconds;
                                  final workMs = totalMs - totalBreakDuration;
                                  if (workMs <= 0) return '0m';

                                  final minutes =
                                      (workMs / (1000 * 60)).round();
                                  if (minutes < 60) {
                                    return '${minutes}m';
                                  } else {
                                    final hours = minutes ~/ 60;
                                    final remainingMinutes = minutes % 60;
                                    return remainingMinutes > 0
                                        ? '${hours}h ${remainingMinutes}m'
                                        : '${hours}h';
                                  }
                                } catch (e) {
                                  return '--';
                                }
                              }

                              return Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  userName,
                                                  style: theme
                                                      .textTheme.titleMedium
                                                      ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                if (user != null &&
                                                    user['department'] != null)
                                                  Text(
                                                    user['department'],
                                                    style: theme
                                                        .textTheme.bodySmall
                                                        ?.copyWith(
                                                      color: Colors.grey,
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
                                              color: Colors.orange
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                  color: Colors.orange),
                                            ),
                                            child: Text(
                                              'Pending',
                                              style: TextStyle(
                                                color: Colors.orange[700],
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      if (date != null)
                                        Text(
                                          'Date: ${DateFormat('EEEE, MMMM d, yyyy').format(date)}',
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Clock In:',
                                                  style: theme
                                                      .textTheme.bodySmall
                                                      ?.copyWith(
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                                Text(
                                                  formatTime(checkInTime),
                                                  style: theme
                                                      .textTheme.bodyMedium
                                                      ?.copyWith(
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Clock Out:',
                                                  style: theme
                                                      .textTheme.bodySmall
                                                      ?.copyWith(
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                                Text(
                                                  formatTime(checkOutTime),
                                                  style: theme
                                                      .textTheme.bodyMedium
                                                      ?.copyWith(
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Break Time:',
                                                  style: theme
                                                      .textTheme.bodySmall
                                                      ?.copyWith(
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                                Text(
                                                  formatBreakDuration(
                                                      totalBreakDuration),
                                                  style: theme
                                                      .textTheme.bodyMedium
                                                      ?.copyWith(
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Work Time:',
                                                  style: theme
                                                      .textTheme.bodySmall
                                                      ?.copyWith(
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                                Text(
                                                  calculateWorkTime(),
                                                  style: theme
                                                      .textTheme.bodyMedium
                                                      ?.copyWith(
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.blue[700],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      if (isOwnTimesheet) ...[
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.grey
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border:
                                                Border.all(color: Colors.grey),
                                          ),
                                          child: Text(
                                            'You cannot approve/reject your own timesheet',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                      ] else ...[
                                        Row(
                                          children: [
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                onPressed: () =>
                                                    _approveTimesheet(
                                                        timesheet['_id']),
                                                icon: const Icon(Icons.check,
                                                    color: Colors.white),
                                                label: const Text('Approve',
                                                    style: TextStyle(
                                                        color: Colors.white)),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.green,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                onPressed: () =>
                                                    _showRejectDialog(
                                                  timesheet['_id'],
                                                  userName,
                                                ),
                                                icon: const Icon(Icons.close,
                                                    color: Colors.white),
                                                label: const Text('Reject',
                                                    style: TextStyle(
                                                        color: Colors.white)),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        if (_totalPages > 1)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  onPressed: _currentPage > 1
                                      ? () {
                                          setState(() => _currentPage--);
                                          _fetchPendingTimesheets();
                                        }
                                      : null,
                                  icon: const Icon(Icons.chevron_left),
                                ),
                                Text('Page $_currentPage of $_totalPages'),
                                IconButton(
                                  onPressed: _currentPage < _totalPages
                                      ? () {
                                          setState(() => _currentPage++);
                                          _fetchPendingTimesheets();
                                        }
                                      : null,
                                  icon: const Icon(Icons.chevron_right),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
    );
  }
}
