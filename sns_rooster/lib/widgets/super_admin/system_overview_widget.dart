import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/super_admin_provider.dart';

class SystemOverviewWidget extends StatelessWidget {
  const SystemOverviewWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SuperAdminProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingOverview) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        if (provider.overviewError != null) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red[400],
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Error loading system overview',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    provider.overviewError!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
          );
        }

        final overview = provider.systemOverview?['overview'];
        if (overview == null) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Center(
                child: Text('No system overview data available'),
              ),
            ),
          );
        }

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.analytics,
                      color: Colors.indigo[800],
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'System Overview',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo[800],
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.5,
                  children: [
                    _buildStatCard(
                      context,
                      'Total Companies',
                      overview['totalCompanies']?.toString() ?? '0',
                      Icons.business,
                      Colors.blue,
                    ),
                    _buildStatCard(
                      context,
                      'Active Companies',
                      overview['activeCompanies']?.toString() ?? '0',
                      Icons.check_circle,
                      Colors.green,
                    ),
                    _buildStatCard(
                      context,
                      'Total Users',
                      overview['totalUsers']?.toString() ?? '0',
                      Icons.people,
                      Colors.orange,
                    ),
                    _buildStatCard(
                      context,
                      'Total Employees',
                      overview['totalEmployees']?.toString() ?? '0',
                      Icons.person,
                      Colors.purple,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
