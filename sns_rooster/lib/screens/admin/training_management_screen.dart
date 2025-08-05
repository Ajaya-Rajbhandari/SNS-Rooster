import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/training_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/admin_side_navigation.dart';
import '../../widgets/notification_bell.dart';
import '../../providers/notification_provider.dart';
import '../../utils/logger.dart';
import 'create_training_dialog.dart';
import 'training_detail_screen.dart';

class TrainingManagementScreen extends StatefulWidget {
  const TrainingManagementScreen({super.key});

  @override
  State<TrainingManagementScreen> createState() =>
      _TrainingManagementScreenState();
}

class _TrainingManagementScreenState extends State<TrainingManagementScreen> {
  String _selectedFilter = 'all';
  String _searchQuery = '';
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
        title: const Text('Training Management'),
        actions: const [
          NotificationBell(),
        ],
      ),
      drawer: const AdminSideNavigation(currentRoute: '/training_management'),
      body: Column(
        children: [
          _buildHeader(),
          _buildFilters(),
          _buildSearchBar(),
          Expanded(
            child: _buildTrainingList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateTrainingDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Training Programs',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Consumer<TrainingProvider>(
                builder: (context, trainingProvider, child) {
                  return Text(
                    '${trainingProvider.trainings.length} training programs',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  );
                },
              ),
            ],
          ),
          _buildStatsCards(),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Consumer<TrainingProvider>(
      builder: (context, trainingProvider, child) {
        final stats = trainingProvider.getTrainingStats();
        return Row(
          children: [
            _buildStatCard('Active', stats['active'] ?? 0, Colors.blue),
            const SizedBox(width: 8),
            _buildStatCard('Completed', stats['completed'] ?? 0, Colors.green),
            const SizedBox(width: 8),
            _buildStatCard('Upcoming', stats['upcoming'] ?? 0, Colors.orange),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
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
            _buildFilterChip('Active', 'active'),
            const SizedBox(width: 8),
            _buildFilterChip('Completed', 'completed'),
            const SizedBox(width: 8),
            _buildFilterChip('Draft', 'draft'),
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

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search trainings...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildTrainingList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Consumer<TrainingProvider>(
      builder: (context, trainingProvider, child) {
        final filteredTrainings = trainingProvider.getFilteredTrainings(
          filter: _selectedFilter,
          searchQuery: _searchQuery,
        );

        if (filteredTrainings.isEmpty) {
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
                  'Create your first training program',
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
            itemCount: filteredTrainings.length,
            itemBuilder: (context, index) {
              final training = filteredTrainings[index];
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
    final startDate = training['schedule']?['startDate'];
    final endDate = training['schedule']?['endDate'];
    final enrolledCount = training['enrolledEmployees']?.length ?? 0;
    final maxCapacity = training['maxCapacity'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _navigateToTrainingDetail(training['_id']),
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
                  _buildStatusChip(status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(Icons.category, category),
                  const SizedBox(width: 8),
                  if (startDate != null)
                    _buildInfoChip(
                      Icons.calendar_today,
                      DateFormat('MMM dd, yyyy')
                          .format(DateTime.parse(startDate)),
                    ),
                ],
              ),
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
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editTraining(training),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteTraining(training),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case 'active':
        color = Colors.green;
        label = 'Active';
        break;
      case 'completed':
        color = Colors.blue;
        label = 'Completed';
        break;
      case 'draft':
        color = Colors.grey;
        label = 'Draft';
        break;
      case 'upcoming':
        color = Colors.orange;
        label = 'Upcoming';
        break;
      default:
        color = Colors.grey;
        label = 'Unknown';
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

  void _showCreateTrainingDialog() {
    showDialog(
      context: context,
      builder: (context) => const CreateTrainingDialog(),
    ).then((_) {
      _loadTrainings();
    });
  }

  void _navigateToTrainingDetail(String trainingId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrainingDetailScreen(trainingId: trainingId),
      ),
    ).then((_) {
      _loadTrainings();
    });
  }

  void _editTraining(Map<String, dynamic> training) {
    showDialog(
      context: context,
      builder: (context) => CreateTrainingDialog(training: training),
    ).then((_) {
      _loadTrainings();
    });
  }

  void _deleteTraining(Map<String, dynamic> training) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Training'),
        content:
            Text('Are you sure you want to delete "${training['title']}"?'),
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
                await trainingProvider.deleteTraining(training['_id']);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Training deleted successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete training: $e')),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
