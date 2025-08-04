import 'package:flutter/material.dart';
import '../../models/performance_review.dart';
import '../../services/performance_review_service.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../../widgets/app_drawer.dart';

class EmployeePerformanceReviewScreen extends StatefulWidget {
  final String reviewId;

  const EmployeePerformanceReviewScreen({
    super.key,
    required this.reviewId,
  });

  @override
  State<EmployeePerformanceReviewScreen> createState() =>
      _EmployeePerformanceReviewScreenState();
}

class _EmployeePerformanceReviewScreenState
    extends State<EmployeePerformanceReviewScreen> {
  late PerformanceReviewService _performanceReviewService;
  PerformanceReview? _review;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  String? _error;

  // Form controllers for editing
  final _formKey = GlobalKey<FormState>();
  final _employeeCommentsController = TextEditingController();
  final _selfAssessmentController = TextEditingController();

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

    _employeeCommentsController.text = _review!.employeeComments ?? '';
    _selfAssessmentController.text = _review!.employeeComments ?? '';
  }

  @override
  void dispose() {
    _employeeCommentsController.dispose();
    _selfAssessmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Performance Review'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading && _review != null) ...[
            if (_canEdit() && !_isEditing) ...[
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: _startEditing,
                tooltip: 'Add Self-Assessment',
              ),
            ] else if (_isEditing) ...[
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: _isSaving ? null : _saveChanges,
                tooltip: 'Save Self-Assessment',
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
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : _review == null
                  ? const Center(child: Text('Review not found'))
                  : _buildReviewDetails(),
    );
  }

  bool _canEdit() {
    return _review!.status == 'submitted_for_employee_review';
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
            _buildStatusSection(),
            const SizedBox(height: 24),
            _buildBasicInfoSection(),
            const SizedBox(height: 24),
            _buildScoresSection(),
            const SizedBox(height: 24),
            _buildManagerCommentsSection(),
            const SizedBox(height: 24),
            _buildSelfAssessmentSection(),
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
                    'Performance Review',
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

  Widget _buildStatusSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Review Status',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
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
                    _getStatusMessage(),
                    style: TextStyle(
                      color: _review!.statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (_canEdit()) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.blue,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Please add your self-assessment to complete this review.',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getStatusMessage() {
    switch (_review!.status) {
      case 'draft':
        return 'Review in Draft';
      case 'in_progress':
        return 'Review in Progress - Awaiting Admin Action';
      case 'submitted_for_employee_review':
        return 'Action Required: Add Self-Assessment';
      case 'employee_review_complete':
        return 'Self-Assessment Complete';
      case 'completed':
        return 'Review Finalized';
      default:
        return _review!.statusDisplayName;
    }
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Review Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
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
                      child: Text(
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

  Widget _buildManagerCommentsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manager Feedback',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              _review!.comments ?? 'No manager feedback provided yet',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[700],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelfAssessmentSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Your Self-Assessment',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                if (_canEdit() && !_isEditing)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Required',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isEditing) ...[
              TextFormField(
                controller: _selfAssessmentController,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText:
                      'Please provide your self-assessment, achievements, goals, and areas for improvement...',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Self-assessment is required';
                  }
                  return null;
                },
              ),
            ] else ...[
              Text(
                _review!.employeeComments ?? 'No self-assessment provided yet',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[700],
                    ),
              ),
            ],
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
            Text(
              'Goals',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
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
            Text(
              'Achievements',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
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
        ),
      ),
    );
  }

  Widget _buildAreasOfImprovementSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Areas of Improvement',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
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
      case 'submitted_for_employee_review':
        return Icons.pending;
      case 'employee_review_complete':
        return Icons.check_circle;
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
      final updateData = <String, dynamic>{
        'employeeComments': _selfAssessmentController.text.trim(),
        'status': 'employee_review_complete',
      };

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
            content: Text('Self-assessment submitted successfully'),
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
            content: Text('Error submitting self-assessment: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
