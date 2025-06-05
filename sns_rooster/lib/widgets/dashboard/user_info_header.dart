import 'package:flutter/material.dart';

class UserInfoHeader extends StatelessWidget {
  final String userName;
  final String userRole;
  final String userAvatar;
  final VoidCallback onNotificationTap;

  const UserInfoHeader({
    super.key,
    required this.userName,
    required this.userRole,
    required this.userAvatar,
    required this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          backgroundImage: AssetImage(userAvatar),
          radius: 28,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome Back, $userName', style: Theme.of(context).textTheme.titleMedium),
              Text(userRole, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.notifications_none, color: Colors.black54),
          onPressed: onNotificationTap,
        ),
      ],
    );
  }
}
