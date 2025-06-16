import 'dart:io';
import 'package:flutter/material.dart';

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
    } else if (avatarUrl!.startsWith('/') || avatarUrl!.startsWith('file://')) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: FileImage(File(avatarUrl!)),
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
