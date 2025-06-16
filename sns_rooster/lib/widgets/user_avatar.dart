import 'dart:io';
import 'package:flutter/material.dart';
import '../config/api_config.dart';

class UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final double radius;

  const UserAvatar({Key? key, this.avatarUrl, this.radius = 40})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (avatarUrl == null || avatarUrl!.isEmpty) {
      return Container(
        width: radius * 2,
        height: radius * 2,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFE0E0E0),
        ),
        child: Icon(
          Icons.person,
          size: radius,
          color: const Color(0xFF9E9E9E),
        ),
      );
    } else if (avatarUrl!.startsWith('http')) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(avatarUrl!),
        onBackgroundImageError: (exception, stackTrace) {
          // Handle network image error
        },
      );
    } else if (avatarUrl!.startsWith('/uploads/')) {
      // Server URL - construct full URL for static files (without /api)
      final baseUrlWithoutApi = ApiConfig.baseUrl.replaceAll('/api', '');
      final fullUrl = '$baseUrlWithoutApi${avatarUrl!}';
      print('UserAvatar: Loading image from: $fullUrl');
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(fullUrl),
        onBackgroundImageError: (exception, stackTrace) {
          print('UserAvatar: Failed to load image from $fullUrl');
          print('UserAvatar: Error: $exception');
          print('UserAvatar: Stack trace: $stackTrace');
          // Optionally, you could return a placeholder widget here if the image fails to load
          // For example:
          // return Container(
          //   width: radius * 2,
          //   height: radius * 2,
          //   decoration: const BoxDecoration(
          //     shape: BoxShape.circle,
          //     color: Color(0xFFE0E0E0),
          //   ),
          //   child: Icon(
          //     Icons.person,
          //     size: radius,
          //     color: const Color(0xFF9E9E9E),
          //   ),
          // );
        },
        // Removed the child property here as CircleAvatar with backgroundImage doesn't typically use it.
        // The placeholder logic should be handled in onBackgroundImageError or by returning a different widget.
      );
    } else if (avatarUrl!.startsWith('file://')) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: FileImage(File(avatarUrl!.replaceFirst('file://', ''))),
        onBackgroundImageError: (exception, stackTrace) {
          // Handle file image error
        },
      );
    } else {
      return CircleAvatar(
        radius: radius,
        backgroundImage: AssetImage(avatarUrl!),
        onBackgroundImageError: (exception, stackTrace) {
          // Handle asset image error
        },
      );
    }
  }
}
