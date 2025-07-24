import 'package:flutter/material.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationListItem extends StatelessWidget {
  final Map<String, dynamic> location;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;
  final VoidCallback? onAssign;
  final bool isSelected;

  const LocationListItem({
    Key? key,
    required this.location,
    this.onEdit,
    this.onDelete,
    this.onTap,
    this.onAssign,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final coordinates = location['coordinates'] ?? {};
    final address = location['address'] ?? {};
    final settings = location['settings'] ?? {};
    final contactInfo = location['contactInfo'] ?? {};

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isSelected
              ? [Colors.blue.shade50, Colors.indigo.shade50]
              : [Colors.white, Colors.grey.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? Colors.blue.shade300 : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? Colors.blue.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
            blurRadius: isSelected ? 15 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              // Main Card Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row with Status Badge and Action Icons
                    Row(
                      children: [
                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: location['status'] == 'active'
                                  ? [
                                      Colors.green.shade400,
                                      Colors.green.shade600
                                    ]
                                  : [
                                      Colors.grey.shade400,
                                      Colors.grey.shade600
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: (location['status'] == 'active'
                                        ? Colors.green
                                        : Colors.grey)
                                    .withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                location['status'] == 'active'
                                    ? Icons.check_circle_rounded
                                    : Icons.pause_circle_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                location['status']?.toUpperCase() ?? 'UNKNOWN',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Location Name and Icon
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.shade400,
                                Colors.indigo.shade400
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                location['name'] ?? 'Unnamed Location',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade800,
                                    ),
                              ),
                              if (address['city'] != null ||
                                  address['state'] != null)
                                Text(
                                  '${address['city'] ?? ''}${address['city'] != null && address['state'] != null ? ', ' : ''}${address['state'] ?? ''}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Location Details Grid
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailItem(
                            icon: Icons.radio_button_checked_rounded,
                            iconColor: Colors.green.shade600,
                            title: 'Geofence',
                            value: '${settings['geofenceRadius'] ?? 100}m',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDetailItem(
                            icon: Icons.people_rounded,
                            iconColor: Colors.purple.shade600,
                            title: 'Capacity',
                            value: '${settings['capacity'] ?? 0} people',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailItem(
                            icon: Icons.person_rounded,
                            iconColor: Colors.green.shade600,
                            title: 'Active Users',
                            value: '${location['activeUsers'] ?? 0} users',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDetailItem(
                            icon: Icons.access_time_rounded,
                            iconColor: Colors.orange.shade600,
                            title: 'Hours',
                            value:
                                '${settings['workingHours']?['start'] ?? '09:00'} - ${settings['workingHours']?['end'] ?? '17:00'}',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailItem(
                            icon: Icons.update_rounded,
                            iconColor: Colors.blue.shade600,
                            title: 'Updated',
                            value: _formatLastUpdated(location['updatedAt']),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(), // Empty container for spacing
                        ),
                      ],
                    ),

                    // Contact Info (if available)
                    if (contactInfo['email'] != null ||
                        contactInfo['phone'] != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.contact_mail_rounded,
                              color: Colors.grey.shade600,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                contactInfo['email'] ??
                                    contactInfo['phone'] ??
                                    '',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Action Buttons Section
              if (onAssign != null || onEdit != null || onDelete != null) ...[
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.grey.shade300,
                        Colors.transparent
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      if (onAssign != null) ...[
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.people_alt_rounded,
                            label: 'Assign',
                            color: Colors.teal.shade500,
                            onPressed: () => onAssign!(),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (onEdit != null) ...[
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.edit_rounded,
                            label: 'Edit',
                            color: Colors.indigo.shade500,
                            onPressed: () => onEdit!(),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (onDelete != null)
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.delete_rounded,
                            label: 'Delete',
                            color: Colors.orange.shade500,
                            onPressed: () => onDelete!(),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatLastUpdated(dynamic updatedAt) {
    if (updatedAt == null) return 'Unknown';

    try {
      final dateTime = DateTime.parse(updatedAt.toString());
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}
