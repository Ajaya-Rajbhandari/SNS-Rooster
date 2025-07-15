import 'package:flutter/material.dart';
import '../config/api_config.dart';
import 'dart:developer';

class AvatarHelper {
  /// Returns the appropriate URL for an avatar based on whether it's remote or local
  static String getAvatarUrl(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.trim().isEmpty) {
      return ''; // Return empty string to trigger error handler
    }
    
    final trimmedUrl = avatarUrl.trim();
    
    // If it's a remote URL, return as is
    if (trimmedUrl.toLowerCase().startsWith('http') || 
        trimmedUrl.contains('://')) {
      return trimmedUrl;
    }
    
    // Otherwise, it's a local file
    return '${ApiConfig.baseUrl}/uploads/avatars/$trimmedUrl';
  }

  /// Creates a CircleAvatar widget with proper error handling
  static Widget buildAvatar(String? avatarUrl, {double radius = 20}) {
    final defaultAvatar = CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[300],
      child: Icon(Icons.person, size: radius * 1.2, color: Colors.grey[600]),
    );
    
    if (avatarUrl == null || avatarUrl.trim().isEmpty) {
      return defaultAvatar;
    }
    
    try {
      final url = getAvatarUrl(avatarUrl);
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(url),
        onBackgroundImageError: (exception, stackTrace) {
          log('Avatar load error: $exception for URL: $url');
        },
      );
    } catch (e) {
      log('Avatar creation error: $e');
      return defaultAvatar;
    }
  }
}
