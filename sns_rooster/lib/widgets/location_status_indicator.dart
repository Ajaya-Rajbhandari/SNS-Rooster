import 'package:flutter/material.dart';

class LocationStatusIndicator extends StatelessWidget {
  final bool hasLocationFeature;
  final String? locationName;
  final double? distance;
  final int? geofenceRadius;
  final bool isLoading;
  final VoidCallback? onRefresh;

  const LocationStatusIndicator({
    Key? key,
    required this.hasLocationFeature,
    this.locationName,
    this.distance,
    this.geofenceRadius,
    this.isLoading = false,
    this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingIndicator();
    }

    if (!hasLocationFeature) {
      return _buildDisabledIndicator();
    }

    if (distance == null || geofenceRadius == null) {
      return _buildUnknownIndicator();
    }

    final isWithinRange = distance! <= geofenceRadius!;
    return _buildLocationIndicator(isWithinRange);
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Checking your location...',
              style: TextStyle(
                color: Colors.blue.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisabledIndicator() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_off,
            color: Colors.orange.shade600,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Location validation is not available in your current plan. You can check in/out from anywhere.',
              style: TextStyle(
                color: Colors.orange.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnknownIndicator() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on_outlined,
            color: Colors.grey.shade600,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Location status unknown. Please try checking in to verify your location.',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onRefresh != null)
            IconButton(
              onPressed: onRefresh,
              icon: Icon(
                Icons.refresh,
                color: Colors.grey.shade600,
                size: 16,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildLocationIndicator(bool isWithinRange) {
    final color = isWithinRange ? Colors.green : Colors.red;
    final icon = isWithinRange ? Icons.location_on : Icons.location_off;

    String message;
    if (isWithinRange) {
      message =
          'You are at your workplace ($locationName). You can check in/out.';
    } else {
      final distanceText = distance! >= 1000
          ? '${(distance! / 1000).toStringAsFixed(1)}km'
          : '${distance!.round()}m';
      final geofenceText = geofenceRadius! >= 1000
          ? '${(geofenceRadius! / 1000).toStringAsFixed(1)}km'
          : '${geofenceRadius!}m';

      if (distance! < 500) {
        message =
            'You\'re $distanceText away from $locationName. Please move closer (within $geofenceText) to check in.';
      } else if (distance! < 5000) {
        message =
            'You\'re $distanceText away from $locationName. Please travel to your workplace to check in.';
      } else {
        message =
            'You\'re too far from $locationName ($distanceText away). Please ensure you\'re at your workplace to check in.';
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.shade200),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color.shade600,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onRefresh != null)
            IconButton(
              onPressed: onRefresh,
              icon: Icon(
                Icons.refresh,
                color: color.shade600,
                size: 16,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}
