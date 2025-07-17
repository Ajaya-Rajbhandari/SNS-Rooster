import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart'; // Added import
import 'package:flutter/material.dart';
import '../config/api_config.dart';
import 'package:flutter_svg/flutter_svg.dart';

class UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final double radius;
  final VoidCallback? onTap; // Added onTap callback
  final String? userId; // Add userId for cache key

  const UserAvatar({
    super.key, // Changed to super.key
    this.avatarUrl,
    this.radius = 40, // Default radius to 40 as in original
    this.onTap,
    this.userId, // Add userId parameter
  });

  @override
  Widget build(BuildContext context) {
    Widget avatarChild;

    if (avatarUrl == null || avatarUrl!.isEmpty) {
      avatarChild = Icon(Icons.person, size: radius, color: Colors.grey[400]);
    } else if (avatarUrl!
        .contains('/opt/render/project/src/rooster-backend/uploads/avatars/')) {
      // Fix production server paths by extracting just the filename
      final filename = avatarUrl!.split('/').last;
      final baseUrlWithoutApi = ApiConfig.baseUrl.replaceAll('/api', '');
      final fixedUrl = '$baseUrlWithoutApi/uploads/avatars/$filename';
      avatarChild = CachedNetworkImage(
        imageUrl: fixedUrl,
        cacheKey: userId != null ? 'avatar_$userId' : null,
        placeholder: (context, url) => CircleAvatar(
          radius: radius,
          backgroundColor: Colors.grey[200],
          child: Icon(Icons.person, size: radius, color: Colors.grey[400]),
        ),
        errorWidget: (context, url, error) {
          print('AVATAR ERROR: Failed to load $url, error: $error');
          return CircleAvatar(
            radius: radius,
            backgroundColor: Colors.grey[200],
            child: Icon(Icons.person, size: radius, color: Colors.grey[400]),
          );
        },
        imageBuilder: (context, imageProvider) => CircleAvatar(
          radius: radius,
          backgroundImage: imageProvider,
        ),
      );
    } else if (avatarUrl!.endsWith('.svg') && avatarUrl!.startsWith('http')) {
      // SVG from network
      avatarChild = FutureBuilder<Widget>(
        future: _loadSvgOrFallback(avatarUrl!, radius),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData) {
            return snapshot.data!;
          } else {
            return CircleAvatar(
              radius: radius,
              backgroundColor: Colors.grey[200],
              child: Icon(Icons.person, size: radius, color: Colors.grey[400]),
            );
          }
        },
      );
    } else if (avatarUrl!.toLowerCase().startsWith('http') ||
        avatarUrl!.contains('://')) {
      // For full URLs (http/https), use directly
      avatarChild = CachedNetworkImage(
        imageUrl: avatarUrl!,
        cacheKey: userId != null ? 'avatar_$userId' : null,
        placeholder: (context, url) => CircleAvatar(
          radius: radius,
          backgroundColor: Colors.grey[200],
          child: Icon(Icons.person, size: radius, color: Colors.grey[400]),
        ),
        errorWidget: (context, url, error) {
          print('AVATAR ERROR: Failed to load $url, error: $error');
          return CircleAvatar(
            radius: radius,
            backgroundColor: Colors.grey[200],
            child: Icon(Icons.person, size: radius, color: Colors.grey[400]),
          );
        },
        imageBuilder: (context, imageProvider) => CircleAvatar(
          radius: radius,
          backgroundImage: imageProvider,
        ),
      );
    } else if (avatarUrl!.startsWith('/uploads/')) {
      // For static files, use base URL without /api prefix
      final baseUrlWithoutApi = ApiConfig.baseUrl.replaceAll('/api', '');
      final fullUrl = '$baseUrlWithoutApi$avatarUrl';
      avatarChild = CachedNetworkImage(
        imageUrl: fullUrl,
        cacheKey: userId != null ? 'avatar_$userId' : null,
        placeholder: (context, url) => CircleAvatar(
          radius: radius,
          backgroundColor: Colors.grey[200],
          child: Icon(Icons.person, size: radius, color: Colors.grey[400]),
        ),
        errorWidget: (context, url, error) => CircleAvatar(
          radius: radius,
          backgroundColor: Colors.grey[200],
          child: Icon(Icons.person, size: radius, color: Colors.grey[400]),
        ),
        imageBuilder: (context, imageProvider) => CircleAvatar(
          radius: radius,
          backgroundImage: imageProvider,
        ),
      );
    } else if (avatarUrl!.startsWith('file://')) {
      avatarChild = CircleAvatar(
        radius: radius,
        backgroundImage:
            FileImage(File(avatarUrl!.replaceFirst('file://', ''))),
      );
    } else {
      // For anything else, assume it's a relative path and add /uploads/avatars/
      // but first check if it's not already a full path to avoid double prefixes
      String finalUrl;
      final baseUrlWithoutApi = ApiConfig.baseUrl.replaceAll('/api', '');

      if (avatarUrl!.startsWith('/uploads/')) {
        finalUrl = '$baseUrlWithoutApi$avatarUrl';
      } else if (!avatarUrl!.startsWith('/')) {
        finalUrl = '$baseUrlWithoutApi/uploads/avatars/$avatarUrl';
      } else {
        finalUrl = '$baseUrlWithoutApi$avatarUrl';
      }

      try {
        avatarChild = CachedNetworkImage(
          imageUrl: finalUrl,
          cacheKey: userId != null ? 'avatar_$userId' : null,
          placeholder: (context, url) => CircleAvatar(
            radius: radius,
            backgroundColor: Colors.grey[200],
            child: Icon(Icons.person, size: radius, color: Colors.grey[400]),
          ),
          errorWidget: (context, url, error) {
            print('AVATAR ERROR: Failed to load $url, error: $error');
            return CircleAvatar(
              radius: radius,
              backgroundColor: Colors.grey[200],
              child: Icon(Icons.person, size: radius, color: Colors.grey[400]),
            );
          },
          imageBuilder: (context, imageProvider) => CircleAvatar(
            radius: radius,
            backgroundImage: imageProvider,
          ),
        );
      } catch (e) {
        print('AVATAR ERROR: Exception loading avatar: $e');
        avatarChild = CircleAvatar(
          radius: radius,
          backgroundColor: Colors.orange[100],
          child:
              Icon(Icons.broken_image, size: radius, color: Colors.orange[700]),
        );
      }
    }

    // Return a GestureDetector if onTap is provided, otherwise just the avatarChild in a CircleAvatar container
    // This structure ensures the circular shape and tap functionality.
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: Colors
            .transparent, // Important for CachedNetworkImage's CircleAvatar to show
        child: ClipOval(
          // Ensures the child (which might be rectangular from CachedNetworkImage) is clipped to a circle
          child: avatarChild,
        ),
      ),
    );
  }
}

Future<Widget> _loadSvgOrFallback(String url, double radius) async {
  try {
    return SvgPicture.network(
      url,
      width: radius * 2,
      height: radius * 2,
      fit: BoxFit.cover,
      placeholderBuilder: (context) => CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey[200],
        child: Icon(Icons.person, size: radius, color: Colors.grey[400]),
      ),
    );
  } catch (e) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[200],
      child: Icon(Icons.person, size: radius, color: Colors.grey[400]),
    );
  }
}
