import 'dart:io';
import 'dart:convert'; // Added missing import for json
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/api_config.dart';

/// Direct Download Service for Android APK Updates
///
/// This service handles:
/// - Downloading APK files directly from server
/// - Installing APK files on Android devices
/// - Managing download progress and status
/// - Handling permissions for APK installation
class DirectDownloadService {
  static const String _downloadEndpoint = '/app/download/android';
  static const String _downloadUrl =
      'https://your-server.com/downloads/sns-rooster.apk';

  /// Download APK file directly
  static Future<bool> downloadAndInstallApk({
    required String downloadUrl,
    required Function(double) onProgress,
    required Function(String) onError,
  }) async {
    try {
      // Check storage permission
      final storageStatus = await Permission.storage.request();
      if (!storageStatus.isGranted) {
        onError('Storage permission is required to download the update');
        return false;
      }

      // Get download directory
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        onError('Could not access storage directory');
        return false;
      }

      final apkPath = '${directory.path}/sns_rooster_update.apk';

      // Download APK file
      final response = await http.get(
        Uri.parse(downloadUrl),
        headers: {
          'User-Agent': 'SNS-Rooster-Update',
        },
      );

      if (response.statusCode != 200) {
        onError('Failed to download APK: ${response.statusCode}');
        return false;
      }

      // Save APK file
      final file = File(apkPath);
      await file.writeAsBytes(response.bodyBytes);

      // Install APK
      return await _installApk(apkPath, onError);
    } catch (e) {
      onError('Download failed: $e');
      return false;
    }
  }

  /// Install APK file
  static Future<bool> _installApk(
      String apkPath, Function(String) onError) async {
    try {
      // Check if file exists
      final file = File(apkPath);
      if (!await file.exists()) {
        onError('APK file not found');
        return false;
      }

      // Request install permission
      final installStatus = await Permission.requestInstallPackages.request();
      if (!installStatus.isGranted) {
        onError('Install permission is required');
        return false;
      }

      // Launch APK installer
      final uri = Uri.file(apkPath);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return true;
      } else {
        onError('Could not launch APK installer');
        return false;
      }
    } catch (e) {
      onError('Installation failed: $e');
      return false;
    }
  }

  /// Get download URL from server (prioritizes GitHub)
  static Future<String?> getDownloadUrl() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}$_downloadEndpoint'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Prioritize GitHub URL if available
        final downloadUrl = data['download_url'];
        if (downloadUrl != null && downloadUrl.contains('github.com')) {
          print('📱 Using GitHub download URL: $downloadUrl');
          return downloadUrl;
        }

        // Fallback to alternative downloads
        final alternativeDownloads = data['alternative_downloads'] as List?;
        if (alternativeDownloads != null && alternativeDownloads.isNotEmpty) {
          // Try GitHub first, then Play Store, then others
          for (final url in alternativeDownloads) {
            if (url.contains('github.com')) {
              print('📱 Using GitHub alternative URL: $url');
              return url;
            }
          }

          // If no GitHub, try Play Store
          for (final url in alternativeDownloads) {
            if (url.contains('play.google.com')) {
              print('📱 Using Play Store URL: $url');
              return url;
            }
          }

          // Use first available alternative
          print(
              '📱 Using alternative download URL: ${alternativeDownloads.first}');
          return alternativeDownloads.first;
        }

        return downloadUrl;
      }

      return null;
    } catch (e) {
      print('❌ Error getting download URL: $e');
      return null;
    }
  }

  /// Check if device supports APK installation
  static Future<bool> canInstallApk() async {
    if (!Platform.isAndroid) return false;

    final storageStatus = await Permission.storage.status;
    final installStatus = await Permission.requestInstallPackages.status;

    return storageStatus.isGranted && installStatus.isGranted;
  }

  /// Request necessary permissions
  static Future<bool> requestPermissions() async {
    if (!Platform.isAndroid) return false;

    final storageStatus = await Permission.storage.request();
    final installStatus = await Permission.requestInstallPackages.request();

    return storageStatus.isGranted && installStatus.isGranted;
  }
}

/// Direct Download Widget
class DirectDownloadWidget extends StatefulWidget {
  final String downloadUrl;
  final VoidCallback? onSuccess;
  final VoidCallback? onCancel;

  const DirectDownloadWidget({
    Key? key,
    required this.downloadUrl,
    this.onSuccess,
    this.onCancel,
  }) : super(key: key);

  @override
  State<DirectDownloadWidget> createState() => _DirectDownloadWidgetState();
}

class _DirectDownloadWidgetState extends State<DirectDownloadWidget> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: const Border(
          left: BorderSide(
            color: Colors.blue,
            width: 4,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                Icons.download,
                color: Colors.blue,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Direct APK Download',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
              if (widget.onCancel != null)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onCancel,
                  iconSize: 20,
                ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Download and install the latest version directly',
            style: TextStyle(fontSize: 14),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.red,
              ),
            ),
          ],
          if (_isDownloading) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.grey.shade300,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            const SizedBox(height: 8),
            Text(
              'Downloading... ${(_progress * 100).toInt()}%',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isDownloading ? null : _startDownload,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                      _isDownloading ? 'Downloading...' : 'Download & Install'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _progress = 0.0;
      _error = null;
    });

    try {
      // Request permissions first
      final hasPermissions = await DirectDownloadService.requestPermissions();
      if (!hasPermissions) {
        setState(() {
          _error = 'Storage and install permissions are required';
          _isDownloading = false;
        });
        return;
      }

      // Download and install APK
      final success = await DirectDownloadService.downloadAndInstallApk(
        downloadUrl: widget.downloadUrl,
        onProgress: (progress) {
          setState(() {
            _progress = progress;
          });
        },
        onError: (error) {
          setState(() {
            _error = error;
            _isDownloading = false;
          });
        },
      );

      if (success) {
        widget.onSuccess?.call();
      }
    } catch (e) {
      setState(() {
        _error = 'Download failed: $e';
        _isDownloading = false;
      });
    }
  }
}
