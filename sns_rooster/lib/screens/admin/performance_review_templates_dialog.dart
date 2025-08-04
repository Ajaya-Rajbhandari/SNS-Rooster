import 'package:flutter/material.dart';
import 'package:sns_rooster/services/performance_review_template_service.dart';
import 'package:sns_rooster/services/api_service.dart';
import 'package:sns_rooster/config/api_config.dart';
import 'package:sns_rooster/utils/logger.dart';

class PerformanceReviewTemplatesDialog extends StatefulWidget {
  const PerformanceReviewTemplatesDialog({Key? key}) : super(key: key);

  @override
  State<PerformanceReviewTemplatesDialog> createState() =>
      _PerformanceReviewTemplatesDialogState();
}

class _PerformanceReviewTemplatesDialogState
    extends State<PerformanceReviewTemplatesDialog> {
  final PerformanceReviewTemplateService _templateService =
      PerformanceReviewTemplateService(ApiService(baseUrl: ApiConfig.baseUrl));
  List<Map<String, dynamic>> _templates = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final templates = await _templateService.getTemplates();
      setState(() {
        _templates = templates;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      Logger.error('Error loading templates: $e');
    }
  }

  void _showTemplateDetails(Map<String, dynamic> template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(template['name'] ?? 'Template'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                template['description'] ?? 'No description',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              if (template['categories'] != null) ...[
                const Text(
                  'Categories:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                ...(template['categories'] as List).map((category) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '• ${category['name']}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          if (category['description'] != null)
                            Text(
                              '  ${category['description']}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                        ],
                      ),
                    )),
                const SizedBox(height: 16),
              ],
              if (template['goals'] != null &&
                  (template['goals'] as List).isNotEmpty) ...[
                const Text(
                  'Sample Goals:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                ...(template['goals'] as List)
                    .take(3)
                    .map((goal) => Text('• $goal')),
                const SizedBox(height: 16),
              ],
              if (template['isDefault'] == true)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Default Template',
                    style: TextStyle(color: Colors.blue, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (template['isDefault'] != true)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _duplicateTemplate(template);
              },
              child: const Text('Duplicate'),
            ),
        ],
      ),
    );
  }

  Future<void> _duplicateTemplate(Map<String, dynamic> template) async {
    try {
      final nameController =
          TextEditingController(text: '${template['name']} (Copy)');
      final descriptionController =
          TextEditingController(text: template['description']);

      final result = await showDialog<Map<String, String>>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Duplicate Template'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Template Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop({
                'name': nameController.text,
                'description': descriptionController.text,
              }),
              child: const Text('Duplicate'),
            ),
          ],
        ),
      );

      if (result != null) {
        await _templateService.duplicateTemplate(
          template['_id'],
          name: result['name'],
          description: result['description'],
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Template duplicated successfully')),
          );
          _loadTemplates();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error duplicating template: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Performance Review Templates',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading templates',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadTemplates,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: _templates.isEmpty
                    ? const Center(
                        child: Text(
                          'No templates available',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _templates.length,
                        itemBuilder: (context, index) {
                          final template = _templates[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Icon(
                                template['isDefault'] == true
                                    ? Icons.star
                                    : Icons.description,
                                color: template['isDefault'] == true
                                    ? Colors.amber
                                    : Colors.blue,
                              ),
                              title:
                                  Text(template['name'] ?? 'Unnamed Template'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(template['description'] ??
                                      'No description'),
                                  if (template['isDefault'] == true)
                                    const Text(
                                      'Default Template',
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  switch (value) {
                                    case 'view':
                                      _showTemplateDetails(template);
                                      break;
                                    case 'duplicate':
                                      if (template['isDefault'] != true) {
                                        _duplicateTemplate(template);
                                      }
                                      break;
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'view',
                                    child: Row(
                                      children: [
                                        Icon(Icons.visibility),
                                        SizedBox(width: 8),
                                        Text('View Details'),
                                      ],
                                    ),
                                  ),
                                  if (template['isDefault'] != true)
                                    const PopupMenuItem(
                                      value: 'duplicate',
                                      child: Row(
                                        children: [
                                          Icon(Icons.copy),
                                          SizedBox(width: 8),
                                          Text('Duplicate'),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              onTap: () => _showTemplateDetails(template),
                            ),
                          );
                        },
                      ),
              ),
          ],
        ),
      ),
    );
  }
}
