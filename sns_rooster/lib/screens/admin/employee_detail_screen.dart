import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sns_rooster/screens/admin/edit_employee_dialog.dart';
import 'package:sns_rooster/providers/employee_provider.dart';
import 'package:sns_rooster/providers/auth_provider.dart';
import 'package:sns_rooster/providers/admin_settings_provider.dart';
import '../../config/api_config.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sns_rooster/screens/profile/profile_screen.dart'
    show showDocumentDialog;

/// Helper function to format duration in a human-readable format
/// Shows hours and minutes when duration is over 60 minutes
String _formatDuration(int totalMinutes) {
  if (totalMinutes >= 60) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return '${hours}h ${minutes}m';
  } else {
    return '${totalMinutes}m';
  }
}

class EmployeeDetailScreen extends StatefulWidget {
  final Map<String, dynamic> employee;
  final EmployeeProvider employeeProvider;

  const EmployeeDetailScreen({
    Key? key,
    required this.employeeProvider,
    required this.employee,
  }) : super(key: key);

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _fullProfile;
  List<Map<String, dynamic>> _attendanceRecords = [];
  bool _isLoading = false;
  bool _isAttendanceLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchFullProfile();
    _fetchAttendance();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchFullProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = widget.employee['userId'] ?? widget.employee['_id'];

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/auth/users/$userId/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _fullProfile = data['profile'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load profile';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchAttendance() async {
    setState(() {
      _isAttendanceLoading = true;
    });

    try {
      final userId = widget.employee['userId'] ?? widget.employee['_id'];
      if (userId == null) return;

      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Use the admin endpoint to get attendance for specific user
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/attendance/user/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // The getUserAttendance endpoint returns data directly as an array
        List<dynamic> attendanceList;
        if (data is List) {
          attendanceList = data;
        } else if (data is Map && data['attendance'] != null) {
          attendanceList = data['attendance'] as List<dynamic>;
        } else {
          attendanceList = [];
        }

        setState(() {
          _attendanceRecords = attendanceList.cast<Map<String, dynamic>>();
          _isAttendanceLoading = false;
        });
      } else {
        print(
            'Error fetching attendance: ${response.statusCode} ${response.body}');
        setState(() {
          _attendanceRecords = [];
          _isAttendanceLoading = false;
        });
      }
    } catch (e) {
      print('Exception fetching attendance: $e');
      setState(() {
        _attendanceRecords = [];
        _isAttendanceLoading = false;
      });
    }
  }

  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null) return 'N/A';
    final dateTime = DateTime.tryParse(dateTimeString)?.toLocal();
    if (dateTime == null) return 'N/A';
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    final date = DateTime.tryParse(dateString);
    if (date == null) return 'N/A';
    return DateFormat('MMM dd, yyyy').format(date);
  }

  Widget _buildProfileHeader() {
    if (_fullProfile == null) return const SizedBox.shrink();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  backgroundImage: _fullProfile!['avatar'] != null &&
                          _fullProfile!['avatar'] !=
                              '/uploads/avatars/default-avatar.png'
                      ? (_fullProfile!['avatar'].toString().contains(
                              '/opt/render/project/src/rooster-backend/uploads/avatars/'))
                          ? NetworkImage(
                              '${ApiConfig.baseUrl.replaceAll('/api', '')}/uploads/avatars/${_fullProfile!['avatar'].toString().split('/').last}')
                          : (_fullProfile!['avatar']
                                      .toString()
                                      .startsWith('http') ||
                                  _fullProfile!['avatar']
                                      .toString()
                                      .contains('://'))
                              ? NetworkImage(_fullProfile!['avatar'])
                              : NetworkImage(
                                  '${ApiConfig.baseUrl.replaceAll('/api', '')}${_fullProfile!['avatar'].toString().startsWith('/') ? '' : '/'}${_fullProfile!['avatar']}')
                      : null,
                  child: _fullProfile!['avatar'] == null ||
                          _fullProfile!['avatar'] ==
                              '/uploads/avatars/default-avatar.png'
                      ? Text(
                          (_fullProfile!['firstName']?.isNotEmpty == true
                                  ? _fullProfile!['firstName'][0]
                                  : '?')
                              .toUpperCase(),
                          style: TextStyle(
                            fontSize: 20,
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_fullProfile!['firstName'] ?? ''} ${_fullProfile!['lastName'] ?? ''}'
                            .trim(),
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _fullProfile!['position'] ?? 'No Position',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      Text(
                        _fullProfile!['department'] ?? 'No Department',
                        style: Theme.of(context).textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            _fullProfile!['isProfileComplete'] == true
                                ? Icons.check_circle
                                : Icons.warning,
                            color: _fullProfile!['isProfileComplete'] == true
                                ? Colors.green
                                : Colors.orange,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              _fullProfile!['isProfileComplete'] == true
                                  ? 'Profile Complete'
                                  : 'Profile Incomplete',
                              style: TextStyle(
                                color:
                                    _fullProfile!['isProfileComplete'] == true
                                        ? Colors.green
                                        : Colors.orange,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final result = await showDialog<bool>(
                              context: context,
                              builder: (context) => EditEmployeeDialog(
                                employee: widget.employee,
                                employeeProvider: widget.employeeProvider,
                              ),
                            );
                            if (result == true) {
                              _fetchFullProfile();
                            }
                          },
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Edit'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _fullProfile!['isActive'] == true
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _fullProfile!['isActive'] == true
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                        child: Text(
                          _fullProfile!['isActive'] == true
                              ? 'Active'
                              : 'Inactive',
                          style: TextStyle(
                            color: _fullProfile!['isActive'] == true
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoTab() {
    if (_fullProfile == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoSection(
            title: 'Personal Information',
            icon: Icons.person,
            children: [
              _buildInfoRow('First Name', _fullProfile!['firstName']),
              _buildInfoRow('Last Name', _fullProfile!['lastName']),
              _buildInfoRow('Email', _fullProfile!['email']),
              _buildInfoRow('Phone', _fullProfile!['phone']),
              _buildInfoRow('Address', _fullProfile!['address']),
              _buildInfoRow('Department', _fullProfile!['department']),
              _buildInfoRow('Position', _fullProfile!['position']),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoSection(
            title: 'Emergency Contact',
            icon: Icons.emergency,
            children: [
              _buildInfoRow('Contact Name', _fullProfile!['emergencyContact']),
              _buildInfoRow('Phone', _fullProfile!['emergencyPhone']),
              _buildInfoRow(
                  'Relationship', _fullProfile!['emergencyRelationship']),
            ],
          ),
          const SizedBox(height: 16),
          Consumer<AdminSettingsProvider>(
            builder: (context, settings, _) {
              return Column(
                children: [
                  if (settings.educationSectionEnabled) ...[
                    _buildEducationSection(),
                    const SizedBox(height: 16),
                  ],
                  if (settings.certificatesSectionEnabled) ...[
                    _buildCertificatesSection(),
                    const SizedBox(height: 16),
                  ],
                ],
              );
            },
          ),
          _buildDocumentsSection(),
        ],
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? 'Not provided',
              style: Theme.of(context).textTheme.bodyMedium,
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEducationSection() {
    final education = _fullProfile!['education'] as List<dynamic>? ?? [];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.school,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Education',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const Divider(),
            if (education.isEmpty)
              Text(
                'No education information provided',
                style: TextStyle(color: Colors.grey[600]),
              )
            else
              ...education
                  .map((edu) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                edu['institution'] ?? 'Unknown Institution',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              Text(
                                '${edu['degree'] ?? 'Unknown Degree'} in ${edu['fieldOfStudy'] ?? 'Unknown Field'}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              if (edu['startDate'] != null ||
                                  edu['endDate'] != null)
                                Text(
                                  '${_formatDate(edu['startDate'])} - ${_formatDate(edu['endDate'])}',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                            ],
                          ),
                        ),
                      ))
                  .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificatesSection() {
    final certificates = _fullProfile!['certificates'] as List<dynamic>? ?? [];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.workspace_premium,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Certificates',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const Divider(),
            if (certificates.isEmpty)
              Text(
                'No certificates provided',
                style: TextStyle(color: Colors.grey[600]),
              )
            else
              ...certificates
                  .map((cert) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 1,
                        child: ListTile(
                          leading: const Icon(Icons.verified),
                          title: Text(cert['name'] ?? 'Unknown Certificate'),
                          trailing: cert['file'] != null
                              ? const Icon(Icons.attach_file)
                              : null,
                        ),
                      ))
                  .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsSection() {
    final documents = _fullProfile!['documents'] as List<dynamic>? ?? [];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.folder,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Documents',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const Divider(),
            if (documents.isEmpty)
              Text(
                'No documents uploaded',
                style: TextStyle(color: Colors.grey[600]),
              )
            else
              ...documents.map((doc) => _buildDocumentTile(doc)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentTile(Map<String, dynamic> doc) {
    final type = doc['type'] ?? 'Document';
    final path = doc['path'];
    final status = doc['status'] ?? 'pending';
    final verifiedBy = doc['verifiedBy'];
    final verifiedAt = doc['verifiedAt'];
    final docId = doc['_id'] ?? doc['id'];

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'verified':
        statusColor = Colors.green;
        statusLabel = 'Verified';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusLabel = 'Rejected';
        break;
      default:
        statusColor = Colors.orange;
        statusLabel = 'Pending';
    }

    final isPending = status == 'pending';
    final isAdmin =
        Provider.of<AuthProvider>(context, listen: false).user?['role'] ==
            'admin';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(type,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                Wrap(
                  spacing: 4,
                  children: [
                    // View/Preview button
                    IconButton(
                      icon: const Icon(Icons.visibility),
                      tooltip: 'View',
                      onPressed: () {
                        final url = path.startsWith('http')
                            ? path
                            : '${ApiConfig.baseUrl.replaceAll('/api', '')}$path';
                        showDocumentDialog(context, url);
                      },
                    ),
                    // Download button
                    IconButton(
                      icon: const Icon(Icons.download),
                      tooltip: 'Download',
                      onPressed: () async {
                        final url = path.startsWith('http')
                            ? path
                            : '${ApiConfig.baseUrl.replaceAll('/api', '')}$path';
                        // For web: open in new tab (browser will handle download)
                        // For mobile/desktop: open externally
                        await launchUrl(Uri.parse(url),
                            mode: LaunchMode.externalApplication);
                      },
                    ),
                    if (isAdmin && isPending) ...[
                      IconButton(
                        icon:
                            const Icon(Icons.check_circle, color: Colors.green),
                        tooltip: 'Verify',
                        onPressed: () => _verifyDocument(docId, 'verified'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        tooltip: 'Reject',
                        onPressed: () => _verifyDocument(docId, 'rejected'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 2,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ),
                if (status != 'pending' && verifiedAt != null)
                  Text(
                    'on ${_formatDateTime(verifiedAt)}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                if (status != 'pending' && verifiedBy != null)
                  Text(
                    'By: $verifiedBy',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _verifyDocument(String docId, String status) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = widget.employee['userId'] ?? widget.employee['_id'];
    final url =
        '${ApiConfig.baseUrl}/employees/users/$userId/documents/$docId/verify';
    try {
      final response = await http.patch(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}',
        },
        body: json.encode({'status': status}),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Document $status successfully.')),
        );
        _fetchFullProfile();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update document status.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Widget _buildAttendanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (_isAttendanceLoading)
            const Center(child: CircularProgressIndicator()),
          if (!_isAttendanceLoading && _attendanceRecords.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.schedule,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No attendance records found',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This employee hasn\'t clocked in yet',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          if (_attendanceRecords.isNotEmpty)
            ..._attendanceRecords.map((record) {
              return _buildAttendanceCard(record);
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildStatisticsTab() {
    // Calculate comprehensive statistics
    final totalDays = _attendanceRecords.length;
    final presentDays =
        _attendanceRecords.where((r) => r['status'] == 'present').length;
    final lateDays =
        _attendanceRecords.where((r) => r['status'] == 'late').length;
    final absentDays =
        _attendanceRecords.where((r) => r['status'] == 'absent').length;

    // Calculate total hours worked
    double totalHoursWorked = 0;
    int completedDays = 0;

    for (final record in _attendanceRecords) {
      if (record['checkInTime'] != null && record['checkOutTime'] != null) {
        final checkIn = DateTime.parse(record['checkInTime']);
        final checkOut = DateTime.parse(record['checkOutTime']);
        final workDuration = checkOut.difference(checkIn).inMilliseconds;
        final breakDuration = record['totalBreakDuration'] ?? 0;
        final netWorkMs = workDuration - breakDuration;

        if (netWorkMs > 0) {
          totalHoursWorked += netWorkMs / (1000 * 60 * 60);
          completedDays++;
        }
      }
    }

    final averageHoursPerDay =
        completedDays > 0 ? totalHoursWorked / completedDays : 0;

    // Calculate days since joining (if hire date is available)
    final hireDateStr = widget.employee['hireDate'];
    int? daysSinceJoining;
    if (hireDateStr != null) {
      final hireDate = DateTime.parse(hireDateStr);
      daysSinceJoining = DateTime.now().difference(hireDate).inDays;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Attendance Overview Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.calendar_today,
                  title: 'Total Days',
                  value: '$totalDays',
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.check_circle,
                  title: 'Present',
                  value: '$presentDays',
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.schedule,
                  title: 'Late',
                  value: '$lateDays',
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.cancel,
                  title: 'Absent',
                  value: '$absentDays',
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Hours Statistics
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Work Hours Statistics',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const Divider(),
                  _buildInfoRow('Total Hours Worked',
                      '${totalHoursWorked.toStringAsFixed(1)} hrs'),
                  _buildInfoRow('Average Hours/Day',
                      '${averageHoursPerDay.toStringAsFixed(1)} hrs'),
                  _buildInfoRow('Days with Complete Records', '$completedDays'),
                  if (totalDays > 0)
                    _buildInfoRow('Attendance Rate',
                        '${((presentDays + lateDays) / totalDays * 100).toStringAsFixed(1)}%'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Account Information
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.account_circle,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Account Information',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const Divider(),
                  _buildInfoRow('User ID', _fullProfile?['_id']),
                  _buildInfoRow('Employee ID', widget.employee['employeeId']),
                  _buildInfoRow(
                      'Hire Date', _formatDate(widget.employee['hireDate'])),
                  if (daysSinceJoining != null)
                    _buildInfoRow(
                        'Days Since Joining', '$daysSinceJoining days'),
                  _buildInfoRow('Account Created',
                      _formatDate(_fullProfile?['createdAt'])),
                  _buildInfoRow(
                      'Last Updated', _formatDate(_fullProfile?['updatedAt'])),
                  _buildInfoRow('Last Login',
                      _formatDateTime(_fullProfile?['lastLogin'])),
                  _buildInfoRow('Role', _fullProfile?['role'] ?? 'N/A'),
                  _buildInfoRow(
                      'Status',
                      _fullProfile?['isActive'] == true
                          ? 'Active'
                          : 'Inactive'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceCard(Map<String, dynamic> record) {
    final date = record['date'] != null ? DateTime.parse(record['date']) : null;
    final dayOfWeek = date?.weekday ?? 0;
    final dayName = date != null ? DateFormat('EEEE').format(date) : 'Unknown';
    final formattedDate =
        date != null ? DateFormat('MMM dd, yyyy').format(date) : 'N/A';

    // Get colors based on day of the week
    final dayColors = _getDayColors(dayOfWeek);
    final statusColor = _getStatusColor(record['status']);

    // Calculate work duration if both check-in and check-out exist
    String workDuration = 'N/A';
    if (record['checkInTime'] != null && record['checkOutTime'] != null) {
      final checkIn = DateTime.parse(record['checkInTime']);
      final checkOut = DateTime.parse(record['checkOutTime']);
      final duration = checkOut.difference(checkIn);
      final breakTime = record['totalBreakDuration'] ?? 0;
      final netWork = duration.inMilliseconds - breakTime;

      if (netWork > 0) {
        final hours = (netWork / (1000 * 60 * 60)).floor();
        final minutes = ((netWork % (1000 * 60 * 60)) / (1000 * 60)).floor();
        workDuration = '${hours}h ${minutes}m';
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: dayColors['border']!, width: 1),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              dayColors['primary']!.withValues(alpha: 0.1),
              dayColors['primary']!.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with day and date
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: dayColors['primary'],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getDayIcon(dayOfWeek),
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          dayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor, width: 1),
                    ),
                    child: Text(
                      (record['status'] ?? 'N/A').toString().toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Date
              Text(
                formattedDate,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: dayColors['primary'],
                    ),
              ),
              const SizedBox(height: 12),

              // Time info in a row
              Row(
                children: [
                  Expanded(
                    child: _buildTimeInfo(
                      icon: Icons.login,
                      label: 'Check-in',
                      time: _formatTime(record['checkInTime']),
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTimeInfo(
                      icon: Icons.logout,
                      label: 'Check-out',
                      time: _formatTime(record['checkOutTime']),
                      color: Colors.red,
                    ),
                  ),
                ],
              ),

              if (workDuration != 'N/A') ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: dayColors['primary']!.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.timer, size: 16, color: dayColors['primary']),
                      const SizedBox(width: 6),
                      Text(
                        'Work Duration: $workDuration',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: dayColors['primary'],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Breaks section
              if (record['breaks'] != null &&
                  (record['breaks'] as List).isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(),
                Row(
                  children: [
                    const Icon(Icons.coffee, size: 16, color: Colors.brown),
                    const SizedBox(width: 6),
                    Text(
                      'Breaks',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.brown,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...((record['breaks'] as List).map((breakRecord) {
                  final startTime = _formatTime(breakRecord['start']);
                  final endTime = breakRecord['end'] != null
                      ? _formatTime(breakRecord['end'])
                      : 'Ongoing';
                  final duration = breakRecord['duration'] != null
                      ? "${(breakRecord['duration'] / (1000 * 60)).round()} min"
                      : 'N/A';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.brown.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '• $startTime - $endTime',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const Spacer(),
                        Text(
                          duration,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.brown,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList()),
                if (record['totalBreakDuration'] != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.brown.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'Total Break Time:',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        Text(
                          _formatDuration(
                              (record['totalBreakDuration'] / (1000 * 60))
                                  .round()),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.brown,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeInfo({
    required IconData icon,
    required String label,
    required String time,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String? timeString) {
    if (timeString == null) return 'N/A';
    final dateTime = DateTime.tryParse(timeString)?.toLocal();
    if (dateTime == null) return 'N/A';
    return DateFormat('HH:mm').format(dateTime);
  }

  Map<String, Color> _getDayColors(int dayOfWeek) {
    switch (dayOfWeek) {
      case 1: // Monday
        return {
          'primary': const Color(0xFF1976D2),
          'border': const Color(0xFF1976D2).withValues(alpha: 0.3),
        };
      case 2: // Tuesday
        return {
          'primary': const Color(0xFF388E3C),
          'border': const Color(0xFF388E3C).withValues(alpha: 0.3),
        };
      case 3: // Wednesday
        return {
          'primary': const Color(0xFFE64A19),
          'border': const Color(0xFFE64A19).withValues(alpha: 0.3),
        };
      case 4: // Thursday
        return {
          'primary': const Color(0xFF7B1FA2),
          'border': const Color(0xFF7B1FA2).withValues(alpha: 0.3),
        };
      case 5: // Friday
        return {
          'primary': const Color(0xFFF57C00),
          'border': const Color(0xFFF57C00).withValues(alpha: 0.3),
        };
      case 6: // Saturday
        return {
          'primary': const Color(0xFF5D4037),
          'border': const Color(0xFF5D4037).withValues(alpha: 0.3),
        };
      case 7: // Sunday
        return {
          'primary': const Color(0xFFD32F2F),
          'border': const Color(0xFFD32F2F).withValues(alpha: 0.3),
        };
      default:
        return {
          'primary': Colors.grey,
          'border': Colors.grey.withValues(alpha: 0.3),
        };
    }
  }

  IconData _getDayIcon(int dayOfWeek) {
    switch (dayOfWeek) {
      case 1:
        return Icons.work; // Monday
      case 2:
        return Icons.trending_up; // Tuesday
      case 3:
        return Icons.flash_on; // Wednesday
      case 4:
        return Icons.star; // Thursday
      case 5:
        return Icons.celebration; // Friday
      case 6:
        return Icons.weekend; // Saturday
      case 7:
        return Icons.home; // Sunday
      default:
        return Icons.calendar_today;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'present':
        return Colors.green;
      case 'late':
        return Colors.orange;
      case 'absent':
        return Colors.red;
      case 'working':
        return Colors.blue;
      case 'on break':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.employee['name'] ?? 'Employee Profile'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.onPrimary,
          unselectedLabelColor:
              Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7),
          indicatorColor: Theme.of(context).colorScheme.onPrimary,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'Profile'),
            Tab(icon: Icon(Icons.access_time), text: 'Attendance'),
            Tab(icon: Icon(Icons.analytics), text: 'Statistics'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchFullProfile,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    _buildProfileHeader(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildPersonalInfoTab(),
                          _buildAttendanceTab(),
                          _buildStatisticsTab(),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
