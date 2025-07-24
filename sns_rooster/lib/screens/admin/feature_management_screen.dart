import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart'; // Add this import
import '../../providers/feature_provider.dart';
import '../../widgets/feature_lock_widget.dart';
import '../../widgets/admin_side_navigation.dart'; // Make sure this is here
import '../../config/api_config.dart'; // Add this import

class FeatureManagementScreen extends StatefulWidget {
  const FeatureManagementScreen({Key? key}) : super(key: key);

  @override
  State<FeatureManagementScreen> createState() =>
      _FeatureManagementScreenState();
}

class _FeatureManagementScreenState extends State<FeatureManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadFeatures();
  }

  Future<void> _loadFeatures() async {
    final featureProvider =
        Provider.of<FeatureProvider>(context, listen: false);

    await featureProvider.loadFeatures();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading:
            true, // This will show hamburger menu when drawer is present
        title: const Text('Feature Management'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              final featureProvider =
                  Provider.of<FeatureProvider>(context, listen: false);
              await featureProvider.forceRefreshFeatures();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Features refreshed successfully'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            tooltip: 'Refresh Features',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue.shade600,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: Colors.blue.shade600,
          tabs: const [
            Tab(text: 'Features', icon: Icon(Icons.featured_play_list)),
            Tab(text: 'Usage', icon: Icon(Icons.analytics)),
            Tab(text: 'Plans', icon: Icon(Icons.card_membership)),
          ],
        ),
      ),
      drawer: AdminSideNavigation(
        currentRoute:
            ModalRoute.of(context)?.settings.name ?? '/feature-management',
      ),
      body: Consumer<FeatureProvider>(
        builder: (context, featureProvider, _) {
          if (featureProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (featureProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading features',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    featureProvider.error!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => featureProvider.refreshFeatures(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildFeaturesTab(featureProvider),
              _buildUsageTab(featureProvider),
              _buildPlansTab(featureProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFeaturesTab(FeatureProvider featureProvider) {
    // Define feature metadata (this stays the same)
    final featureMetadata = [
      {
        'key': 'attendance',
        'title': 'Attendance Tracking',
        'description': 'Track employee attendance, check-ins, and check-outs',
        'icon': Icons.access_time,
        'availablePlans': ['Basic', 'Advance', 'Professional', 'Enterprise'],
      },
      {
        'key': 'payroll',
        'title': 'Payroll Management',
        'description': 'Calculate and manage employee payroll',
        'icon': Icons.account_balance_wallet,
        'availablePlans': ['Basic', 'Advance', 'Professional', 'Enterprise'],
      },
      {
        'key': 'leaveManagement',
        'title': 'Leave Management',
        'description': 'Manage employee leave requests and approvals',
        'icon': Icons.event_note,
        'availablePlans': ['Basic', 'Advance', 'Professional', 'Enterprise'],
      },
      {
        'key': 'analytics',
        'title': 'Analytics Dashboard',
        'description': 'Advanced analytics and reporting features',
        'icon': Icons.analytics,
        'availablePlans': ['Advance', 'Professional', 'Enterprise'],
      },
      {
        'key': 'advancedReporting',
        'title': 'Advanced Reporting',
        'description': 'Custom reports and advanced data analysis',
        'icon': Icons.assessment,
        'availablePlans': ['Professional', 'Enterprise'],
      },
      {
        'key': 'customBranding',
        'title': 'Custom Branding',
        'description': 'Customize app appearance with your brand',
        'icon': Icons.palette,
        'availablePlans': ['Professional', 'Enterprise'],
      },
      {
        'key': 'apiAccess',
        'title': 'API Access',
        'description': 'Access to REST API for integrations',
        'icon': Icons.api,
        'availablePlans': ['Enterprise'],
      },
      {
        'key': 'multiLocation',
        'title': 'Multi-Location Support',
        'description': 'Manage multiple office locations',
        'icon': Icons.location_on,
        'availablePlans': ['Enterprise'],
      },
      {
        'key': 'expenseManagement',
        'title': 'Expense Management',
        'description': 'Track and manage employee expenses',
        'icon': Icons.receipt,
        'availablePlans': ['Professional', 'Enterprise'],
      },
      {
        'key': 'performanceReviews',
        'title': 'Performance Reviews',
        'description': 'Conduct employee performance evaluations',
        'icon': Icons.star_rate,
        'availablePlans': ['Enterprise'],
      },
      {
        'key': 'trainingManagement',
        'title': 'Training Management',
        'description': 'Manage employee training programs',
        'icon': Icons.school,
        'availablePlans': ['Enterprise'],
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: featureMetadata.length,
      itemBuilder: (context, index) {
        final feature = featureMetadata[index];
        // Use real backend data instead of mock data
        final isEnabled =
            featureProvider.isFeatureEnabled(feature['key'] as String);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isEnabled ? Colors.green.shade100 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                feature['icon'] as IconData,
                color: isEnabled ? Colors.green.shade600 : Colors.grey.shade600,
              ),
            ),
            title: Text(
              feature['title'] as String,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isEnabled ? Colors.black : Colors.grey.shade700,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature['description'] as String,
                  style: TextStyle(
                    color:
                        isEnabled ? Colors.grey.shade600 : Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isEnabled
                      ? '✅ Available in your plan'
                      : 'Available in: ${(feature['availablePlans'] as List<String>).join(', ')}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isEnabled
                        ? Colors.green.shade600
                        : Colors.orange.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            trailing: isEnabled
                ? Icon(Icons.check_circle, color: Colors.green.shade600)
                : IconButton(
                    icon: Icon(Icons.lock_outline, color: Colors.grey.shade400),
                    onPressed: () => _showFeatureLockDialog(context, feature),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildUsageTab(FeatureProvider featureProvider) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Current Plan Info
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.card_membership, color: Colors.blue.shade600),
                    const SizedBox(width: 8),
                    const Text(
                      'Current Plan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  featureProvider.subscriptionPlanName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                if (featureProvider.subscriptionPlanPrice != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '\$${featureProvider.subscriptionPlanPrice!['monthly']}/month',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Usage Limits
        const Text(
          'Usage Limits',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        _buildUsageLimitWidget(
          limitKey: 'maxEmployees',
          title: 'Employees',
          icon: Icons.people,
          unit: 'employees',
          featureProvider: featureProvider,
        ),

        _buildUsageLimitWidget(
          limitKey: 'maxStorageGB',
          title: 'Storage',
          icon: Icons.storage,
          unit: 'GB',
          featureProvider: featureProvider,
        ),

        _buildUsageLimitWidget(
          limitKey: 'maxApiCallsPerDay',
          title: 'API Calls',
          icon: Icons.api,
          unit: 'calls/day',
          featureProvider: featureProvider,
        ),

        // Warnings
        if (featureProvider.usageWarnings.isNotEmpty) ...[
          const SizedBox(height: 16),
          Card(
            color: Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange.shade600),
                      const SizedBox(width: 8),
                      const Text(
                        'Usage Warnings',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...featureProvider.usageWarnings.map((warning) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• You are approaching your $warning limit',
                          style: TextStyle(color: Colors.orange.shade700),
                        ),
                      )),
                ],
              ),
            ),
          ),
        ],

        // Exceeded Limits
        if (featureProvider.exceededLimits.isNotEmpty) ...[
          const SizedBox(height: 16),
          Card(
            color: Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.error, color: Colors.red.shade600),
                      const SizedBox(width: 8),
                      const Text(
                        'Limit Exceeded',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...featureProvider.exceededLimits.map((limit) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• You have exceeded your $limit limit',
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      )),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _showUpgradeDialog(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Upgrade Plan'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildUsageLimitWidget({
    required String limitKey,
    required String title,
    required IconData icon,
    required String unit,
    required FeatureProvider featureProvider,
  }) {
    final currentUsage = featureProvider.getCurrentUsage(limitKey);
    final limit = featureProvider.getLimit(limitKey);
    final percentage = featureProvider.getUsagePercentage(limitKey);
    final isExceeded = !featureProvider.isWithinLimit(limitKey);
    final isWarning = percentage > 80 && !isExceeded;

    if (limit == 0) return const SizedBox.shrink(); // Unlimited

    Color getColor() {
      if (isExceeded) return Colors.red;
      if (isWarning) return Colors.orange;
      return Colors.green;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: getColor()),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                if (isExceeded)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Limit Exceeded',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Progress bar
            LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(getColor()),
            ),

            const SizedBox(height: 8),

            // Usage text
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$currentUsage / $limit $unit',
                  style: TextStyle(
                    color: getColor(),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '$percentage%',
                  style: TextStyle(
                    color: getColor(),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            if (isExceeded || isWarning) ...[
              const SizedBox(height: 8),
              Text(
                isExceeded
                    ? 'You have exceeded your limit. Please upgrade your plan.'
                    : 'You are approaching your limit. Consider upgrading.',
                style: TextStyle(
                  color: getColor(),
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlansTab(FeatureProvider featureProvider) {
    final plans = [
      {
        'name': 'Basic',
        'price': '\$29/month',
        'features': [
          'Attendance Tracking',
          'Payroll Management',
          'Leave Management',
          'Document Management',
          'Notifications'
        ],
        'color': Colors.grey,
      },
      {
        'name': 'Advance',
        'price': '\$50/month',
        'features': ['All Basic features', 'Analytics', 'Custom Branding'],
        'color': Colors.blue,
      },
      {
        'name': 'Professional',
        'price': '\$79/month',
        'features': [
          'All Advance features',
          'Advanced Reporting',
          'Multi-Location'
        ],
        'color': Colors.purple,
      },
      {
        'name': 'Enterprise',
        'price': '\$199/month',
        'features': [
          'All Professional features',
          'API Access',
          'Priority Support'
        ],
        'color': Colors.orange,
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: plans.length,
      itemBuilder: (context, index) {
        final plan = plans[index];
        final isCurrentPlan = plan['name'].toString().toLowerCase() ==
            featureProvider.subscriptionPlanName.toLowerCase();

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Container(
            decoration: BoxDecoration(
              border: isCurrentPlan
                  ? Border.all(color: Colors.blue.shade600, width: 2)
                  : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plan['name'] as String,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              plan['price'] as String,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isCurrentPlan)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade600,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Current Plan',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...(plan['features'] as List<String>)
                      .map((feature) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Icon(Icons.check,
                                    color: Colors.green, size: 16),
                                const SizedBox(width: 8),
                                Expanded(child: Text(feature)),
                              ],
                            ),
                          )),
                  if (!isCurrentPlan) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _showUpgradeDialog(
                            context), // Fix: Remove second parameter
                        style: ElevatedButton.styleFrom(
                          backgroundColor: plan['color'] as Color,
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Upgrade to ${plan['name']}'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showFeatureLockDialog(
      BuildContext context, Map<String, dynamic> feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lock_outline, color: Colors.orange.shade600),
            const SizedBox(width: 8),
            Text(feature['title'] as String),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(feature['description'] as String),
            const SizedBox(height: 16),
            Text(
              'Available in: ${(feature['availablePlans'] as List<String>).join(', ')}',
              style: TextStyle(
                color: Colors.orange.shade600,
                fontWeight: FontWeight.w500,
              ),
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
              Navigator.of(context).pop();
              _showUpgradeDialog(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Upgrade Plan'),
          ),
        ],
      ),
    );
  }

  void _contactSuperAdmin(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.admin_panel_settings, color: Colors.blue.shade600),
            const SizedBox(width: 8),
            const Expanded(
              // Add this to prevent overflow
              child: Text('Contact Super Administrator'),
            ),
          ],
        ),
        content: SingleChildScrollView(
          // Add this to handle overflow
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  'Please contact the Super Administrator to upgrade your subscription plan:'),
              const SizedBox(height: 16),
              _buildContactInfo(
                  'Email', 'superadmin@snstechservices.com.au', Icons.email),
              const SizedBox(height: 8),
              _buildContactInfo('Phone', '+61 123 456 789', Icons.phone),
              const SizedBox(height: 8),
              _buildContactInfo('Company', 'SNS Tech Services', Icons.business),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Text(
                  'Please copy the email address and send your upgrade request with your company details.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start, // Add this
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        Expanded(
          // Make sure this is here
          child: SelectableText(
            value,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard(Map<String, dynamic> feature, bool isEnabled,
      FeatureProvider featureProvider) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  feature['icon'] as IconData,
                  color: isEnabled ? Colors.green : Colors.grey,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    feature['title'] as String,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isEnabled)
                  const Icon(Icons.check_circle, color: Colors.green)
                else
                  const Icon(Icons.lock, color: Colors.orange),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              feature['description'] as String,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            if (!isEnabled) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Current Plan: ${featureProvider.subscriptionPlanName}',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showUpgradeDialog(
                      context), // Fix: Remove second parameter
                  icon: const Icon(Icons.arrow_upward),
                  label: const Text('Upgrade Plan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUsageCard(String title, String current, String limit,
      String percentage, IconData icon) {
    // Fix: Parse percentage correctly
    final percentageValue =
        int.tryParse(percentage.replaceAll('%', ''))?.toDouble() ?? 0.0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue.shade600, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$current / $limit ($percentage%)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            LinearProgressIndicator(
              value: percentageValue / 100, // Fix: Use parsed value
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                percentageValue > 80
                    ? Colors.orange
                    : Colors.green, // Fix: Use parsed value
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Fix: Add context parameter to _showUpgradeDialog
  void _showUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.upgrade, color: Colors.orange.shade600),
            const SizedBox(width: 8),
            const Text('Upgrade Required'),
          ],
        ),
        content: const Text(
          'To access this feature, please contact the Super Administrator to upgrade your subscription plan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _contactSuperAdmin(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Contact Super Admin'),
          ),
        ],
      ),
    );
  }
}
