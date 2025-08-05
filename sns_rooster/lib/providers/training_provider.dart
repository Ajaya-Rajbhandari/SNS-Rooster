import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import '../utils/logger.dart';

class TrainingProvider with ChangeNotifier {
  final ApiService _apiService;
  List<Map<String, dynamic>> _trainings = [];
  Map<String, dynamic>? _selectedTraining;
  bool _isLoading = false;
  String? _error;

  TrainingProvider(this._apiService);

  // Getters
  List<Map<String, dynamic>> get trainings => _trainings;
  Map<String, dynamic>? get selectedTraining => _selectedTraining;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch all trainings for the company
  Future<void> fetchTrainings() async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.get('/training');
      if (response != null &&
          response.data != null &&
          response.data['trainings'] != null) {
        _trainings =
            List<Map<String, dynamic>>.from(response.data['trainings']);
        Logger.info('Fetched ${_trainings.length} trainings');
      } else {
        _trainings = [];
      }
    } catch (e) {
      _setError('Failed to fetch trainings: $e');
      Logger.error('Error fetching trainings: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Fetch a specific training by ID
  Future<Map<String, dynamic>?> fetchTrainingById(String trainingId) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.get('/training/$trainingId');
      if (response != null && response.data != null) {
        _selectedTraining = response.data;
        Logger.info('Fetched training: ${response.data['title']}');
        return response.data;
      }
      return null;
    } catch (e) {
      _setError('Failed to fetch training: $e');
      Logger.error('Error fetching training $trainingId: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Create a new training
  Future<bool> createTraining(Map<String, dynamic> trainingData) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.post('/training', trainingData);
      if (response != null) {
        await fetchTrainings(); // Refresh the list
        Logger.info('Training created successfully');
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to create training: $e');
      Logger.error('Error creating training: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update an existing training
  Future<bool> updateTraining(
      String trainingId, Map<String, dynamic> trainingData) async {
    _setLoading(true);
    _clearError();

    try {
      final response =
          await _apiService.put('/training/$trainingId', trainingData);
      if (response != null) {
        await fetchTrainings(); // Refresh the list
        Logger.info('Training updated successfully');
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to update training: $e');
      Logger.error('Error updating training: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete a training
  Future<bool> deleteTraining(String trainingId) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.delete('/training/$trainingId');
      if (response != null) {
        await fetchTrainings(); // Refresh the list
        Logger.info('Training deleted successfully');
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to delete training: $e');
      Logger.error('Error deleting training: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Enroll an employee in a training
  Future<bool> enrollEmployee(String trainingId, String employeeId) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.post('/training/$trainingId/enroll', {
        'employeeId': employeeId,
      });
      if (response != null) {
        await fetchTrainingById(trainingId); // Refresh the training details
        Logger.info('Employee enrolled successfully');
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to enroll employee: $e');
      Logger.error('Error enrolling employee: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Unenroll an employee from a training
  Future<bool> unenrollEmployee(String trainingId, String employeeId) async {
    _setLoading(true);
    _clearError();

    try {
      final response =
          await _apiService.delete('/training/$trainingId/enroll/$employeeId');
      if (response != null) {
        await fetchTrainingById(trainingId); // Refresh the training details
        Logger.info('Employee unenrolled successfully');
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to unenroll employee: $e');
      Logger.error('Error unenrolling employee: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Complete training for an employee
  Future<bool> completeTrainingForEmployee(String trainingId, String employeeId,
      {double? score}) async {
    _setLoading(true);
    _clearError();

    try {
      final data = {'employeeId': employeeId};
      if (score != null) {
        data['score'] = score.toString();
      }

      final response =
          await _apiService.post('/training/$trainingId/complete', data);
      if (response != null) {
        await fetchTrainingById(trainingId); // Refresh the training details
        Logger.info('Training completed for employee');
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to complete training: $e');
      Logger.error('Error completing training: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get training statistics
  Future<Map<String, dynamic>?> fetchTrainingStats() async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.get('/training/stats');
      if (response != null && response.data != null) {
        Logger.info('Training stats fetched successfully');
        return response.data;
      }
      return null;
    } catch (e) {
      _setError('Failed to fetch training stats: $e');
      Logger.error('Error fetching training stats: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Get filtered trainings
  List<Map<String, dynamic>> getFilteredTrainings({
    String filter = 'all',
    String searchQuery = '',
  }) {
    List<Map<String, dynamic>> filtered = List.from(_trainings);

    // Apply status filter
    if (filter != 'all') {
      filtered = filtered.where((training) {
        final status = training['status'] ?? 'draft';
        return status == filter;
      }).toList();
    }

    // Apply search filter
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((training) {
        final title = (training['title'] ?? '').toString().toLowerCase();
        final description =
            (training['description'] ?? '').toString().toLowerCase();
        final category = (training['category'] ?? '').toString().toLowerCase();
        final query = searchQuery.toLowerCase();

        return title.contains(query) ||
            description.contains(query) ||
            category.contains(query);
      }).toList();
    }

    return filtered;
  }

  // Get training statistics for display
  Map<String, int> getTrainingStats() {
    final now = DateTime.now();
    int active = 0;
    int completed = 0;
    int upcoming = 0;
    int draft = 0;

    for (final training in _trainings) {
      final status = training['status'] ?? 'draft';
      final startDate = training['schedule']?['startDate'];
      final endDate = training['schedule']?['endDate'];

      switch (status) {
        case 'active':
          active++;
          break;
        case 'completed':
          completed++;
          break;
        case 'draft':
          draft++;
          break;
        case 'upcoming':
          if (startDate != null) {
            final start = DateTime.parse(startDate);
            if (start.isAfter(now)) {
              upcoming++;
            }
          }
          break;
      }
    }

    return {
      'active': active,
      'completed': completed,
      'upcoming': upcoming,
      'draft': draft,
    };
  }

  // Clear selected training
  void clearSelectedTraining() {
    _selectedTraining = null;
    notifyListeners();
  }

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
