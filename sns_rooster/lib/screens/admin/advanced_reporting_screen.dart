import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/feature_provider.dart';
import '../../widgets/admin_side_navigation.dart';
import '../../widgets/feature_lock_widget.dart';
import 'package:intl/intl.dart';

class AdvancedReportingScreen extends StatefulWidget {
  const AdvancedReportingScreen({Key? key}) : super(key: key);

  @override
  State<AdvancedReportingScreen> createState() =>
      _AdvancedReportingScreenState();
}

class _AdvancedReportingScreenState extends State<AdvancedReportingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedReportType = 'attendance';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _selectedFormat = 'pdf';
  bool _isGenerating = false;

  final List<String> _reportTypes = [
    'attendance',
    'payroll',
    'leave',
    'performance',
    'custom'
  ];

  final List<String> _exportFormats = ['pdf', 'excel', 'csv', 'json'];

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
    return Consumer<FeatureProvider>(
      builder: (context, featureProvider, _) {
        // Check if advanced reporting is enabled
        if (!featureProvider.isFeatureEnabled('advancedReporting')) {
          return Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: true,
              title: const Text('Advanced Reporting'),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
            ),
            drawer:
                const AdminSideNavigation(currentRoute: '/advanced-reporting'),
            body: const FeatureLockWidget(
              featureName:
                  'advancedReporting', // Fix: Use correct parameter name
              title: 'Advanced Reporting',
              description:
                  'Create custom reports with advanced analytics, scheduled reports, and multiple export formats.',
              icon: Icons.assessment, // Fix: Add required icon parameter
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: true,
            title: const Text('Advanced Reporting'),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
            bottom: TabBar(
              controller: _tabController,
              labelColor: Colors.blue.shade600,
              unselectedLabelColor: Colors.grey.shade600,
              indicatorColor: Colors.blue.shade600,
              tabs: const [
                Tab(text: 'Report Builder'),
                Tab(text: 'Scheduled Reports'),
                Tab(text: 'Report History'),
              ],
            ),
          ),
          drawer:
              const AdminSideNavigation(currentRoute: '/advanced-reporting'),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildReportBuilder(),
              _buildScheduledReports(),
              _buildReportHistory(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReportBuilder() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create Custom Report',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Report Type Selection
                  DropdownButtonFormField<String>(
                    value: _selectedReportType,
                    decoration: const InputDecoration(
                      labelText: 'Report Type',
                      border: OutlineInputBorder(),
                    ),
                    items: _reportTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedReportType = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Date Range Selection
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(true),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Start Date',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              DateFormat('MMM dd, yyyy').format(_startDate),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(false),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'End Date',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              DateFormat('MMM dd, yyyy').format(_endDate),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Export Format Selection
                  DropdownButtonFormField<String>(
                    value: _selectedFormat,
                    decoration: const InputDecoration(
                      labelText: 'Export Format',
                      border: OutlineInputBorder(),
                    ),
                    items: _exportFormats.map((format) {
                      return DropdownMenuItem(
                        value: format,
                        child: Text(format.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedFormat = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // Generate Report Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isGenerating ? null : _generateReport,
                      icon: _isGenerating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.file_download),
                      label: Text(
                          _isGenerating ? 'Generating...' : 'Generate Report'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduledReports() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.schedule,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Scheduled Reports',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Set up automated reports that are generated and sent on a schedule.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportHistory() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Report History',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'View and download previously generated reports.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _generateReport() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      // Simulate report generation
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Report generated successfully in $_selectedFormat format'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }
}
