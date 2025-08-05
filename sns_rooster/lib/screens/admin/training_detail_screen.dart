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

class TrainingDetailScreen extends StatefulWidget {
  final String trainingId;

  const TrainingDetailScreen({super.key, required this.trainingId});

  @override
  State<TrainingDetailScreen> createState() => _TrainingDetailScreenState();
}

class _TrainingDetailScreenState extends State<TrainingDetailScreen> {
  Map<String, dynamic>? _training;
  bool _isLoading = true;
  String? _error;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(context, listen: false)
          .fetchNotifications();
      _loadTrainingDetails();
    });
  }

  Future<void> _loadTrainingDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final trainingProvider =
          Provider.of<TrainingProvider>(context, listen: false);
      final training =
          await trainingProvider.fetchTrainingById(widget.trainingId);

      if (training != null) {
        setState(() {
          _training = training;
        });
      } else {
        setState(() {
          _error = 'Training not found';
        });
      }
    } catch (e) {
      Logger.error('Error loading training details: $e');
      setState(() {
        _error = 'Failed to load training details: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_training?['title'] ?? 'Training Details'),
        actions: const [
          NotificationBell(),
        ],
      ),
      drawer: const AdminSideNavigation(currentRoute: '/training_management'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : _buildTrainingDetails(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Error',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: TextStyle(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadTrainingDetails,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainingDetails() {
    if (_training == null) {
      return const Center(child: Text('Training not found'));
    }

    return Column(
      children: [
        _buildHeader(),
        _buildTabBar(),
        Expanded(
          child: _buildTabContent(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final status = _training!['status'] ?? 'draft';
    final title = _training!['title'] ?? 'Untitled Training';
    final category = _training!['category'] ?? 'General';
    final instructor = _training!['instructor'] ?? 'Not specified';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildStatusChip(status),
                        const SizedBox(width: 8),
                        _buildInfoChip(Icons.category, category),
                        const SizedBox(width: 8),
                        _buildInfoChip(Icons.person, instructor),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _editTraining(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteTraining(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        onTap: (index) {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        labelColor: Theme.of(context).primaryColor,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Theme.of(context).primaryColor,
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Enrollments'),
          Tab(text: 'Materials'),
          Tab(text: 'Progress'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildOverviewTab();
      case 1:
        return _buildEnrollmentsTab();
      case 2:
        return _buildMaterialsTab();
      case 3:
        return _buildProgressTab();
      default:
        return _buildOverviewTab();
    }
  }

  Widget _buildOverviewTab() {
    final description = _training!['description'] ?? '';
    final location = _training!['location'] ?? 'Not specified';
    final duration = _training!['duration'] ?? 0;
    final maxCapacity = _training!['maxCapacity'] ?? 0;
    final enrolledCount =
        (_training!['enrolledEmployees'] as List<dynamic>?)?.length ?? 0;
    final learningObjectives =
        _training!['learningObjectives'] as List<dynamic>? ?? [];
    final schedule = _training!['schedule'] ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection('Description', description),
          const SizedBox(height: 24),
          _buildSection('Schedule', _buildScheduleInfo(schedule)),
          const SizedBox(height: 24),
          _buildSection(
              'Details',
              _buildDetailsInfo(
                  location, duration, maxCapacity, enrolledCount)),
          const SizedBox(height: 24),
          _buildSection(
              'Learning Objectives', _buildObjectivesList(learningObjectives)),
        ],
      ),
    );
  }

  Widget _buildEnrollmentsTab() {
    final enrolledEmployees =
        _training!['enrolledEmployees'] as List<dynamic>? ?? [];
    final maxCapacity = _training!['maxCapacity'] ?? 0;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Enrolled Employees (${enrolledEmployees.length}${maxCapacity > 0 ? '/$maxCapacity' : ''})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton(
                onPressed: () => _showEnrollEmployeeDialog(),
                child: const Text('Enroll Employee'),
              ),
            ],
          ),
        ),
        Expanded(
          child: enrolledEmployees.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No employees enrolled',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enroll employees to start the training',
                        style: TextStyle(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: enrolledEmployees.length,
                  itemBuilder: (context, index) {
                    final employee = enrolledEmployees[index];
                    return _buildEnrollmentCard(employee);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMaterialsTab() {
    final materials = _training!['materials'] as List<dynamic>? ?? [];

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Training Materials (${materials.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton(
                onPressed: () => _showAddMaterialDialog(),
                child: const Text('Add Material'),
              ),
            ],
          ),
        ),
        Expanded(
          child: materials.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.folder,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No materials uploaded',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Upload training materials for employees',
                        style: TextStyle(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: materials.length,
                  itemBuilder: (context, index) {
                    final material = materials[index];
                    return _buildMaterialCard(material);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildProgressTab() {
    final enrolledEmployees =
        _training!['enrolledEmployees'] as List<dynamic>? ?? [];
    final completedEmployees =
        enrolledEmployees.where((e) => e['status'] == 'completed').length;
    final inProgressEmployees =
        enrolledEmployees.where((e) => e['status'] == 'in_progress').length;
    final notStartedEmployees =
        enrolledEmployees.where((e) => e['status'] == 'not_started').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgressStats(
              completedEmployees, inProgressEmployees, notStartedEmployees),
          const SizedBox(height: 24),
          _buildProgressChart(enrolledEmployees),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        content,
      ],
    );
  }

  Widget _buildSectionText(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
          ),
        ),
      ],
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

  Widget _buildScheduleInfo(Map<String, dynamic> schedule) {
    final startDate = schedule['startDate'];
    final endDate = schedule['endDate'];
    final startTime = schedule['startTime'];
    final endTime = schedule['endTime'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (startDate != null) ...[
          Text(
              'Start Date: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(startDate))}'),
          const SizedBox(height: 4),
        ],
        if (endDate != null) ...[
          Text(
              'End Date: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(endDate))}'),
          const SizedBox(height: 4),
        ],
        if (startTime != null) ...[
          Text('Start Time: $startTime'),
          const SizedBox(height: 4),
        ],
        if (endTime != null) ...[
          Text('End Time: $endTime'),
        ],
      ],
    );
  }

  Widget _buildDetailsInfo(String location, dynamic duration,
      dynamic maxCapacity, int enrolledCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Location: $location'),
        const SizedBox(height: 4),
        Text('Duration: ${duration.toString()} hours'),
        const SizedBox(height: 4),
        Text(
            'Max Capacity: ${maxCapacity > 0 ? maxCapacity.toString() : 'Unlimited'}'),
        const SizedBox(height: 4),
        Text('Enrolled: $enrolledCount'),
      ],
    );
  }

  Widget _buildObjectivesList(List<dynamic> objectives) {
    if (objectives.isEmpty) {
      return const Text('No learning objectives specified');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: objectives.map((objective) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.check_circle, size: 16, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(child: Text(objective.toString())),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEnrollmentCard(Map<String, dynamic> employee) {
    final name =
        '${employee['firstName'] ?? ''} ${employee['lastName'] ?? ''}'.trim();
    final email = employee['email'] ?? '';
    final status = employee['status'] ?? 'not_started';
    final enrollmentDate = employee['enrollmentDate'];
    final completionDate = employee['completionDate'];
    final score = employee['score'];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
        ),
        title: Text(name.isNotEmpty ? name : 'Unknown Employee'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(email),
            if (enrollmentDate != null)
              Text(
                  'Enrolled: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(enrollmentDate))}'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStatusChip(status),
            if (score != null) Text('Score: $score%'),
          ],
        ),
        onTap: () => _showEmployeeProgressDialog(employee),
      ),
    );
  }

  Widget _buildMaterialCard(Map<String, dynamic> material) {
    final name = material['name'] ?? 'Unknown Material';
    final type = material['type'] ?? 'Unknown';
    final size = material['size'] ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(_getMaterialIcon(type)),
        title: Text(name),
        subtitle: Text('$type • ${_formatFileSize(size)}'),
        trailing: IconButton(
          icon: const Icon(Icons.download),
          onPressed: () => _downloadMaterial(material),
        ),
      ),
    );
  }

  Widget _buildProgressStats(int completed, int inProgress, int notStarted) {
    final total = completed + inProgress + notStarted;
    final completionRate = total > 0 ? (completed / total * 100).round() : 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Overall Progress',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Completed', completed, Colors.green),
                _buildStatItem('In Progress', inProgress, Colors.orange),
                _buildStatItem('Not Started', notStarted, Colors.grey),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: total > 0 ? completed / total : 0,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            ),
            const SizedBox(height: 8),
            Text(
              '$completionRate% Complete',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressChart(List<dynamic> employees) {
    // Simple progress chart - can be enhanced with charts library
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Employee Progress',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...employees.map((employee) {
              final name =
                  '${employee['firstName'] ?? ''} ${employee['lastName'] ?? ''}'
                      .trim();
              final progress = employee['progress'] ?? 0.0;
              final status = employee['status'] ?? 'not_started';

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(name.isNotEmpty ? name : 'Unknown Employee'),
                        _buildStatusChip(status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[300],
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                    const SizedBox(height: 4),
                    Text('${(progress * 100).round()}%'),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  IconData _getMaterialIcon(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'video':
        return Icons.video_library;
      case 'image':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} KB';
    return '${(bytes / (1024 * 1024)).round()} MB';
  }

  void _editTraining() {
    showDialog(
      context: context,
      builder: (context) => CreateTrainingDialog(training: _training),
    ).then((_) {
      _loadTrainingDetails();
    });
  }

  void _deleteTraining() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Training'),
        content:
            Text('Are you sure you want to delete "${_training!['title']}"?'),
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
                final success =
                    await trainingProvider.deleteTraining(widget.trainingId);
                if (success && mounted) {
                  Navigator.pop(context);
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

  void _showEnrollEmployeeDialog() {
    // TODO: Implement employee enrollment dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Employee enrollment feature coming soon')),
    );
  }

  void _showAddMaterialDialog() {
    // TODO: Implement material upload dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Material upload feature coming soon')),
    );
  }

  void _showEmployeeProgressDialog(Map<String, dynamic> employee) {
    // TODO: Implement employee progress dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Employee progress feature coming soon')),
    );
  }

  void _downloadMaterial(Map<String, dynamic> material) {
    // TODO: Implement material download
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Material download feature coming soon')),
    );
  }
}
