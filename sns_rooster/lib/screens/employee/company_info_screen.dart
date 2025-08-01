import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/company_info_service.dart';
import '../../widgets/app_drawer.dart';

class CompanyInfoScreen extends StatefulWidget {
  const CompanyInfoScreen({super.key});

  @override
  State<CompanyInfoScreen> createState() => _CompanyInfoScreenState();
}

class _CompanyInfoScreenState extends State<CompanyInfoScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _companyInfo;
  Map<String, dynamic>? _usageInfo;
  Map<String, dynamic>? _subscriptionInfo;
  List<Map<String, dynamic>>? _companyUpdates;

  @override
  void initState() {
    super.initState();
    _loadCompanyInfo();
  }

  @override
  void dispose() {
    // Clean up any resources if needed
    super.dispose();
  }

  Future<void> _loadCompanyInfo() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final companyInfoService = CompanyInfoService(authProvider);

      // Load all company information in parallel
      final results = await Future.wait([
        companyInfoService.getCompanyInfo(),
        companyInfoService.getCompanyUsage(),
        companyInfoService.getSubscriptionInfo(),
        companyInfoService.getCompanyUpdates(),
      ]);

      if (!mounted) return;

      setState(() {
        _companyInfo = results[0] as Map<String, dynamic>;
        _usageInfo = results[1] as Map<String, dynamic>;
        _subscriptionInfo = results[2] as Map<String, dynamic>;
        _companyUpdates = results[3] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading company info: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Information'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCompanyInfo,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCompanyInfo,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Company Overview Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.business,
                                  color: Colors.blue,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Company Overview',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.refresh, size: 20),
                                  onPressed: _loadCompanyInfo,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildCompanyOverview(),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Workplace Information Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.work,
                                  color: Colors.green,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Workplace Information',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.refresh, size: 20),
                                  onPressed: _loadCompanyInfo,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildWorkplaceInfo(),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Available Tools Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.build,
                                  color: Colors.orange,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Available Tools',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.refresh, size: 20),
                                  onPressed: _loadCompanyInfo,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildAvailableTools(),
                          ],
                        ),
                      ),
                    ),

                    // Company Updates Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.announcement,
                                  color: Colors.purple,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Company Updates',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.refresh, size: 20),
                                  onPressed: _loadCompanyInfo,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildCompanyUpdates(),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCompanyOverview() {
    if (_companyInfo == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(height: 8),
              Text(
                'Loading company information...',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final info = _companyInfo!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Company Name
        if (info['name'] != null && info['name'].toString().isNotEmpty)
          _buildInfoRow('Company Name', info['name']),

        // Company Status
        if (info['status'] != null && info['status'].toString().isNotEmpty)
          _buildInfoRow(
              'Status',
              info['status'].toString().toUpperCase() == 'TRIAL' &&
                      info['trialPlanName'] != null
                  ? 'TRIAL - ${info['trialPlanName']}'
                  : info['status'].toString().toUpperCase()),

        // Employee Count
        if (_usageInfo != null)
          _buildInfoRow('Total Employees',
              '${_usageInfo!['employees']?['current'] ?? 0}'),

        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: info['status'] == 'trial'
                ? Colors.orange[50]
                : Colors.green[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: info['status'] == 'trial'
                    ? Colors.orange[200]!
                    : Colors.green[200]!),
          ),
          child: Row(
            children: [
              Icon(
                  info['status'] == 'trial'
                      ? Icons.access_time
                      : Icons.check_circle,
                  color: info['status'] == 'trial'
                      ? Colors.orange[600]
                      : Colors.green[600],
                  size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  info['status'] == 'trial'
                      ? 'Your company is in trial period. Enjoy full access to all features!'
                      : 'Your company is active and ready for work!',
                  style: TextStyle(
                    fontSize: 12,
                    color: info['status'] == 'trial'
                        ? Colors.orange[700]
                        : Colors.green[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWorkplaceInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWorkplaceRow(
          'Working Hours',
          '9:00 AM - 5:00 PM',
          Icons.access_time,
          Colors.blue,
        ),
        const SizedBox(height: 12),
        _buildWorkplaceRow(
          'Work Days',
          'Monday - Friday',
          Icons.calendar_today,
          Colors.green,
        ),
        const SizedBox(height: 12),
        _buildWorkplaceRow(
          'Break Time',
          '1 hour lunch break',
          Icons.restaurant,
          Colors.orange,
        ),
        const SizedBox(height: 12),
        _buildWorkplaceRow(
          'Location Tracking',
          'Enabled for attendance',
          Icons.location_on,
          Colors.red,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Contact your manager for specific workplace policies and procedures.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvailableTools() {
    if (_subscriptionInfo == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final features = _subscriptionInfo!['features'] ?? [];

    return Column(
      children: [
        _buildToolRow('Clock In/Out', 'Track your work hours',
            Icons.access_time, Colors.green),
        const SizedBox(height: 8),
        _buildToolRow('Leave Requests', 'Submit time-off requests',
            Icons.beach_access, Colors.blue),
        const SizedBox(height: 8),
        _buildToolRow('Payroll Access', 'View your payslips',
            Icons.account_balance_wallet, Colors.orange),
        const SizedBox(height: 8),
        _buildToolRow('Document Center', 'Access company documents',
            Icons.folder, Colors.purple),
        const SizedBox(height: 8),
        _buildToolRow('Notifications', 'Stay updated with alerts',
            Icons.notifications, Colors.red),
        if (features.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Text(
            'Additional Features:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          ...features.take(5).map((feature) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkplaceRow(
      String title, String subtitle, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToolRow(
      String title, String subtitle, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
      ],
    );
  }

  IconData _getUpdateIcon(String type) {
    switch (type) {
      case 'maintenance':
        return Icons.build;
      case 'feature':
        return Icons.new_releases;
      case 'holiday':
        return Icons.event;
      case 'announcement':
        return Icons.announcement;
      case 'urgent':
        return Icons.warning;
      default:
        return Icons.info;
    }
  }

  Color _getUpdateColor(String type) {
    switch (type) {
      case 'maintenance':
        return Colors.orange;
      case 'feature':
        return Colors.green;
      case 'holiday':
        return Colors.red;
      case 'announcement':
        return Colors.blue;
      case 'urgent':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getTimeAgo(String createdAt) {
    try {
      final date = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Recently';
    }
  }

  Widget _buildCompanyUpdates() {
    if (_companyUpdates == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_companyUpdates!.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.notifications_none, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No updates available',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for company announcements',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        ..._companyUpdates!.map((update) {
          final icon = _getUpdateIcon(update['type']);
          final color = _getUpdateColor(update['type']);
          final timeAgo = _getTimeAgo(update['createdAt']);

          return Column(
            children: [
              _buildUpdateItem(
                update['title'] ?? 'Update',
                update['message'] ?? '',
                icon,
                color,
                timeAgo,
              ),
              if (update != _companyUpdates!.last) const SizedBox(height: 12),
            ],
          );
        }),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Check the main dashboard for real-time updates and notifications.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUpdateItem(String title, String description, IconData icon,
      Color color, String time) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
