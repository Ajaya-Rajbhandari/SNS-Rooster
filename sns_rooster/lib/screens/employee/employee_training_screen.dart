import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/training_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/notification_bell.dart';
import '../../providers/notification_provider.dart';
import '../../utils/logger.dart';

class EmployeeTrainingScreen extends StatefulWidget {
  const EmployeeTrainingScreen({super.key});

  @override
  State<EmployeeTrainingScreen> createState() => _EmployeeTrainingScreenState();
}

class _EmployeeTrainingScreenState extends State<EmployeeTrainingScreen> {
  String _selectedFilter = 'all';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(context, listen: false)
          .fetchNotifications();
      _loadTrainings();
    });
  }

  Future<void> _loadTrainings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final trainingProvider =
          Provider.of<TrainingProvider>(context, listen: false);
      await trainingProvider.fetchTrainings();
    } catch (e) {
      Logger.error('Error loading trainings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load trainings: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Training Programs'),
        actions: const [
          NotificationBell(),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          _buildHeader(),
          _buildFilters(),
          Expanded(
            child: _buildTrainingList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Available Training Programs',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Consumer<TrainingProvider>(
            builder: (context, trainingProvider, child) {
              final availableTrainings = trainingProvider.getFilteredTrainings(
                filter: 'active',
                searchQuery: '',
              );
              return Text(
                '${availableTrainings.length} training programs available',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All', 'all'),
            const SizedBox(width: 8),
            _buildFilterChip('Available', 'active'),
            const SizedBox(width: 8),
            _buildFilterChip('Enrolled', 'enrolled'),
            const SizedBox(width: 8),
            _buildFilterChip('Completed', 'completed'),
            const SizedBox(width: 8),
            _buildFilterChip('Upcoming', 'upcoming'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      checkmarkColor: Theme.of(context).primaryColor,
    );
  }

  Widget _buildTrainingList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Consumer<TrainingProvider>(
      builder: (context, trainingProvider, child) {
        final trainings = trainingProvider.getFilteredTrainings(
          filter: _selectedFilter == 'all' ? '' : _selectedFilter,
          searchQuery: '',
        );

        if (trainings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.school_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No trainings found',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Check back later for new training programs',
                  style: TextStyle(
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadTrainings,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: trainings.length,
            itemBuilder: (context, index) {
              final training = trainings[index];
              return _buildTrainingCard(training);
            },
          ),
        );
      },
    );
  }

  Widget _buildTrainingCard(Map<String, dynamic> training) {
    final status = training['status'] ?? 'draft';
    final title = training['title'] ?? 'Untitled Training';
    final description = training['description'] ?? '';
    final category = training['category'] ?? 'General';
    final instructor = training['instructor'] ?? 'Not specified';
    final duration = training['duration'] ?? 0;
    final startDate = training['schedule']?['startDate'];
    final enrolledCount = training['enrolledEmployees']?.length ?? 0;
    final maxCapacity = training['maxCapacity'] ?? 0;
    final learningObjectives =
        training['learningObjectives'] as List<dynamic>? ?? [];

    // Check if current user is enrolled
    final currentUser = Provider.of<AuthProvider>(context, listen: false).user;
    final currentUserId = currentUser?['_id'];
    final isEnrolled =
        training['enrolledEmployees']?.any((e) => e['_id'] == currentUserId) ??
            false;
    final enrollmentStatus = isEnrolled
        ? training['enrolledEmployees']
            ?.firstWhere((e) => e['_id'] == currentUserId, orElse: () => {})
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(
                    status, isEnrolled, enrollmentStatus?['status']),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoChip(Icons.category, category),
                const SizedBox(width: 8),
                _buildInfoChip(Icons.person, instructor),
                const SizedBox(width: 8),
                _buildInfoChip(Icons.access_time, '${duration}h'),
              ],
            ),
            if (startDate != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Starts: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(startDate))}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
            if (learningObjectives.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Learning Objectives:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              ...learningObjectives.take(3).map((objective) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle,
                          size: 12, color: Colors.green),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          objective.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              if (learningObjectives.length > 3)
                Text(
                  '... and ${learningObjectives.length - 3} more',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$enrolledCount enrolled${maxCapacity > 0 ? ' / $maxCapacity' : ''}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                _buildActionButton(training, isEnrolled, enrollmentStatus),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(
      String status, bool isEnrolled, String? enrollmentStatus) {
    Color color;
    String label;

    if (isEnrolled) {
      switch (enrollmentStatus) {
        case 'completed':
          color = Colors.green;
          label = 'Completed';
          break;
        case 'in_progress':
          color = Colors.blue;
          label = 'In Progress';
          break;
        case 'not_started':
          color = Colors.orange;
          label = 'Enrolled';
          break;
        default:
          color = Colors.grey;
          label = 'Enrolled';
      }
    } else {
      switch (status) {
        case 'active':
          color = Colors.green;
          label = 'Available';
          break;
        case 'upcoming':
          color = Colors.orange;
          label = 'Upcoming';
          break;
        case 'completed':
          color = Colors.grey;
          label = 'Completed';
          break;
        default:
          color = Colors.grey;
          label = 'Not Available';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(Map<String, dynamic> training, bool isEnrolled,
      Map<String, dynamic>? enrollmentStatus) {
    final status = training['status'] ?? 'draft';
    final maxCapacity = training['maxCapacity'] ?? 0;
    final enrolledCount = training['enrolledEmployees']?.length ?? 0;
    final isFull = maxCapacity > 0 && enrolledCount >= maxCapacity;

    if (isEnrolled) {
      final enrollmentStatusStr = enrollmentStatus?['status'] ?? 'not_started';

      switch (enrollmentStatusStr) {
        case 'completed':
          return ElevatedButton.icon(
            onPressed: () => _viewCertificate(training),
            icon: const Icon(Icons.verified, size: 16),
            label: const Text('View Certificate'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          );
        case 'in_progress':
          return ElevatedButton.icon(
            onPressed: () => _continueTraining(training),
            icon: const Icon(Icons.play_arrow, size: 16),
            label: const Text('Continue'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          );
        default:
          return ElevatedButton.icon(
            onPressed: () => _startTraining(training),
            icon: const Icon(Icons.play_arrow, size: 16),
            label: const Text('Start'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          );
      }
    } else {
      if (status == 'active' && !isFull) {
        return ElevatedButton.icon(
          onPressed: () => _enrollInTraining(training),
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Enroll'),
        );
      } else if (isFull) {
        return ElevatedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.person_off, size: 16),
          label: const Text('Full'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey,
            foregroundColor: Colors.white,
          ),
        );
      } else {
        return ElevatedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.schedule, size: 16),
          label: const Text('Coming Soon'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey,
            foregroundColor: Colors.white,
          ),
        );
      }
    }
  }

  void _enrollInTraining(Map<String, dynamic> training) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enroll in Training'),
        content:
            Text('Are you sure you want to enroll in "${training['title']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final trainingProvider =
                    Provider.of<TrainingProvider>(context, listen: false);
                final currentUser =
                    Provider.of<AuthProvider>(context, listen: false).user;
                final success = await trainingProvider.enrollEmployee(
                  training['_id'],
                  currentUser!['_id'],
                );
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Successfully enrolled in training')),
                  );
                  _loadTrainings();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to enroll: $e')),
                  );
                }
              }
            },
            child: const Text('Enroll'),
          ),
        ],
      ),
    );
  }

  void _startTraining(Map<String, dynamic> training) {
    // TODO: Implement training start functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Training start feature coming soon')),
    );
  }

  void _continueTraining(Map<String, dynamic> training) {
    // TODO: Implement training continue functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Training continue feature coming soon')),
    );
  }

  void _viewCertificate(Map<String, dynamic> training) {
    // TODO: Implement certificate viewing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Certificate viewing feature coming soon')),
    );
  }
}
