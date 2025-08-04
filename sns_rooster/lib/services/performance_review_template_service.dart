import 'package:sns_rooster/services/api_service.dart';
import 'package:sns_rooster/utils/logger.dart';

class PerformanceReviewTemplateService {
  final ApiService apiService;

  PerformanceReviewTemplateService(this.apiService);

  // Get all templates
  Future<List<Map<String, dynamic>>> getTemplates() async {
    try {
      final response = await apiService.get('/performance-review-templates');

      if (response.success) {
        return List<Map<String, dynamic>>.from(response.data);
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      Logger.error('Error fetching templates: $e');
      rethrow;
    }
  }

  // Get a specific template
  Future<Map<String, dynamic>> getTemplate(String templateId) async {
    try {
      final response =
          await apiService.get('/performance-review-templates/$templateId');

      if (response.success) {
        return response.data;
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      Logger.error('Error fetching template: $e');
      rethrow;
    }
  }

  // Create a new template
  Future<Map<String, dynamic>> createTemplate(
      Map<String, dynamic> templateData) async {
    try {
      final response =
          await apiService.post('/performance-review-templates', templateData);

      if (response.success) {
        return response.data;
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      Logger.error('Error creating template: $e');
      rethrow;
    }
  }

  // Update a template
  Future<Map<String, dynamic>> updateTemplate(
      String templateId, Map<String, dynamic> templateData) async {
    try {
      final response = await apiService.put(
          '/performance-review-templates/$templateId', templateData);

      if (response.success) {
        return response.data;
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      Logger.error('Error updating template: $e');
      rethrow;
    }
  }

  // Delete a template
  Future<void> deleteTemplate(String templateId) async {
    try {
      final response =
          await apiService.delete('/performance-review-templates/$templateId');

      if (!response.success) {
        throw Exception(response.message);
      }
    } catch (e) {
      Logger.error('Error deleting template: $e');
      rethrow;
    }
  }

  // Duplicate a template
  Future<Map<String, dynamic>> duplicateTemplate(String templateId,
      {String? name, String? description}) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (description != null) data['description'] = description;

      final response = await apiService.post(
          '/performance-review-templates/$templateId/duplicate', data);

      if (response.success) {
        return response.data;
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      Logger.error('Error duplicating template: $e');
      rethrow;
    }
  }
}
