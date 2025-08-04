import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math' show pi, cos;

class EmployeeLocationMapWidget extends StatefulWidget {
  final Map<String, dynamic> location;
  final double height;
  final bool showGeofence;

  const EmployeeLocationMapWidget({
    Key? key,
    required this.location,
    this.height = 200,
    this.showGeofence = true,
  }) : super(key: key);

  @override
  State<EmployeeLocationMapWidget> createState() =>
      _EmployeeLocationMapWidgetState();
}

class _EmployeeLocationMapWidgetState extends State<EmployeeLocationMapWidget> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Circle> _circles = {};
  LatLng? _centerLocation;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  void _initializeMap() {
    // Get location coordinates
    final coords = widget.location['coordinates'];
    if (coords != null &&
        coords['latitude'] != null &&
        coords['longitude'] != null) {
      _centerLocation = LatLng(
        coords['latitude'].toDouble(),
        coords['longitude'].toDouble(),
      );
    } else {
      // Default location if coordinates are not available
      _centerLocation = const LatLng(-33.8688, 151.2093);
    }

    // Create marker for the work location
    _markers.add(
      Marker(
        markerId: const MarkerId('work_location'),
        position: _centerLocation!,
        infoWindow: InfoWindow(
          title: widget.location['name'] ?? 'Work Location',
          snippet: _getLocationAddress(widget.location),
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );

    // Create geofence circle if enabled
    if (widget.showGeofence) {
      final geofenceRadius =
          widget.location['settings']?['geofenceRadius']?.toDouble() ?? 100.0;
      _circles.add(
        Circle(
          circleId: const CircleId('geofence'),
          center: _centerLocation!,
          radius: geofenceRadius,
          fillColor: Colors.blue.withValues(alpha: 0.2),
          strokeColor: Colors.blue,
          strokeWidth: 2,
        ),
      );
    }
  }

  String _getLocationAddress(Map<String, dynamic> location) {
    final address = location['address'];
    if (address == null) return 'No address available';

    final parts = <String>[];

    // Add street address if available
    if (address['street']?.isNotEmpty == true) {
      parts.add(address['street']);
    }

    // Add city if available
    if (address['city']?.isNotEmpty == true) {
      parts.add(address['city']);
    }

    // Add state/province if available
    if (address['state']?.isNotEmpty == true) {
      parts.add(address['state']);
    }

    // Add country if available
    if (address['country']?.isNotEmpty == true) {
      parts.add(address['country']);
    }

    // Add postal code if available
    if (address['postalCode']?.isNotEmpty == true) {
      parts.add(address['postalCode']);
    }

    // If no structured address, try to use the full address string
    if (parts.isEmpty && address['fullAddress']?.isNotEmpty == true) {
      return address['fullAddress'];
    }

    // If still empty, try to construct from coordinates
    if (parts.isEmpty) {
      final coords = location['coordinates'];
      if (coords != null &&
          coords['latitude'] != null &&
          coords['longitude'] != null) {
        return '${coords['latitude'].toStringAsFixed(6)}, ${coords['longitude'].toStringAsFixed(6)}';
      }
    }

    return parts.isEmpty ? 'No address available' : parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // For web, try to use real Google Maps first, fallback if needed
      try {
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                GoogleMap(
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                    // Fit bounds to show the location and geofence
                    _fitBounds();
                  },
                  initialCameraPosition: CameraPosition(
                    target: _centerLocation!,
                    zoom: 15.0, // Closer zoom for better detail
                  ),
                  markers: _markers,
                  circles: _circles,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: false, // Hide default zoom controls
                  mapToolbarEnabled: false, // Hide map toolbar
                  compassEnabled: true,
                  onTap: (_) {
                    // Handle map tap if needed
                  },
                ),
                // Custom zoom controls
                Positioned(
                  right: 16,
                  top: 16,
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.add, size: 20),
                              onPressed: () {
                                _mapController?.animateCamera(
                                  CameraUpdate.zoomIn(),
                                );
                              },
                              tooltip: 'Zoom In',
                            ),
                            Container(
                              height: 1,
                              color: Colors.grey.shade300,
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove, size: 20),
                              onPressed: () {
                                _mapController?.animateCamera(
                                  CameraUpdate.zoomOut(),
                                );
                              },
                              tooltip: 'Zoom Out',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      } catch (e) {
        print('🗺️ Employee map: Google Maps failed, using fallback: $e');
        // Fallback to the web fallback map
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _buildWebFallbackMap(),
          ),
        );
      }
    }

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
                // Fit bounds to show the location and geofence
                _fitBounds();
              },
              initialCameraPosition: CameraPosition(
                target: _centerLocation!,
                zoom: 15.0, // Closer zoom for better detail
              ),
              markers: _markers,
              circles: _circles,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: false, // Hide default zoom controls
              mapToolbarEnabled: false, // Hide map toolbar
              compassEnabled: true,
              onTap: (_) {
                // Handle map tap if needed
              },
            ),
            // Custom zoom controls
            Positioned(
              right: 16,
              top: 16,
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add, size: 20),
                          onPressed: () {
                            _mapController?.animateCamera(
                              CameraUpdate.zoomIn(),
                            );
                          },
                          tooltip: 'Zoom In',
                        ),
                        Container(
                          height: 1,
                          color: Colors.grey.shade300,
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove, size: 20),
                          onPressed: () {
                            _mapController?.animateCamera(
                              CameraUpdate.zoomOut(),
                            );
                          },
                          tooltip: 'Zoom Out',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebFallbackMap() {
    final coords = widget.location['coordinates'];
    final address = _getLocationAddress(widget.location);
    final locationName = widget.location['name'] ?? 'Work Location';
    final geofenceRadius =
        widget.location['settings']?['geofenceRadius']?.toDouble() ?? 100.0;

    return Container(
      width: double.infinity,
      height: widget.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade50,
            Colors.blue.shade100,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned.fill(
            child: CustomPaint(
              painter: MapGridPainter(),
            ),
          ),
          // Location marker
          if (coords != null &&
              coords['latitude'] != null &&
              coords['longitude'] != null)
            Positioned(
              left: 50,
              top: 50,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade600,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.shade600.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      locationName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Geofence circle
          if (widget.showGeofence)
            Positioned(
              left: 50,
              top: 50,
              child: Container(
                width: geofenceRadius * 0.8,
                height: geofenceRadius * 0.8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.blue.shade400,
                    width: 2,
                  ),
                  color: Colors.blue.shade400.withValues(alpha: 0.1),
                ),
              ),
            ),
          // Location info
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.blue.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Location Details',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    address,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Geofence: ${geofenceRadius.toInt()}m radius',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // API Key notice
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Text(
                'Fallback Map',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _fitBounds() {
    if (_mapController != null && _centerLocation != null) {
      final geofenceRadius =
          widget.location['settings']?['geofenceRadius']?.toDouble() ?? 100.0;
      final padding =
          geofenceRadius * 2; // Add some padding around the geofence

      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(
              _centerLocation!.latitude -
                  (padding / 111000), // Convert meters to degrees
              _centerLocation!.longitude -
                  (padding /
                      (111000 * cos(_centerLocation!.latitude * pi / 180))),
            ),
            northeast: LatLng(
              _centerLocation!.latitude + (padding / 111000),
              _centerLocation!.longitude +
                  (padding /
                      (111000 * cos(_centerLocation!.latitude * pi / 180))),
            ),
          ),
          50.0, // Padding in pixels
        ),
      );
    }
  }
}

class MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.shade200.withValues(alpha: 0.3)
      ..strokeWidth = 1;

    // Draw grid lines
    for (double i = 0; i < size.width; i += 20) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 20) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
