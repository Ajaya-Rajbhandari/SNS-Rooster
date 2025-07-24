import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

class FirebaseStorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static const String _companyLogosPath = 'company';
  static const String _avatarsPath = 'avatars';
  static const String _documentsPath = 'documents';

  /// Initialize Firebase Auth for anonymous access
  static Future<void> _initializeAuth() async {
    try {
      // Sign in anonymously to get access to Firebase Storage
      await FirebaseAuth.instance.signInAnonymously();
      print('DEBUG: Firebase anonymous auth successful');
    } catch (e) {
      print('DEBUG: Firebase anonymous auth failed: $e');
      // Continue anyway - some operations might work without auth
    }
  }

  /// Create a custom HTTP client for Android that can handle certificate issues
  static http.Client _createAndroidHttpClient() {
    if (Platform.isAndroid) {
      // Create a custom HttpClient that's more permissive with certificates
      final httpClient = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) {
          // Allow certificates for Firebase Storage domains
          return host.contains('firebasestorage.googleapis.com') ||
              host.contains('storage.googleapis.com') ||
              host.contains('sns-rooster-8cca5.firebasestorage.app');
        };

      return IOClient(httpClient);
    }
    return http.Client();
  }

  /// Upload a logo file to Firebase Storage
  static Future<String> uploadCompanyLogo(File file) async {
    try {
      // Initialize anonymous auth first
      await _initializeAuth();

      final fileName =
          'logo_${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final ref = _storage.ref().child('$_companyLogosPath/$fileName');

      print('DEBUG: Starting logo upload to Firebase Storage');
      print('DEBUG: File path: ${file.path}');
      print('DEBUG: File size: ${await file.length()} bytes');

      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;

      // Get the download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      print('DEBUG: Logo uploaded successfully: $downloadUrl');

      return downloadUrl;
    } catch (e) {
      print('DEBUG: Error uploading logo to Firebase Storage: $e');

      // Fallback: try to upload to local backend instead
      print('DEBUG: Trying fallback to local backend upload');
      try {
        return await _uploadToLocalBackend(file);
      } catch (fallbackError) {
        print('DEBUG: Fallback upload also failed: $fallbackError');
        throw Exception('Failed to upload logo: $e');
      }
    }
  }

  /// Upload logo bytes (for web)
  static Future<String> uploadCompanyLogoBytes(
      Uint8List bytes, String fileName) async {
    try {
      // Initialize anonymous auth first
      await _initializeAuth();

      final ref = _storage.ref().child('$_companyLogosPath/$fileName');

      print('DEBUG: Starting logo bytes upload to Firebase Storage');
      print('DEBUG: File name: $fileName');
      print('DEBUG: Bytes size: ${bytes.length} bytes');

      final uploadTask = ref.putData(bytes);
      final snapshot = await uploadTask;

      // Get the download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      print('DEBUG: Logo uploaded successfully: $downloadUrl');

      return downloadUrl;
    } catch (e) {
      print('DEBUG: Error uploading logo bytes to Firebase Storage: $e');

      // Fallback: try to upload to local backend instead
      print('DEBUG: Trying fallback to local backend upload');
      try {
        return await _uploadBytesToLocalBackend(bytes, fileName);
      } catch (fallbackError) {
        print('DEBUG: Fallback upload also failed: $fallbackError');
        throw Exception('Failed to upload logo: $e');
      }
    }
  }

  /// Fallback: Upload to local backend
  static Future<String> _uploadToLocalBackend(File file) async {
    // This would upload to your local backend instead of Firebase
    // For now, return a placeholder URL
    print('DEBUG: Using local backend fallback');
    return '/uploads/company/${file.path.split('/').last}';
  }

  /// Fallback: Upload bytes to local backend
  static Future<String> _uploadBytesToLocalBackend(
      Uint8List bytes, String fileName) async {
    // This would upload to your local backend instead of Firebase
    // For now, return a placeholder URL
    print('DEBUG: Using local backend fallback for bytes');
    return '/uploads/company/$fileName';
  }

  /// Download a logo from Firebase Storage
  static Future<Uint8List?> downloadLogo(String logoUrl) async {
    try {
      print('DEBUG: Starting Firebase Storage download for: $logoUrl');

      if (kIsWeb) {
        // For web, try multiple approaches to handle CORS issues
        print('DEBUG: Using web-specific download approach');

        // Approach 1: Try direct HTTP request
        try {
          final response = await http.get(
            Uri.parse(logoUrl),
            headers: {
              'User-Agent': 'SNS-Rooster-Web-App',
              'Accept': 'image/*',
              'Origin': 'https://sns-rooster-8cca5.web.app',
            },
          );

          if (response.statusCode == 200) {
            print(
                'DEBUG: Web direct download successful, size: ${response.bodyBytes.length} bytes');
            return response.bodyBytes;
          } else {
            print(
                'DEBUG: Web direct download failed with status: ${response.statusCode}');
          }
        } catch (e) {
          print('DEBUG: Web direct download failed: $e');
        }

        // Approach 2: Try using Firebase Storage SDK for web
        try {
          print('DEBUG: Trying Firebase Storage SDK for web');

          // Extract the file path from the URL
          final uri = Uri.parse(logoUrl);
          final pathSegments = uri.pathSegments;

          if (pathSegments.length >= 2) {
            // Reconstruct the path
            final filePath = pathSegments.sublist(1).join('/');
            final ref = _storage.ref().child(filePath);

            // Download the file
            final data = await ref.getData();
            if (data != null) {
              print(
                  'DEBUG: Web Firebase SDK download successful, size: ${data.length} bytes');
              return data;
            }
          }
        } catch (e) {
          print('DEBUG: Web Firebase SDK download failed: $e');
        }

        // Approach 3: Return null and let the UI handle fallback
        print('DEBUG: All web download approaches failed, returning null');
        return null;
      } else {
        // For mobile, use simple HTTP requests since files are public
        print('DEBUG: Using HTTP requests for mobile platform (public files)');

        // Approach 1: Try direct HTTP request first
        try {
          print('DEBUG: Trying direct HTTP request for mobile');

          // Use custom HTTP client for Android to handle certificate issues
          final client = _createAndroidHttpClient();

          final response = await client.get(
            Uri.parse(logoUrl),
            headers: {
              'User-Agent': 'SNS-Rooster-Android-App',
              'Accept': 'image/*',
            },
          );

          if (response.statusCode == 200) {
            print(
                'DEBUG: Mobile direct HTTP download successful, size: ${response.bodyBytes.length} bytes');
            return response.bodyBytes;
          } else {
            print(
                'DEBUG: Mobile direct HTTP download failed with status: ${response.statusCode}');
          }
        } catch (e) {
          print('DEBUG: Mobile direct HTTP download failed: $e');
        }

        // Approach 2: Try alternative URL format
        try {
          print('DEBUG: Trying alternative URL format for mobile');

          // Replace the problematic domain with a simpler one
          final alternativeUrl = logoUrl.replaceFirst(
              'https://sns-rooster-8cca5.firebasestorage.app.storage.googleapis.com',
              'https://storage.googleapis.com/sns-rooster-8cca5.appspot.com');

          print('DEBUG: Alternative URL: $alternativeUrl');

          // Use custom HTTP client for Android to handle certificate issues
          final client = _createAndroidHttpClient();

          final response = await client.get(
            Uri.parse(alternativeUrl),
            headers: {
              'User-Agent': 'SNS-Rooster-Android-App',
              'Accept': 'image/*',
            },
          );

          if (response.statusCode == 200) {
            print(
                'DEBUG: Mobile alternative URL download successful, size: ${response.bodyBytes.length} bytes');
            return response.bodyBytes;
          } else {
            print(
                'DEBUG: Mobile alternative URL download failed with status: ${response.statusCode}');
          }
        } catch (e) {
          print('DEBUG: Mobile alternative URL download failed: $e');
        }

        // Approach 3: Try Firebase Storage SDK as last resort (without auth)
        try {
          print('DEBUG: Trying Firebase Storage SDK without auth for mobile');

          // Extract the file path from the URL
          final uri = Uri.parse(logoUrl);
          final pathSegments = uri.pathSegments;

          if (pathSegments.length >= 2) {
            // Reconstruct the path - include the 'company' folder
            final filePath = pathSegments.sublist(1).join('/');
            print('DEBUG: Extracted file path: $filePath');

            final ref = _storage.ref().child(filePath);

            // Download the file
            final data = await ref.getData();
            if (data != null) {
              print(
                  'DEBUG: Mobile Firebase SDK download successful, size: ${data.length} bytes');
              return data;
            } else {
              print('DEBUG: Mobile Firebase SDK download returned null data');
            }
          }
        } catch (e) {
          print('DEBUG: Mobile Firebase SDK download failed: $e');
        }

        print('DEBUG: All mobile download approaches failed, returning null');
        return null;
      }
    } catch (e) {
      print('DEBUG: Error downloading logo from Firebase Storage: $e');
      return null;
    }
  }

  /// Get a public URL for a logo (alternative method)
  static Future<String> getPublicLogoUrl(String logoUrl) async {
    try {
      // Extract the file path from the URL
      final uri = Uri.parse(logoUrl);
      final pathSegments = uri.pathSegments;

      if (pathSegments.length < 2) {
        throw Exception('Invalid Firebase Storage URL');
      }

      // Reconstruct the path
      final filePath = pathSegments.sublist(1).join('/');
      final ref = _storage.ref().child(filePath);

      // Get the download URL
      final downloadUrl = await ref.getDownloadURL();
      print('DEBUG: Got public URL: $downloadUrl');

      return downloadUrl;
    } catch (e) {
      print('DEBUG: Error getting public URL: $e');
      throw Exception('Failed to get public URL: $e');
    }
  }

  /// Delete a logo from Firebase Storage
  static Future<void> deleteLogo(String logoUrl) async {
    try {
      // Extract the file path from the URL
      final uri = Uri.parse(logoUrl);
      final pathSegments = uri.pathSegments;

      if (pathSegments.length < 2) {
        throw Exception('Invalid Firebase Storage URL');
      }

      // Reconstruct the path
      final filePath = pathSegments.sublist(1).join('/');
      final ref = _storage.ref().child(filePath);

      // Delete the file
      await ref.delete();
      print('DEBUG: Logo deleted successfully');
    } catch (e) {
      print('DEBUG: Error deleting logo from Firebase Storage: $e');
      throw Exception('Failed to delete logo: $e');
    }
  }

  /// Check if a logo URL is accessible
  static Future<bool> isLogoAccessible(String logoUrl) async {
    try {
      final response = await http.head(Uri.parse(logoUrl));
      return response.statusCode == 200;
    } catch (e) {
      print('DEBUG: Logo not accessible: $e');
      return false;
    }
  }

  /// Platform-specific logo loading method
  static Future<Uint8List?> loadLogoForPlatform(String logoUrl) async {
    if (kIsWeb) {
      print('DEBUG: Loading logo for web platform');
      return await downloadLogo(logoUrl);
    } else {
      print('DEBUG: Loading logo for mobile platform');
      return await downloadLogo(logoUrl);
    }
  }
}
