import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/training_provider.dart';
import '../../utils/logger.dart';

class CreateTrainingDialog extends StatefulWidget {
  final Map<String, dynamic>? training;

  const CreateTrainingDialog({super.key, this.training});

  @override
  State<CreateTrainingDialog> createState() => _CreateTrainingDialogState();
}

class _CreateTrainingDialogState extends State<CreateTrainingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _instructorController = TextEditingController();
  final _locationController = TextEditingController();
  final _maxCapacityController = TextEditingController();
  final _durationController = TextEditingController();
  final _learningObjectivesController = TextEditingController();

  String _selectedType = 'workshop';
  String _selectedStatus = 'draft';
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isLoading = false;

  final List<String> _trainingTypes = [
    'workshop',
    'seminar',
    'online_course',
    'certification',
    'onboarding',
    'compliance',
    'skill_development',
    'leadership',
    'technical',
    'soft_skills',
  ];

  final List<String> _trainingStatuses = [
    'draft',
    'upcoming',
    'active',
    'completed',
    'cancelled',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.training != null) {
      _loadTrainingData();
    }
  }

  void _loadTrainingData() {
    final training = widget.training!;
    _titleController.text = training['title'] ?? '';
    _descriptionController.text = training['description'] ?? '';
    _categoryController.text = training['category'] ?? '';
    _instructorController.text = training['instructor'] ?? '';
    _locationController.text = training['location'] ?? '';
    _maxCapacityController.text = (training['maxCapacity'] ?? '').toString();
    _durationController.text = (training['duration'] ?? '').toString();
    _learningObjectivesController.text =
        (training['learningObjectives'] as List<dynamic>?)?.join(', ') ?? '';
    _selectedType = training['type'] ?? 'workshop';
    _selectedStatus = training['status'] ?? 'draft';

    if (training['schedule'] != null) {
      final schedule = training['schedule'];
      if (schedule['startDate'] != null) {
        _startDate = DateTime.parse(schedule['startDate']);
      }
      if (schedule['endDate'] != null) {
        _endDate = DateTime.parse(schedule['endDate']);
      }
      if (schedule['startTime'] != null) {
        final timeParts = schedule['startTime'].split(':');
        _startTime = TimeOfDay(
            hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1]));
      }
      if (schedule['endTime'] != null) {
        final timeParts = schedule['endTime'].split(':');
        _endTime = TimeOfDay(
            hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1]));
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _instructorController.dispose();
    _locationController.dispose();
    _maxCapacityController.dispose();
    _durationController.dispose();
    _learningObjectivesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBasicInfoSection(),
                      const SizedBox(height: 24),
                      _buildScheduleSection(),
                      const SizedBox(height: 24),
                      _buildDetailsSection(),
                      const SizedBox(height: 24),
                      _buildObjectivesSection(),
                    ],
                  ),
                ),
              ),
            ),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          widget.training != null ? 'Edit Training' : 'Create New Training',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Basic Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Training Title *',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a title';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Training Type',
                  border: OutlineInputBorder(),
                ),
                items: _trainingTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_formatTrainingType(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: _trainingStatuses.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(_formatStatus(status)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value!;
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _categoryController,
          decoration: const InputDecoration(
            labelText: 'Category',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Schedule',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ListTile(
                title: const Text('Start Date'),
                subtitle: Text(_startDate != null
                    ? DateFormat('MMM dd, yyyy').format(_startDate!)
                    : 'Select start date'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(true),
              ),
            ),
            Expanded(
              child: ListTile(
                title: const Text('End Date'),
                subtitle: Text(_endDate != null
                    ? DateFormat('MMM dd, yyyy').format(_endDate!)
                    : 'Select end date'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(false),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: ListTile(
                title: const Text('Start Time'),
                subtitle: Text(_startTime != null
                    ? _startTime!.format(context)
                    : 'Select start time'),
                trailing: const Icon(Icons.access_time),
                onTap: () => _selectTime(true),
              ),
            ),
            Expanded(
              child: ListTile(
                title: const Text('End Time'),
                subtitle: Text(_endTime != null
                    ? _endTime!.format(context)
                    : 'Select end time'),
                trailing: const Icon(Icons.access_time),
                onTap: () => _selectTime(false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Training Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _instructorController,
                decoration: const InputDecoration(
                  labelText: 'Instructor',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _maxCapacityController,
                decoration: const InputDecoration(
                  labelText: 'Max Capacity',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(
                  labelText: 'Duration (hours)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildObjectivesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Learning Objectives',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _learningObjectivesController,
          decoration: const InputDecoration(
            labelText: 'Learning Objectives (comma-separated)',
            border: OutlineInputBorder(),
            hintText:
                'e.g., Understand basic concepts, Learn new skills, Complete certification',
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveTraining,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.training != null ? 'Update' : 'Create'),
        ),
      ],
    );
  }

  Future<void> _selectDate(bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? DateTime.now()),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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

  Future<void> _selectTime(bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime
          ? (_startTime ?? TimeOfDay.now())
          : (_endTime ?? TimeOfDay.now()),
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _saveTraining() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final trainingData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'type': _selectedType,
        'status': _selectedStatus,
        'category': _categoryController.text,
        'instructor': _instructorController.text,
        'location': _locationController.text,
        'maxCapacity': _maxCapacityController.text.isNotEmpty
            ? int.parse(_maxCapacityController.text)
            : null,
        'duration': _durationController.text.isNotEmpty
            ? double.parse(_durationController.text)
            : null,
        'learningObjectives': _learningObjectivesController.text.isNotEmpty
            ? _learningObjectivesController.text
                .split(',')
                .map((e) => e.trim())
                .toList()
            : [],
        'schedule': {
          if (_startDate != null) 'startDate': _startDate!.toIso8601String(),
          if (_endDate != null) 'endDate': _endDate!.toIso8601String(),
          if (_startTime != null)
            'startTime':
                '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}',
          if (_endTime != null)
            'endTime':
                '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}',
        },
      };

      final trainingProvider =
          Provider.of<TrainingProvider>(context, listen: false);
      bool success;

      if (widget.training != null) {
        success = await trainingProvider.updateTraining(
            widget.training!['_id'], trainingData);
      } else {
        success = await trainingProvider.createTraining(trainingData);
      }

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.training != null
                ? 'Training updated successfully'
                : 'Training created successfully'),
          ),
        );
      }
    } catch (e) {
      Logger.error('Error saving training: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save training: $e')),
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

  String _formatTrainingType(String type) {
    switch (type) {
      case 'workshop':
        return 'Workshop';
      case 'seminar':
        return 'Seminar';
      case 'online_course':
        return 'Online Course';
      case 'certification':
        return 'Certification';
      case 'onboarding':
        return 'Onboarding';
      case 'compliance':
        return 'Compliance';
      case 'skill_development':
        return 'Skill Development';
      case 'leadership':
        return 'Leadership';
      case 'technical':
        return 'Technical';
      case 'soft_skills':
        return 'Soft Skills';
      default:
        return type;
    }
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'draft':
        return 'Draft';
      case 'upcoming':
        return 'Upcoming';
      case 'active':
        return 'Active';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }
}
