import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sns_rooster/providers/auth_provider.dart';
import 'package:sns_rooster/widgets/admin_side_navigation.dart';
import 'package:sns_rooster/widgets/company_details_widget.dart';
import 'package:sns_rooster/widgets/company_usage_widget.dart';
import 'package:sns_rooster/widgets/modern_card_widget.dart';
import 'edit_company_form_screen.dart';
import 'package:sns_rooster/providers/company_settings_provider.dart';

class CompanySettingsScreen extends StatefulWidget {
  const CompanySettingsScreen({Key? key}) : super(key: key);

  @override
  State<CompanySettingsScreen> createState() => _CompanySettingsScreenState();
}

class _CompanySettingsScreenState extends State<CompanySettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Company Settings'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
      ),
      drawer: const AdminSideNavigation(currentRoute: '/company-settings'),
      body: Row(
        children: [
          // Side Navigation (Desktop)
          if (MediaQuery.of(context).size.width > 768)
            const SizedBox(
              width: 250,
              child: AdminSideNavigation(currentRoute: '/company-settings'),
            ),
          // Main Content
          Expanded(
            child: Column(
              children: [
                // Tab Bar
                Container(
                  color: colorScheme.surface,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: colorScheme.primary,
                    unselectedLabelColor:
                        colorScheme.onSurface.withValues(alpha: 0.7),
                    indicatorColor: colorScheme.primary,
                    tabs: const [
                      Tab(text: 'Company Info'),
                      Tab(text: 'Subscription'),
                      Tab(text: 'Configuration'),
                    ],
                  ),
                ),
                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCompanyInfoTab(theme, colorScheme),
                      _buildSubscriptionTab(theme, colorScheme),
                      _buildConfigurationTab(theme, colorScheme),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyInfoTab(ThemeData theme, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Company Information',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage your company details, contact information, and branding.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),

          // Company Details Widget
          const CompanyDetailsWidget(),

          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditCompanyFormScreen(),
                    ),
                  );

                  // Refresh data if changes were made
                  if (result == true) {
                    // Trigger refresh of company settings
                    final companySettingsProvider =
                        Provider.of<CompanySettingsProvider>(context,
                            listen: false);
                    await companySettingsProvider.load();
                  }
                },
                icon: const Icon(Icons.edit),
                label: const Text('Edit Company Details'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionTab(ThemeData theme, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Subscription & Billing',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'View your current plan, usage statistics, and available features.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),

          // Company Usage Widget (Status, Usage, Features)
          const CompanyUsageWidget(),

          // Force Refresh Button
          Center(
            child: ElevatedButton.icon(
              onPressed: () async {
                // Force refresh the FeatureProvider
                final authProvider =
                    Provider.of<AuthProvider>(context, listen: false);
                if (authProvider.featureProvider != null) {
                  await authProvider.featureProvider!.forceRefreshFeatures();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Usage data refreshed'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh Usage Data'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.secondary,
                foregroundColor: colorScheme.onSecondary,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Billing Information Card
          SettingsCard(
            icon: Icons.payment,
            title: 'Billing Information',
            description:
                'Manage your billing details, payment methods, and subscription settings.',
            actionText: 'Billing Settings',
            onAction: () {
              // TODO: Navigate to billing settings
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Billing settings coming soon...'),
                ),
              );
            },
            accentColor: colorScheme.primary,
          ),

          const SizedBox(height: 16),

          SettingsCard(
            icon: Icons.upgrade,
            title: 'Plan Management',
            description:
                'Upgrade, downgrade, or change your subscription plan.',
            actionText: 'Change Plan',
            onAction: () {
              // TODO: Navigate to plan upgrade/downgrade
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Plan management coming soon...'),
                ),
              );
            },
            accentColor: colorScheme.secondary,
          ),
        ],
      ),
    );
  }

  Widget _buildConfigurationTab(ThemeData theme, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Company Configuration',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Configure company settings, preferences, and system options.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),

          // Settings Cards
          SettingsCard(
            icon: Icons.work,
            title: 'Work Settings',
            description:
                'Configure working hours, holidays, and attendance policies.',
            actionText: 'Configure',
            onAction: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Work settings coming soon...'),
                ),
              );
            },
            accentColor: colorScheme.primary,
          ),

          const SizedBox(height: 16),

          SettingsCard(
            icon: Icons.notifications,
            title: 'Notification Settings',
            description:
                'Manage email notifications, alerts, and communication preferences.',
            actionText: 'Configure',
            onAction: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notification settings coming soon...'),
                ),
              );
            },
            accentColor: colorScheme.secondary,
          ),

          const SizedBox(height: 16),

          SettingsCard(
            icon: Icons.security,
            title: 'Security Settings',
            description:
                'Configure security policies, password requirements, and access controls.',
            actionText: 'Configure',
            onAction: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Security settings coming soon...'),
                ),
              );
            },
            accentColor: colorScheme.tertiary,
          ),

          const SizedBox(height: 16),

          SettingsCard(
            icon: Icons.integration_instructions,
            title: 'Integrations',
            description:
                'Connect with third-party services and manage API integrations.',
            actionText: 'Manage',
            onAction: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Integrations coming soon...'),
                ),
              );
            },
            accentColor: colorScheme.error,
          ),
        ],
      ),
    );
  }
}
