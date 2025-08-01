// Web-specific export functionality
// This file is only imported on web platforms

import 'dart:convert';
import 'dart:html' as html;

void exportForWebImpl(String jsonString) {
  final bytes = utf8.encode(jsonString);
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download',
        'location_data_${DateTime.now().millisecondsSinceEpoch}.json')
    ..click();
  html.Url.revokeObjectUrl(url);
}
