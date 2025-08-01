import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/feature_provider.dart';
import '../../models/performance_review.dart';
import '../../services/performance_review_service.dart';
import '../../services/api_service.dart';
import '../../widgets/admin_side_navigation.dart';

class PerformanceReviewsScreen extends StatefulWidget {
  const PerformanceReviewsScreen({super.key});

  @override
  State<PerformanceReviewsScreen> createState() =>
      _PerformanceReviewsScreenState();
}

class _PerformanceReviewsScreenState extends State<PerformanceReviewsScreen> {
  late PerformanceReviewService _performanceReviewService;
  List<PerformanceReview> _reviews = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';
  Map<String, dynamic> _statistics = {};

  @override
  void initState() {
    super.initState();
    _checkFeatureAccess();
    _initializeService();
    _loadData();
  }

  void _initializeService() {
    final apiService = ApiService(baseUrl: 'http://192.168.1.119:5000/api');
    _performanceReviewService = PerformanceReviewService(apiService);
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Load reviews and statistics in parallel
      final results = await Future.wait([
        _performanceReviewService.getPerformanceReviews(),
        _performanceReviewService.getPerformanceStatistics(),
      ]);

      if (mounted) {
        setState(() {
          _reviews = results[0] as List<PerformanceReview>;
          _statistics = results[1] as Map<String, dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading performance reviews: $e');

      // Show mock data as fallback for demonstration
      final mockReviews = [
        PerformanceReview(
          id: '1',
          employeeId: 'emp1',
          employeeName: 'John Doe',
          reviewerId: 'mgr1',
          reviewerName: 'Jane Manager',
          reviewPeriod: 'Q4 2024',
          startDate: DateTime(2024, 10, 1),
          endDate: DateTime(2024, 12, 31),
          status: 'in_progress',
          scores: {
            'communication': 4.0,
            'teamwork': 4.5,
            'technical': 4.2,
          },
          goals: ['Improve project delivery', 'Enhance technical skills'],
          achievements: ['Led successful project launch'],
          areasOfImprovement: ['Time management', 'Documentation'],
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          dueDate: DateTime.now().add(const Duration(days: 10)),
        ),
        PerformanceReview(
          id: '2',
          employeeId: 'emp2',
          employeeName: 'Alice Smith',
          reviewerId: 'mgr1',
          reviewerName: 'Jane Manager',
          reviewPeriod: 'Q4 2024',
          startDate: DateTime(2024, 10, 1),
          endDate: DateTime(2024, 12, 31),
          status: 'completed',
          scores: {
            'communication': 4.5,
            'teamwork': 4.8,
            'technical': 4.0,
          },
          goals: ['Mentor junior developers', 'Learn new technology'],
          achievements: ['Successfully mentored 2 junior developers'],
          areasOfImprovement: ['Presentation skills'],
          overallRating: 4.4,
          createdAt: DateTime.now().subtract(const Duration(days: 15)),
          completedAt: DateTime.now().subtract(const Duration(days: 2)),
          dueDate: DateTime.now().subtract(const Duration(days: 3)),
        ),
      ];

      final mockStatistics = {
        'total': 12,
        'completed': 8,
        'inProgress': 3,
        'overdue': 1,
        'averageRating': 4.2,
      };

      if (mounted) {
        setState(() {
          _reviews = mockReviews;
          _statistics = mockStatistics;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Using demo data - Backend connection failed: ${e.toString()}'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _checkFeatureAccess() {
    final featureProvider =
        Provider.of<FeatureProvider>(context, listen: false);
    if (!featureProvider.hasPerformanceReviews) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/admin/dashboard');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Performance Reviews feature is not available in your current plan'),
            backgroundColor: Colors.orange,
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Consumer<FeatureProvider>(
          builder: (context, featureProvider, child) {
            if (!featureProvider.hasPerformanceReviews) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            return Scaffold(
              appBar: AppBar(
                title: const Text('Performance Reviews'),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              drawer: const AdminSideNavigation(
                  currentRoute: '/performance_reviews'),
              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.assessment,
                              size: 40,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Performance Reviews',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Manage employee performance evaluations and feedback',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Quick Actions
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _showCreateReviewDialog();
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Create Review'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _showComingSoonDialog(
                                  context, 'Review Templates');
                            },
                            icon: const Icon(Icons.description),
                            label: const Text('Templates'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Statistics Cards
                    if (_statistics.isNotEmpty) ...[
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Total Reviews',
                              '${_statistics['total'] ?? 0}',
                              Icons.assessment,
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Completed',
                              '${_statistics['completed'] ?? 0}',
                              Icons.check_circle,
                              Colors.green,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'In Progress',
                              '${_statistics['inProgress'] ?? 0}',
                              Icons.pending,
                              Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Overdue',
                              '${_statistics['overdue'] ?? 0}',
                              Icons.warning,
                              Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Filter Tabs
                    Row(
                      children: [
                        Text(
                          'Filter:',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildFilterChip('all', 'All'),
                                _buildFilterChip('in_progress', 'In Progress'),
                                _buildFilterChip('completed', 'Completed'),
                                _buildFilterChip('overdue', 'Overdue'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Performance Reviews List
                    Expanded(
                      child: Card(
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Text(
                                    'Performance Reviews',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const Spacer(),
                                  if (_isLoading)
                                    const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: _isLoading
                                  ? const Center(
                                      child: CircularProgressIndicator())
                                  : _filteredReviews.isEmpty
                                      ? Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.assessment_outlined,
                                                size: 64,
                                                color: Colors.grey[400],
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                'No Performance Reviews',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleLarge
                                                    ?.copyWith(
                                                      color: Colors.grey[600],
                                                    ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Create your first performance review to get started.',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      color: Colors.grey[500],
                                                    ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : ListView.builder(
                                          padding: const EdgeInsets.all(16.0),
                                          itemCount: _filteredReviews.length,
                                          itemBuilder: (context, index) {
                                            final review =
                                                _filteredReviews[index];
                                            return _buildReviewCard(review);
                                          },
                                        ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<PerformanceReview> get _filteredReviews {
    if (_selectedFilter == 'all') {
      return _reviews;
    }
    return _reviews
        .where((review) => review.status == _selectedFilter)
        .toList();
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = value;
          });
        },
        selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
        checkmarkColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildReviewCard(PerformanceReview review) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: review.statusColor,
          child: Icon(
            _getStatusIcon(review.status),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          review.employeeName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Period: ${review.reviewPeriod}'),
            Text('Reviewer: ${review.reviewerName}'),
            if (review.overallRating != null)
              Text('Rating: ${review.overallRating!.toStringAsFixed(1)}/5.0'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: review.statusColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                review.statusDisplayName,
                style: TextStyle(
                  color: review.statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Due: ${_formatDate(review.dueDate)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        onTap: () => _showReviewDetails(review),
        isThreeLine: true,
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'draft':
        return Icons.edit;
      case 'in_progress':
        return Icons.pending;
      case 'completed':
        return Icons.check_circle;
      case 'overdue':
        return Icons.warning;
      default:
        return Icons.assessment;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showReviewDetails(PerformanceReview review) {
    _showComingSoonDialog(context, 'Review Details');
  }

  void _showCreateReviewDialog() {
    _showComingSoonDialog(context, 'Create New Review');
  }

  void _showComingSoonDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.rocket_launch,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              const Text('Coming Soon'),
            ],
          ),
          content: Text(
            '$feature is currently under development and will be available in a future update.\n\nStay tuned for exciting new features!',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it'),
            ),
          ],
        );
      },
    );
  }
}
