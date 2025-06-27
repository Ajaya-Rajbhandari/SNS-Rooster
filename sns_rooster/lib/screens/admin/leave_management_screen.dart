import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/leave_provider.dart';
import '../../models/leave_request.dart';
import '../../widgets/admin_side_navigation.dart';
import 'dart:async';

class LeaveManagementScreen extends StatefulWidget {
  const LeaveManagementScreen({super.key});

  @override
  State<LeaveManagementScreen> createState() => _LeaveManagementScreenState();
}

class _LeaveManagementScreenState extends State<LeaveManagementScreen> {
  String _selectedFilter = 'All';
  String _searchQuery = '';
  int _currentPage = 1;
  final int _pageSize = 10;
  final List<String> _filters = ['Pending', 'Approved', 'Rejected', 'All'];
  final Completer<void> _apiServiceCompleter = Completer<void>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeApiService();
      _fetchLeaveRequests();
    });
  }

  Future<void> _initializeApiService() async {
    try {
      print('DEBUG: Initializing _apiService');
      // Simulate initialization logic for _apiService
      await Future.delayed(const Duration(seconds: 1));
      _apiServiceCompleter.complete();
      print('DEBUG: _apiService initialization complete');
    } catch (e) {
      print('Error initializing _apiService: $e');
      _apiServiceCompleter.completeError(e);
    }
  }

  Future<void> _fetchLeaveRequests() async {
    final leaveProvider = Provider.of<LeaveProvider>(context, listen: false);
    try {
      await _apiServiceCompleter.future;
      print('DEBUG: Initiating fetchLeaveRequests');
      print(
          'DEBUG: Authorization header being sent: ${await leaveProvider.getAuthorizationHeader()}');
      await leaveProvider.fetchLeaveRequests();
      print(
          'DEBUG: Leave requests fetched successfully. Total requests: ${leaveProvider.leaveRequests.length}');
    } catch (e) {
      if (e is FormatException) {
        print('Error parsing response: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Error parsing backend response. Please contact admin.')),
        );
      } else if (e.toString().contains('employeeId is undefined')) {
        print('Error: employeeId is undefined for leave history request.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Employee ID is missing. Please contact admin.')),
        );
      } else {
        print('Error fetching leave requests: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Error fetching leave requests. Please try again later.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Management'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              final query = await showSearch(
                context: context,
                delegate: LeaveSearchDelegate(),
              );
              if (query != null) {
                setState(() {
                  _searchQuery = query;
                });
              }
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (context) => _filters
                .map((filter) => PopupMenuItem(
                      value: filter,
                      child: Text(filter),
                    ))
                .toList(),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Text(_selectedFilter),
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

          final leaveRequests = provider.leaveRequests
              .where((request) {
                if (_selectedFilter != 'All' &&
                    request.status.toString().split('.').last !=
                        _selectedFilter) {
                  return false;
                }
                if (_searchQuery.isNotEmpty &&
                    !request.employeeName
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase())) {
                  return false;
                }
                return true;
              })
              .skip((_currentPage - 1) * _pageSize)
              .take(_pageSize)
              .toList();

          if (leaveRequests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No ${_selectedFilter.toLowerCase()} leave requests',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: leaveRequests.length,
                  itemBuilder: (context, index) {
                    final request = leaveRequests[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        request.employeeName,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        request.leaveType
                                            .toString()
                                            .split('.')
                                            .last,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                _buildStatusChip(request.status),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDateRange(
                                    request.startDate,
                                    request.endDate,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  '${request.duration} days',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            if (request.reason.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Text(
                                'Reason:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(request.reason),
                            ],
                            if (request.status ==
                                LeaveRequestStatus.pending) ...[
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        provider.rejectLeaveRequest(request.id);
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                      child: const Text('Reject'),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        provider
                                            .approveLeaveRequest(request.id);
                                      },
                                      child: const Text('Approve'),
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
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentPage > 1)
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _currentPage--;
                          });
                        },
                        child: const Text('Previous'),
                      ),
                    if (leaveRequests.length == _pageSize)
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _currentPage++;
                          });
                        },
                        child: const Text('Next'),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
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
        color: color.withOpacity(0.1),
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

class LeaveSearchDelegate extends SearchDelegate<String> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Container();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Container();
  }
}
