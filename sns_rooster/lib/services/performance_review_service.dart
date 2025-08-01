import '../models/performance_review.dart';
import 'api_service.dart';

class PerformanceReviewService {
  final ApiService apiService;

  PerformanceReviewService(this.apiService);

  // Get all performance reviews for the current company
  Future<List<PerformanceReview>> getPerformanceReviews({
    String? status,
    String? employeeId,
  }) async {
    String endpoint = '/performance-reviews';

    // Add query parameters
    List<String> queryParams = [];
    if (status != null) queryParams.add('status=$status');
    if (employeeId != null) queryParams.add('employeeId=$employeeId');

    if (queryParams.isNotEmpty) {
      endpoint += '?${queryParams.join('&')}';
    }

    final response = await apiService.get(endpoint);

    if (response.success && response.data is List) {
      return (response.data as List)
          .map((json) => PerformanceReview.fromJson(json))
          .toList();
    } else {
      throw Exception(
          'Failed to load performance reviews: ${response.message}');
    }
  }

  // Get a specific performance review
  Future<PerformanceReview> getPerformanceReview(String reviewId) async {
    final response = await apiService.get('/performance-reviews/$reviewId');

    if (response.success) {
      return PerformanceReview.fromJson(response.data);
    } else {
      throw Exception('Failed to load performance review: ${response.message}');
    }
  }

  // Create a new performance review
  Future<PerformanceReview> createPerformanceReview(
      Map<String, dynamic> reviewData) async {
    final response = await apiService.post('/performance-reviews', reviewData);

    if (response.success) {
      return PerformanceReview.fromJson(response.data);
    } else {
      throw Exception(
          'Failed to create performance review: ${response.message}');
    }
  }

  // Update a performance review
  Future<PerformanceReview> updatePerformanceReview(
      String reviewId, Map<String, dynamic> reviewData) async {
    final response =
        await apiService.put('/performance-reviews/$reviewId', reviewData);

    if (response.success) {
      return PerformanceReview.fromJson(response.data);
    } else {
      throw Exception(
          'Failed to update performance review: ${response.message}');
    }
  }

  // Delete a performance review
  Future<void> deletePerformanceReview(String reviewId) async {
    final response = await apiService.delete('/performance-reviews/$reviewId');

    if (!response.success) {
      throw Exception(
          'Failed to delete performance review: ${response.message}');
    }
  }

  // Submit a performance review (change status to in_progress)
  Future<PerformanceReview> submitPerformanceReview(String reviewId) async {
    final response =
        await apiService.post('/performance-reviews/$reviewId/submit', {});

    if (response.success) {
      return PerformanceReview.fromJson(response.data);
    } else {
      throw Exception(
          'Failed to submit performance review: ${response.message}');
    }
  }

  // Complete a performance review
  Future<PerformanceReview> completePerformanceReview(
      String reviewId, Map<String, dynamic> finalData) async {
    final response = await apiService.post(
        '/performance-reviews/$reviewId/complete', finalData);

    if (response.success) {
      return PerformanceReview.fromJson(response.data);
    } else {
      throw Exception(
          'Failed to complete performance review: ${response.message}');
    }
  }

  // Get performance review templates
  Future<List<Map<String, dynamic>>> getReviewTemplates() async {
    final response = await apiService.get('/performance-reviews/templates');

    if (response.success && response.data is List) {
      return List<Map<String, dynamic>>.from(response.data);
    } else {
      throw Exception('Failed to load review templates: ${response.message}');
    }
  }

  // Get performance statistics
  Future<Map<String, dynamic>> getPerformanceStatistics() async {
    final response = await apiService.get('/performance-reviews/statistics');

    if (response.success) {
      return Map<String, dynamic>.from(response.data);
    } else {
      throw Exception(
          'Failed to load performance statistics: ${response.message}');
    }
  }

  // Get employees eligible for performance review
  Future<List<Map<String, dynamic>>> getEligibleEmployees() async {
    final response =
        await apiService.get('/performance-reviews/eligible-employees');

    if (response.success && response.data is List) {
      return List<Map<String, dynamic>>.from(response.data);
    } else {
      throw Exception('Failed to load eligible employees: ${response.message}');
    }
  }
}
