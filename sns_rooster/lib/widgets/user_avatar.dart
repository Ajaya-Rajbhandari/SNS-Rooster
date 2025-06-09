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
      return CircleAvatar(
        radius: radius,
        backgroundImage: AssetImage('assets/images/profile_placeholder.png'),
      );
    } else if (avatarUrl!.startsWith('http')) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(avatarUrl!),
      );
    } else if (avatarUrl!.startsWith('/') || avatarUrl!.startsWith('file://')) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: FileImage(File(avatarUrl!)),
      );
    } else {
      return CircleAvatar(
        radius: radius,
        backgroundImage: AssetImage(avatarUrl!),
      );
    }
  }
}
