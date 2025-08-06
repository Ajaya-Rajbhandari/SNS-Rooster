import 'package:flutter/material.dart';
import '../../models/performance_review.dart';
import '../../services/performance_review_service.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../../widgets/admin_side_navigation.dart';

class PerformanceReviewDetailsScreen extends StatefulWidget {
  final String reviewId;

  const PerformanceReviewDetailsScreen({
    super.key,
    required this.reviewId,
  });

  @override
  State<PerformanceReviewDetailsScreen> createState() =>
      _PerformanceReviewDetailsScreenState();
}

class _PerformanceReviewDetailsScreenState
    extends State<PerformanceReviewDetailsScreen> {
  late PerformanceReviewService _performanceReviewService;
  PerformanceReview? _review;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  String? _error;

  // Form controllers for editing
  final _formKey = GlobalKey<FormState>();
  final _commentsController = TextEditingController();
  final _employeeCommentsController = TextEditingController();
  final _overallRatingController = TextEditingController();

  // Controllers for dynamic lists
  final List<TextEditingController> _goalsControllers = [];
  final List<TextEditingController> _achievementsControllers = [];
  final List<TextEditingController> _areasOfImprovementControllers = [];

  // Score controllers
  final Map<String, TextEditingController> _scoreControllers = {};

  @override
  void initState() {
    super.initState();
    _initializeService();
    _loadReviewDetails();
  }

  void _initializeService() {
    final apiService = ApiService(baseUrl: ApiConfig.baseUrl);
    _performanceReviewService = PerformanceReviewService(apiService);
  }

  Future<void> _loadReviewDetails() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final review =
          await _performanceReviewService.getPerformanceReview(widget.reviewId);

      if (mounted) {
        setState(() {
          _review = review;
          _isLoading = false;
        });
        _initializeControllers();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _initializeControllers() {
    if (_review == null) return;

    // Initialize score controllers
    _scoreControllers.clear();
    _review!.scores.forEach((key, value) {
      _scoreControllers[key] =
          TextEditingController(text: value?.toString() ?? '');
    });

    // Initialize other controllers
    _commentsController.text = _review!.comments ?? '';
    _employeeCommentsController.text = _review!.employeeComments ?? '';
    _overallRatingController.text = _review!.overallRating?.toString() ?? '';

    // Initialize list controllers
    _goalsControllers.clear();
    _achievementsControllers.clear();
    _areasOfImprovementControllers.clear();

    for (String goal in _review!.goals) {
      _goalsControllers.add(TextEditingController(text: goal));
    }
    for (String achievement in _review!.achievements) {
      _achievementsControllers.add(TextEditingController(text: achievement));
    }
    for (String area in _review!.areasOfImprovement) {
      _areasOfImprovementControllers.add(TextEditingController(text: area));
    }

    // Add empty controllers for new items
    _goalsControllers.add(TextEditingController());
    _achievementsControllers.add(TextEditingController());
    _areasOfImprovementControllers.add(TextEditingController());
  }

  @override
  void dispose() {
    _commentsController.dispose();
    _employeeCommentsController.dispose();
    _overallRatingController.dispose();
    for (var controller in _scoreControllers.values) {
      controller.dispose();
    }
    for (var controller in _goalsControllers) {
      controller.dispose();
    }
    for (var controller in _achievementsControllers) {
      controller.dispose();
    }
    for (var controller in _areasOfImprovementControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Review' : 'Review Details'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading && _review != null) ...[
            if (!_isEditing) ...[
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: _startEditing,
                tooltip: 'Edit Review',
              ),
            ] else ...[
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: _isSaving ? null : _saveChanges,
                tooltip: 'Save Changes',
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: _cancelEditing,
                tooltip: 'Cancel',
              ),
            ],
          ],
        ],
      ),
      drawer: const AdminSideNavigation(currentRoute: '/performance_reviews'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : _review == null
                  ? const Center(child: Text('Review not found'))
                  : _buildReviewDetails(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Error loading review',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadReviewDetails,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderSection(),
            const SizedBox(height: 24),
            _buildStatusManagementSection(),
            const SizedBox(height: 24),
            _buildBasicInfoSection(),
            const SizedBox(height: 24),
            _buildScoresSection(),
            const SizedBox(height: 24),
            _buildCommentsSection(),
            const SizedBox(height: 24),
            _buildGoalsSection(),
            const SizedBox(height: 24),
            _buildAchievementsSection(),
            const SizedBox(height: 24),
            _buildAreasOfImprovementSection(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: _review!.statusColor,
              child: Icon(
                _getStatusIcon(_review!.status),
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _review!.employeeName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    'Period: ${_review!.reviewPeriod}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _review!.statusColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _review!.statusDisplayName,
                style: TextStyle(
                  color: _review!.statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basic Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Employee', _review!.employeeName),
            _buildInfoRow('Reviewer', _review!.reviewerName),
            _buildInfoRow('Start Date', _formatDate(_review!.startDate)),
            _buildInfoRow('End Date', _formatDate(_review!.endDate)),
            _buildInfoRow('Due Date', _formatDate(_review!.dueDate)),
            if (_review!.overallRating != null)
              _buildInfoRow('Overall Rating',
                  '${_review!.overallRating!.toStringAsFixed(1)}/5.0'),
          ],
        ),
      ),
    );
  }

  Widget _buildScoresSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Scores',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ..._review!.scores.entries.map((entry) {
              final controller = _scoreControllers[entry.key];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        _formatScoreLabel(entry.key),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: _isEditing
                          ? TextFormField(
                              controller: controller,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: '1-5',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  final rating = double.tryParse(value);
                                  if (rating == null ||
                                      rating < 1 ||
                                      rating > 5) {
                                    return 'Enter 1-5';
                                  }
                                }
                                return null;
                              },
                            )
                          : Text(
                              '${entry.value ?? 'N/A'}/5',
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comments',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'Manager Comments',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _isEditing
                ? TextFormField(
                    controller: _commentsController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Enter evaluation feedback and comments...',
                      border: OutlineInputBorder(),
                    ),
                  )
                : Text(
                    _review!.comments ?? 'No manager comments',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
            const SizedBox(height: 16),
            Text(
              'Employee Self-Assessment',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _review!.employeeComments ?? 'No employee self-assessment',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[700],
                  ),
            ),
            if (_review!.employeeComments == null ||
                _review!.employeeComments!.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Employee has not provided self-assessment yet',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Goals',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                if (_isEditing)
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _addGoal,
                    tooltip: 'Add Goal',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isEditing) ...[
              ..._goalsControllers.map((controller) => _buildEditableListItem(
                    controller: controller,
                    hintText: 'Enter a goal...',
                    onRemove: _goalsControllers.length > 1
                        ? () => _removeGoal(controller)
                        : null,
                  )),
            ] else ...[
              if (_review!.goals.isEmpty)
                Text(
                  'No goals set',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                )
              else
                ..._review!.goals.map((goal) => _buildListItem(goal)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Achievements',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                if (_isEditing)
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _addAchievement,
                    tooltip: 'Add Achievement',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isEditing) ...[
              ..._achievementsControllers
                  .map((controller) => _buildEditableListItem(
                        controller: controller,
                        hintText: 'Enter an achievement...',
                        onRemove: _achievementsControllers.length > 1
                            ? () => _removeAchievement(controller)
                            : null,
                      )),
            ] else ...[
              if (_review!.achievements.isEmpty)
                Text(
                  'No achievements recorded',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                )
              else
                ..._review!.achievements
                    .map((achievement) => _buildListItem(achievement)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusManagementSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status Management',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Status',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _review!.statusColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _review!.statusColor,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getStatusIcon(_review!.status),
                              color: _review!.statusColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _review!.statusDisplayName,
                              style: TextStyle(
                                color: _review!.statusColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Actions',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      _buildStatusActionButtons(),
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

  Widget _buildStatusActionButtons() {
    switch (_review!.status) {
      case 'draft':
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _submitForEmployeeReview,
                icon: const Icon(Icons.send),
                label: const Text('Submit for Employee Review'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Employee will be notified to add self-assessment',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      case 'in_progress':
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.pending,
                    color: Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Review in Progress',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _submitForEmployeeReview,
                icon: const Icon(Icons.send),
                label: const Text('Submit for Employee Review'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Move to next step: Employee self-assessment',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      case 'submitted_for_employee_review':
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.pending,
                    color: Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Waiting for Employee',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isSaving ? null : _revertToDraft,
                icon: const Icon(Icons.undo),
                label: const Text('Revert to Draft'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                ),
              ),
            ),
          ],
        );
      case 'employee_review_complete':
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _completeReview,
                icon: const Icon(Icons.check_circle),
                label: const Text('Finalize Review'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isSaving ? null : _revertToDraft,
                icon: const Icon(Icons.undo),
                label: const Text('Revert to Draft'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                ),
              ),
            ),
          ],
        );
      case 'completed':
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.green,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Review Completed',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isSaving ? null : _reopenReview,
                icon: const Icon(Icons.refresh),
                label: const Text('Reopen Review'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue,
                ),
              ),
            ),
          ],
        );
      default:
        return const Text('No actions available');
    }
  }

  Widget _buildAreasOfImprovementSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Areas of Improvement',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                if (_isEditing)
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _addAreaOfImprovement,
                    tooltip: 'Add Area of Improvement',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isEditing) ...[
              ..._areasOfImprovementControllers
                  .map((controller) => _buildEditableListItem(
                        controller: controller,
                        hintText: 'Enter an area of improvement...',
                        onRemove: _areasOfImprovementControllers.length > 1
                            ? () => _removeAreaOfImprovement(controller)
                            : null,
                      )),
            ] else ...[
              if (_review!.areasOfImprovement.isEmpty)
                Text(
                  'No areas of improvement identified',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                )
              else
                ..._review!.areasOfImprovement
                    .map((area) => _buildListItem(area)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.fiber_manual_record, size: 8, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  String _formatScoreLabel(String key) {
    switch (key) {
      case 'communication':
        return 'Communication';
      case 'teamwork':
        return 'Teamwork';
      case 'technical':
        return 'Technical Skills';
      case 'leadership':
        return 'Leadership';
      case 'problemSolving':
        return 'Problem Solving';
      case 'initiative':
        return 'Initiative';
      default:
        return key.replaceAll(RegExp(r'([A-Z])'), ' \$1').trim();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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

  void _startEditing() {
    setState(() {
      _isEditing = true;
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
    });
    _initializeControllers(); // Reset to original values
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Prepare update data
      final updateData = <String, dynamic>{};

      // Scores
      final scores = <String, dynamic>{};
      _scoreControllers.forEach((key, controller) {
        if (controller.text.isNotEmpty) {
          scores[key] = double.parse(controller.text);
        }
      });
      updateData['scores'] = scores;

      // Comments - Only manager comments can be edited by admin
      if (_commentsController.text.isNotEmpty) {
        updateData['comments'] = _commentsController.text;
      }
      // Employee comments are read-only for admin - they should be added by employee

      // Overall rating
      if (_overallRatingController.text.isNotEmpty) {
        updateData['overallRating'] =
            double.parse(_overallRatingController.text);
      }

      // Lists
      final goals = _goalsControllers
          .map((controller) => controller.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();
      updateData['goals'] = goals;

      final achievements = _achievementsControllers
          .map((controller) => controller.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();
      updateData['achievements'] = achievements;

      final areasOfImprovement = _areasOfImprovementControllers
          .map((controller) => controller.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();
      updateData['areasOfImprovement'] = areasOfImprovement;

      // Update the review
      final updatedReview =
          await _performanceReviewService.updatePerformanceReview(
        widget.reviewId,
        updateData,
      );

      if (mounted) {
        setState(() {
          _review = updatedReview;
          _isEditing = false;
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating review: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addGoal() {
    setState(() {
      _goalsControllers.add(TextEditingController());
    });
  }

  void _removeGoal(TextEditingController controller) {
    setState(() {
      _goalsControllers.remove(controller);
      controller.dispose();
    });
  }

  void _addAchievement() {
    setState(() {
      _achievementsControllers.add(TextEditingController());
    });
  }

  void _removeAchievement(TextEditingController controller) {
    setState(() {
      _achievementsControllers.remove(controller);
      controller.dispose();
    });
  }

  void _addAreaOfImprovement() {
    setState(() {
      _areasOfImprovementControllers.add(TextEditingController());
    });
  }

  void _removeAreaOfImprovement(TextEditingController controller) {
    setState(() {
      _areasOfImprovementControllers.remove(controller);
      controller.dispose();
    });
  }

  // Status Management Methods
  Future<void> _submitForEmployeeReview() async {
    await _changeStatus('submitted_for_employee_review',
        'Review submitted for employee self-assessment');
  }

  Future<void> _completeReview() async {
    await _changeStatus('completed', 'Review finalized successfully');
  }

  Future<void> _revertToDraft() async {
    await _changeStatus('draft', 'Review reverted to draft');
  }

  Future<void> _reopenReview() async {
    await _changeStatus(
        'submitted_for_employee_review', 'Review reopened for employee input');
  }

  Future<void> _changeStatus(String newStatus, String successMessage) async {
    setState(() {
      _isSaving = true;
    });

    try {
      final updateData = <String, dynamic>{
        'status': newStatus,
      };

      // If completing the review, set completedAt timestamp
      if (newStatus == 'completed') {
        updateData['completedAt'] = DateTime.now().toIso8601String();
      }

      final updatedReview =
          await _performanceReviewService.updatePerformanceReview(
        widget.reviewId,
        updateData,
      );

      if (mounted) {
        setState(() {
          _review = updatedReview;
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildEditableListItem({
    required TextEditingController controller,
    required String hintText,
    VoidCallback? onRemove,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hintText,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.remove_circle, color: Colors.red),
              onPressed: onRemove,
              tooltip: 'Remove',
            ),
          ],
        ],
      ),
    );
  }
}
