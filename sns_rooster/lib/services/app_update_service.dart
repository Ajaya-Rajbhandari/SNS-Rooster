import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/api_config.dart';
import '../utils/global_navigator.dart';

/// App Update Service
///
/// This service handles:
/// - Checking for app updates
/// - Showing update alerts to users
/// - Directing users to download/update
/// - Managing update preferences
class AppUpdateService {
  static const String _updateCheckEndpoint = '/app/version/check';
  static const String _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.snstech.sns_rooster';
  static const String _webAppUrl = 'https://sns-rooster-8ccz5.web.app';
  static const String _directDownloadUrl =
      'https://sns-rooster.com/downloads/sns-rooster.apk';

  /// Check if app update is available
  static Future<AppUpdateInfo?> checkForUpdates({
    bool forceCheck = false,
    bool showAlert = true,
  }) async {
    // Skip update checks on web platform
    if (kIsWeb) {
      print('🌐 Skipping app update check on web platform');
      return null;
    }
    try {
      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final buildNumber = packageInfo.buildNumber;

      print('🔍 Checking for app updates...');
      print('📱 Current version: $currentVersion (build: $buildNumber)');

      // Check with backend for latest version
      final uri =
          Uri.parse('${ApiConfig.baseUrl}$_updateCheckEndpoint').replace(
        queryParameters: {
          'version': currentVersion,
          'build': buildNumber,
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'User-Agent':
              'SNS-Rooster/$currentVersion (${Platform.isAndroid ? 'Android' : Platform.isIOS ? 'iOS' : 'Web'})',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final latestVersion = data['latest_version'];
        final latestBuildNumber = data['latest_build_number'];
        final updateRequired = data['update_required'] ?? false;
        // Get platform-appropriate update message from backend
        final updateMessage =
            data['update_message'] ?? 'A new version is available';
        final downloadUrl = data['download_url'];

        print('🔄 Latest version: $latestVersion (build: $latestBuildNumber)');
        print('⚠️ Update required: $updateRequired');

        // Compare versions
        final hasUpdate = _compareVersions(
          currentVersion: currentVersion,
          currentBuild: buildNumber,
          latestVersion: latestVersion,
          latestBuild: latestBuildNumber,
        );

        if (hasUpdate) {
          final updateInfo = AppUpdateInfo(
            currentVersion: currentVersion,
            latestVersion: latestVersion,
            updateRequired: updateRequired,
            message: updateMessage,
            downloadUrl: downloadUrl,
          );

          if (showAlert) {
            _showUpdateAlert(updateInfo);
          }

          return updateInfo;
        } else {
          print('✅ App is up to date');
          return null;
        }
      } else {
        print('❌ Failed to check for updates: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error checking for updates: $e');
      return null;
    }
  }

  /// Compare version numbers
  static bool _compareVersions({
    required String currentVersion,
    required String currentBuild,
    required String latestVersion,
    required String latestBuild,
  }) {
    try {
      // Compare version strings (e.g., "1.0.0" vs "1.0.1")
      final currentParts = currentVersion.split('.').map(int.parse).toList();
      final latestParts = latestVersion.split('.').map(int.parse).toList();

      // Compare major.minor.patch
      for (int i = 0; i < 3; i++) {
        final current = i < currentParts.length ? currentParts[i] : 0;
        final latest = i < latestParts.length ? latestParts[i] : 0;

        if (latest > current) return true;
        if (latest < current) return false;
      }

      // If versions are equal, compare build numbers
      final currentBuildNum = int.tryParse(currentBuild) ?? 0;
      final latestBuildNum = int.tryParse(latestBuild) ?? 0;

      return latestBuildNum > currentBuildNum;
    } catch (e) {
      print('❌ Error comparing versions: $e');
      return false;
    }
  }

  /// Show update alert dialog
  static void _showUpdateAlert(AppUpdateInfo updateInfo) {
    // Use a global navigator key or context to show dialog
    // This will be called from the main app widget
    _showUpdateDialog(updateInfo);
  }

  /// Show update dialog (to be called from main app)
  static void _showUpdateDialog(AppUpdateInfo updateInfo) {
    // Use the global navigator key to show the dialog
    final context = GlobalNavigator.navigatorKey.currentContext;
    if (context != null) {
      showDialog(
        context: context,
        barrierDismissible: !updateInfo.updateRequired,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(
                updateInfo.updateRequired ? Icons.warning : Icons.info,
                color: updateInfo.updateRequired ? Colors.red : Colors.blue,
              ),
              const SizedBox(width: 8),
              Text(
                updateInfo.updateRequired
                    ? 'Critical Update Required'
                    : 'Update Available',
                style: TextStyle(
                  color: updateInfo.updateRequired ? Colors.red : Colors.blue,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(updateInfo.message),
              const SizedBox(height: 8),
              Text(
                'Current: ${updateInfo.currentVersion} → Latest: ${updateInfo.latestVersion}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 12),
              if (Platform.isAndroid) ...[
                const Text(
                  'Choose download method:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
          actions: [
            if (!updateInfo.updateRequired)
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Later'),
              ),
            if (Platform.isAndroid) ...[
              // GitHub Download Button
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
                  print('🔘 GitHub download clicked');
                  try {
                    await launchUpdateUrl(
                        'https://github.com/Ajaya-Rajbhandari/SNS-Rooster/releases/latest');
                  } catch (e) {
                    print('❌ Error in GitHub download: $e');
                  }
                },
                icon: const Icon(Icons.download),
                label: const Text('GitHub'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
              // Play Store Button
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
                  print('🔘 Play Store clicked');
                  try {
                    await launchUpdateUrl(
                        'https://play.google.com/store/apps/details?id=com.snstech.sns_rooster');
                  } catch (e) {
                    print('❌ Error in Play Store: $e');
                  }
                },
                icon: const Icon(Icons.store),
                label: const Text('Play Store'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ] else ...[
              // For non-Android platforms, use the original single button
              ElevatedButton(
                onPressed: () async {
                  print('🔘 Update button clicked');
                  print(
                      '📱 Platform: ${Platform.isAndroid ? 'Android' : 'Web'}');
                  print('🔗 Download URL: ${updateInfo.downloadUrl}');

                  Navigator.of(context).pop();

                  try {
                    await launchUpdateUrl(updateInfo.downloadUrl);
                  } catch (e) {
                    print('❌ Error in update button: $e');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      updateInfo.updateRequired ? Colors.red : Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child:
                    Text(updateInfo.updateRequired ? 'Update Now' : 'Update'),
              ),
            ],
          ],
        ),
      );
    }
  }

  /// Launch app store or download URL
  static Future<void> launchUpdateUrl(String? customUrl) async {
    try {
      final url = customUrl ?? _getDefaultUpdateUrl();
      final uri = Uri.parse(url);

      print('🔗 Attempting to launch update URL: $url');

      if (Platform.isAndroid) {
        // Handle different types of URLs
        if (url.contains('github.com')) {
          // For GitHub URLs, open the releases page instead of direct download
          final releasesUrl =
              'https://github.com/Ajaya-Rajbhandari/SNS-Rooster/releases/latest';
          final releasesUri = Uri.parse(releasesUrl);

          print('📱 Opening GitHub releases page: $releasesUrl');

          try {
            await launchUrl(releasesUri, mode: LaunchMode.externalApplication);
            print('✅ Opened GitHub releases page');
          } catch (e) {
            print('❌ Failed to open GitHub releases: $e');
            _showUrlFallbackDialog(releasesUrl);
          }
        } else if (url.contains('play.google.com')) {
          // For Play Store URLs, open directly
          try {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            print('✅ Opened Play Store');
          } catch (e) {
            print('❌ Failed to open Play Store: $e');
            _showUrlFallbackDialog(url);
          }
        } else {
          // For other URLs, try multiple approaches
          bool launched = false;

          // Method 1: Try external application (browser)
          try {
            print('🔍 Trying LaunchMode.externalApplication...');
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            print('✅ Launched update URL in external app: $url');
            launched = true;
          } catch (e) {
            print('⚠️ Failed to launch in external app: $e');
          }

          // Method 2: Try in-app webview if external failed
          if (!launched) {
            try {
              print('🔍 Trying LaunchMode.inAppWebView...');
              await launchUrl(uri, mode: LaunchMode.inAppWebView);
              print('✅ Launched update URL in in-app webview: $url');
              launched = true;
            } catch (e) {
              print('⚠️ Failed to launch in in-app webview: $e');
            }
          }

          // Method 3: Try platform default
          if (!launched) {
            try {
              print('🔍 Trying platform default...');
              await launchUrl(uri);
              print('✅ Launched update URL with platform default: $url');
              launched = true;
            } catch (e) {
              print('⚠️ Failed to launch with platform default: $e');
            }
          }

          if (!launched) {
            print('❌ All launch methods failed for URL: $url');
            _showUrlFallbackDialog(url);
          }
        }
      } else {
        // For web and other platforms
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          print('🔗 Launched update URL: $url');
        } else {
          print('❌ Could not launch URL: $url');
        }
      }
    } catch (e) {
      print('❌ Error launching update URL: $e');
      // Show fallback dialog
      _showUrlFallbackDialog(customUrl ?? _getDefaultUpdateUrl());
    }
  }

  /// Show fallback dialog with URL
  static void _showUrlFallbackDialog(String url) {
    final context = GlobalNavigator.navigatorKey.currentContext;
    if (context != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Update Download'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Unable to open download link automatically.'),
              const SizedBox(height: 8),
              const Text('Please copy this URL and open it in your browser:'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SelectableText(
                  url,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  /// Get default update URL based on platform
  static String _getDefaultUpdateUrl() {
    // For Android, use direct download instead of Play Store
    if (Platform.isAndroid) {
      return _directDownloadUrl;
    }
    // For other platforms, use Play Store
    return _playStoreUrl;
  }

  /// Schedule periodic update checks
  static void scheduleUpdateChecks() {
    // This can be called from app startup
    // Check for updates every 24 hours
    Future.delayed(const Duration(hours: 24), () {
      checkForUpdates(showAlert: true);
    });
  }

  /// Force update check (for manual refresh)
  static Future<void> forceUpdateCheck() async {
    await checkForUpdates(forceCheck: true, showAlert: true);
  }
}

/// App Update Information Model
class AppUpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final bool updateRequired;
  final String message;
  final String? downloadUrl;

  AppUpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.updateRequired,
    required this.message,
    this.downloadUrl,
  });

  bool get isCritical => updateRequired;
  bool get hasUpdate => currentVersion != latestVersion;

  @override
  String toString() {
    return 'AppUpdateInfo(current: $currentVersion, latest: $latestVersion, required: $updateRequired)';
  }
}

/// Update Alert Widget
class UpdateAlertWidget extends StatelessWidget {
  final AppUpdateInfo updateInfo;
  final VoidCallback? onUpdate;
  final VoidCallback? onDismiss;

  const UpdateAlertWidget({
    Key? key,
    required this.updateInfo,
    this.onUpdate,
    this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: updateInfo.isCritical ? Colors.red.shade50 : Colors.blue.shade50,
        border: Border(
          left: BorderSide(
            color: updateInfo.isCritical ? Colors.red : Colors.blue,
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
              Icon(
                updateInfo.isCritical ? Icons.warning : Icons.info,
                color: updateInfo.isCritical ? Colors.red : Colors.blue,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  updateInfo.isCritical
                      ? 'Critical Update Required'
                      : 'Update Available',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: updateInfo.isCritical ? Colors.red : Colors.blue,
                  ),
                ),
              ),
              if (!updateInfo.isCritical && onDismiss != null)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onDismiss,
                  iconSize: 20,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            updateInfo.message,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            'Current: ${updateInfo.currentVersion} → Latest: ${updateInfo.latestVersion}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onUpdate ??
                      () {
                        AppUpdateService.launchUpdateUrl(
                            updateInfo.downloadUrl);
                      },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        updateInfo.isCritical ? Colors.red : Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(updateInfo.isCritical ? 'Update Now' : 'Update'),
                ),
              ),
              if (updateInfo.isCritical) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    // For critical updates, you might want to exit the app
                    Navigator.of(context).pop();
                  },
                  child: const Text('Exit App'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
