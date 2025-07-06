import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart'; // Added import
import 'package:flutter/material.dart';
import '../config/api_config.dart';
import 'package:flutter_svg/flutter_svg.dart';

class UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final double radius;
  final VoidCallback? onTap; // Added onTap callback

  const UserAvatar({
    super.key, // Changed to super.key
    this.avatarUrl,
    this.radius = 40, // Default radius to 40 as in original
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget avatarChild;

    if (avatarUrl == null || avatarUrl!.isEmpty) {
      avatarChild = Icon(Icons.person, size: radius, color: Colors.grey[400]);
    } else if (avatarUrl!.startsWith('http')) {
      avatarChild = CachedNetworkImage(
        imageUrl: avatarUrl!,
        placeholder: (context, url) => CircleAvatar(
          radius: radius,
          backgroundColor: Colors.grey[200],
          child: Icon(Icons.person, size: radius, color: Colors.grey[400]),
        ),
        errorWidget: (context, url, error) => CircleAvatar(
          radius: radius,
          backgroundColor: Colors.grey[200],
          child: SvgPicture.asset(
            'assets/images/default-avatar.png',
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
          ),
        ),
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
      // Assume it's an asset path
      try {
        avatarChild = CircleAvatar(
          radius: radius,
          backgroundImage: AssetImage(avatarUrl!),
        );
      } catch (e) {
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
