import 'package:flutter/material.dart';
import 'package:sns_rooster/utils/logger.dart';
import 'package:provider/provider.dart';
import '../../providers/leave_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/leave_request.dart';
import '../../widgets/admin_side_navigation.dart';
import '../../widgets/role_filter_chip.dart';
import 'dart:async';
import 'package:intl/intl.dart';

class LeaveManagementScreen extends StatefulWidget {
  const LeaveManagementScreen({super.key});

  @override
  State<LeaveManagementScreen> createState() => _LeaveManagementScreenState();
}

class _LeaveManagementScreenState extends State<LeaveManagementScreen>
    with WidgetsBindingObserver {
  final List<Map<String, dynamic>> _leaveRequests = [];
  String _selectedStatus = 'all';
  String _selectedRole = 'all';
  bool _showHalfDayOnly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeApiService();
      _fetchLeaveRequests();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Refresh data when app comes back to foreground
      _fetchLeaveRequests();
    }
  }

  Future<void> _initializeApiService() async {
    try {
      log('DEBUG: Initializing _apiService');
      // Simulate initialization logic for _apiService
      await Future.delayed(const Duration(seconds: 1));
      // _apiServiceCompleter.complete(); // This line is removed
      log('DEBUG: _apiService initialization complete');
    } catch (e) {
      log('Error initializing _apiService: $e');
      // _apiServiceCompleter.completeError(e); // This line is removed
    }
  }

  Future<void> _fetchLeaveRequests() async {
    final leaveProvider = Provider.of<LeaveProvider>(context, listen: false);
    try {
      // await _apiServiceCompleter.future; // This line is removed
      log('DEBUG: Initiating fetchLeaveRequests');
      log('DEBUG: Authorization header being sent: ${await leaveProvider.getAuthorizationHeader()}');

      // Always include admins by default, but allow filtering
      String role = 'all';
      if (_selectedRole == 'employee') {
        role = 'employee';
      } else if (_selectedRole == 'admin') {
        role = 'admin';
      }

      await leaveProvider.fetchLeaveRequests(
        includeAdmins:
            true, // Always include admins, let backend handle filtering
        role: role,
      );
      log('DEBUG: Leave requests fetched successfully. Total requests: ${leaveProvider.leaveRequests.length}');
    } catch (e) {
      if (e is FormatException) {
        log('Error parsing response: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Error parsing backend response. Please contact admin.')),
        );
      } else if (e.toString().contains('employeeId is undefined')) {
        log('Error: employeeId is undefined for leave history request.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Employee ID is missing. Please contact admin.')),
        );
      } else {
        log('Error fetching leave requests: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Error fetching leave requests. Please try again later.')),
        );
      }
    }
  }

  void _onFilterChanged(String value) {
    setState(() {
      _selectedStatus = value;
      // _currentPage = 1; // This line is removed
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      // _searchQuery = query; // This line is removed
      // _currentPage = 1; // This line is removed
    });
  }

  void _onRoleChanged(String? role) {
    setState(() {
      _selectedRole = role!;
    });
    _fetchLeaveRequests();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Management'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _fetchLeaveRequests();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Refreshing leave requests...'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          // IconButton( // This line is removed
          //   icon: const Icon(Icons.search), // This line is removed
          //   onPressed: () async { // This line is removed
          //     final query = await showSearch( // This line is removed
          //       context: context, // This line is removed
          //       delegate: LeaveSearchDelegate(initialQuery: _searchQuery), // This line is removed
          //     ); // This line is removed
          //     if (query != null) { // This line is removed
          //       _onSearchChanged(query); // This line is removed
          //     } // This line is removed
          //   }, // This line is removed
          // ), // This line is removed
          PopupMenuButton<String>(
            onSelected: _onFilterChanged,
            itemBuilder: (context) => ['Pending', 'Approved', 'Rejected', 'All']
                .map((filter) => PopupMenuItem(
                      value: filter,
                      child: Text(filter),
                    ))
                .toList(),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Text(_selectedStatus),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
      drawer: const AdminSideNavigation(currentRoute: '/leave_management'),
      body: Consumer<LeaveProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final leaveRequests = provider.leaveRequests.where((request) {
            final statusStr = request.status.toString().split('.').last;
            if (_selectedStatus != 'All' &&
                statusStr.toLowerCase() != _selectedStatus.toLowerCase()) {
              return false;
            }
            // if (_searchQuery.isNotEmpty && // This line is removed
            //     !('${request.employeeName} ${request.department}' // This line is removed
            //         .toLowerCase() // This line is removed
            //         .contains(_searchQuery.toLowerCase()))) { // This line is removed
            //   return false; // This line is removed
            // } // This line is removed
            if (_showHalfDayOnly && !request.isHalfDay) {
              return false;
            }
            // Add role filtering logic
            if (_selectedRole != 'all' && request.role != _selectedRole) {
              return false;
            }
            return true;
          }).toList();

          // Calculate stats
          final pendingCount = leaveRequests
              .where((r) => r.status == LeaveRequestStatus.pending)
              .length;
          final approvedCount = leaveRequests
              .where((r) => r.status == LeaveRequestStatus.approved)
              .length;
          final rejectedCount = leaveRequests
              .where((r) => r.status == LeaveRequestStatus.rejected)
              .length;

          return Column(
            children: [
              // Quick Stats Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.05),
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Pending',
                        pendingCount.toString(),
                        Colors.orange,
                        Icons.pending,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Approved',
                        approvedCount.toString(),
                        Colors.green,
                        Icons.check_circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Rejected',
                        rejectedCount.toString(),
                        Colors.red,
                        Icons.cancel,
                      ),
                    ),
                  ],
                ),
              ),

              // Filters Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border:
                      Border(bottom: BorderSide(color: Colors.grey.shade200)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filters',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Role filters in a row
                    Row(
                      children: [
                        Expanded(
                          child: RoleFilterChip(
                            selectedRole: _selectedRole,
                            onRoleChanged: _onRoleChanged,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Additional filters in a row
                    Row(
                      children: [
                        FilterChip(
                          selected: _showHalfDayOnly,
                          onSelected: (selected) {
                            setState(() {
                              _showHalfDayOnly = selected;
                              // _currentPage = 1; // This line is removed
                            });
                          },
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 16,
                                color: _showHalfDayOnly
                                    ? Colors.white
                                    : Colors.blue,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Half Day Only',
                                style: TextStyle(
                                  color: _showHalfDayOnly
                                      ? Colors.white
                                      : Colors.blue,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: _showHalfDayOnly
                              ? Colors.blue
                              : Colors.blue.withValues(alpha: 0.1),
                          selectedColor: Colors.blue,
                          checkmarkColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                        const SizedBox(width: 12),
                        FilterChip(
                          selected: _selectedStatus != 'All',
                          onSelected: (selected) {
                            // This will be handled by the dropdown in AppBar
                          },
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.filter_list,
                                size: 16,
                                color: _selectedStatus != 'All'
                                    ? Colors.white
                                    : Colors.grey[600],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Status: $_selectedStatus',
                                style: TextStyle(
                                  color: _selectedStatus != 'All'
                                      ? Colors.white
                                      : Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: _selectedStatus != 'All'
                              ? Colors.green
                              : Colors.grey.withValues(alpha: 0.1),
                          selectedColor: Colors.green,
                          checkmarkColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Leave Requests List
              Expanded(
                child: leaveRequests.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: () async {
                          await _fetchLeaveRequests();
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: leaveRequests.length,
                          itemBuilder: (context, index) {
                            final request = leaveRequests[index];
                            // final isProcessing = // This line is removed
                            //     _processingRequestIndex == index; // This line is removed
                            return _buildModernLeaveCard(request, false, index,
                                provider); // This line is changed
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
      String title, String count, Color color, IconData icon) {
    return Card(
      elevation: 4,
      shadowColor: color.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
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
              count,
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No leave requests found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernLeaveCard(LeaveRequest request, bool isProcessing,
      int index, LeaveProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: InkWell(
        onTap: () {
          // Handle card tap if needed
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with employee name and status
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
                                request.employeeName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                request.department,
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
                  _buildStatusChip(request.status),
                ],
              ),
              const SizedBox(height: 16),

              // Leave details with icons
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    '${DateFormat('MMM dd').format(request.startDate)} - ${DateFormat('MMM dd, yyyy').format(request.endDate)}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    request.isHalfDay ? '0.5 days' : '${request.duration} days',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Leave type and half-day indicator
              Row(
                children: [
                  Icon(Icons.label, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    request.leaveType
                        .toString()
                        .split('.')
                        .last
                        .replaceAll('_', ' '),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  if (request.isHalfDay) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'HALF DAY',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              // Reason
              if (request.reason.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.chat_bubble_outline,
                        size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        request.reason,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // Action buttons for pending requests
              if (request.status == LeaveRequestStatus.pending) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: false // isProcessing // This line is changed
                            ? null
                            : () async {
                                // setState(() { // This line is removed
                                //   _processingRequestIndex = index; // This line is removed
                                // }); // This line is removed
                                try {
                                  await provider.rejectLeaveRequest(request.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('Leave request rejected.')),
                                  );
                                  _fetchLeaveRequests();
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Error rejecting leave request: $e')),
                                  );
                                } finally {
                                  // setState(() { // This line is removed
                                  //   _processingRequestIndex = null; // This line is removed
                                  // }); // This line is removed
                                }
                              },
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: false // isProcessing // This line is changed
                            ? null
                            : () async {
                                // setState(() { // This line is removed
                                //   _processingRequestIndex = index; // This line is removed
                                // }); // This line is removed
                                try {
                                  // Check if this is an admin leave request and prevent self-approval
                                  final currentUser = Provider.of<AuthProvider>(
                                          context,
                                          listen: false)
                                      .user;
                                  final currentUserId = currentUser?['_id'];

                                  if (request.role == 'admin' &&
                                      request.user == currentUserId) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'You cannot approve your own leave request.'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }

                                  await provider
                                      .approveLeaveRequest(request.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('Leave request approved.')),
                                  );
                                  _fetchLeaveRequests();
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Error approving leave request: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                } finally {
                                  // setState(() { // This line is removed
                                  //   _processingRequestIndex = null; // This line is removed
                                  // }); // This line is removed
                                }
                              },
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(LeaveRequestStatus status) {
    Color color;
    String text;

    switch (status) {
      case LeaveRequestStatus.pending:
        color = Colors.orange;
        text = 'Pending';
        break;
      case LeaveRequestStatus.approved:
        color = Colors.green;
        text = 'Approved';
        break;
      case LeaveRequestStatus.rejected:
        color = Colors.red;
        text = 'Rejected';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDateRange(DateTime startDate, DateTime endDate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.calendar_today, size: 16),
            const SizedBox(width: 8),
            Text(
              'From: ${_formatDate(startDate)}',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.calendar_today, size: 16),
            const SizedBox(width: 8),
            Text(
              'To: ${_formatDate(endDate)}',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
