import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/profile_provider.dart';
import '../../config/api_config.dart';

class UserInfoHeader extends StatelessWidget {
  final VoidCallback onNotificationTap;

  const UserInfoHeader({
    super.key,
    required this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);
    final profile = profileProvider.profile;

    return Row(
      children: [
        CircleAvatar(
          backgroundImage: profile != null && profile['avatar'] != null
              ? (profile['avatar'].toString().contains(
                      '/opt/render/project/src/rooster-backend/uploads/avatars/'))
                  ? NetworkImage(
                      '${ApiConfig.baseUrl.replaceAll('/api', '')}/uploads/avatars/${profile['avatar'].toString().split('/').last}')
                  : (profile['avatar'].toString().startsWith('http') ||
                          profile['avatar'].toString().contains('://'))
                      ? NetworkImage(profile['avatar'])
                      : NetworkImage(
                          '${ApiConfig.baseUrl.replaceAll('/api', '')}${profile['avatar'].toString().startsWith('/') ? '' : '/'}${profile['avatar']}')
              : const AssetImage('assets/images/default_avatar.png')
                  as ImageProvider,
          radius: 28,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile != null
                    ? 'Welcome Back, ${profile['name']}'
                    : 'Welcome Back',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                profile != null ? profile['role'] ?? '' : '',
                style: Theme.of(context).textTheme.bodySmall,
              ),
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
