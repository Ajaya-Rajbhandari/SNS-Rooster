import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw vertical lines
    for (double x = 0; x <= size.width; x += 50) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal lines
    for (double y = 0; y <= size.height; y += 50) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class InteractiveLocationMap extends StatefulWidget {
  final List<Map<String, dynamic>> locations;
  final double height;
  final Function(Map<String, dynamic> location)? onMarkerTap;
  final VoidCallback? onMapTap;

  const InteractiveLocationMap({
    Key? key,
    required this.locations,
    this.height = 300,
    this.onMarkerTap,
    this.onMapTap,
  }) : super(key: key);

  @override
  State<InteractiveLocationMap> createState() => _InteractiveLocationMapState();
}

class _InteractiveLocationMapState extends State<InteractiveLocationMap> {
  final MapController _mapController = MapController();
  LatLng? _centerLocation;
  bool _isLoading = true;
  List<Marker> _markers = [];

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Create markers for all locations
      _createMarkers();

      // Set center location (use first location or current location)
      if (widget.locations.isNotEmpty) {
        final firstLocation = widget.locations.first;
        final coords = firstLocation['coordinates'];
        if (coords != null &&
            coords['latitude'] != null &&
            coords['longitude'] != null) {
          _centerLocation = LatLng(
            coords['latitude'].toDouble(),
            coords['longitude'].toDouble(),
          );
        }
      }

      // If no center location from locations, try to get current location
      if (_centerLocation == null) {
        await _getCurrentLocation();
      }

      // If still no center location, use default
      _centerLocation ??= const LatLng(-33.8688, 151.2093);
    } catch (e) {
      // Use default location if everything fails
      _centerLocation = const LatLng(-33.8688, 151.2093);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _centerLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      // Keep existing center location or use default
    }
  }

  void _createMarkers() {
    final markers = <Marker>[];

    for (int i = 0; i < widget.locations.length; i++) {
      final location = widget.locations[i];
      final coords = location['coordinates'];

      if (coords != null &&
          coords['latitude'] != null &&
          coords['longitude'] != null) {
        final lat = coords['latitude'].toDouble();
        final lng = coords['longitude'].toDouble();

        markers.add(
          Marker(
            point: LatLng(lat, lng),
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () {
                if (widget.onMarkerTap != null) {
                  widget.onMarkerTap!(location);
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: _getMarkerColor(location['status'] ?? 'active'),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        );
      }
    }

    setState(() {
      _markers = markers;
    });
  }

  Color _getMarkerColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.red;
      case 'maintenance':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  double _getMarkerX(LatLng point) {
    // Simple positioning - center the marker
    return 100.0; // Place markers in the center for now
  }

  double _getMarkerY(LatLng point) {
    // Simple positioning - center the marker
    return 100.0; // Place markers in the center for now
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _centerLocation == null) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade200,
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
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
            Container(
              width: double.infinity,
              height: double.infinity,
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
                  // Simple grid background
                  CustomPaint(
                    size: Size.infinite,
                    painter: GridPainter(),
                  ),
                  // Markers
                  ..._markers
                      .map((marker) => Positioned(
                            left: _getMarkerX(marker.point),
                            top: _getMarkerY(marker.point),
                            child: marker.child,
                          ))
                      .toList(),
                ],
              ),
            ),
            // Map controls overlay
            Positioned(
              top: 16,
              right: 16,
              child: Column(
                children: [
                  // Fit bounds button
                  if (widget.locations.length > 1)
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
                      child: IconButton(
                        icon: const Icon(Icons.fit_screen, size: 20),
                        onPressed: () {
                          // For now, just show a message
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Map navigation coming soon!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        tooltip: 'Fit all locations',
                      ),
                    ),
                  const SizedBox(height: 8),
                  // Current location button
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
                    child: IconButton(
                      icon: const Icon(Icons.my_location, size: 20),
                      onPressed: () async {
                        await _getCurrentLocation();
                        // For now, just show a message
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Location feature coming soon!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      tooltip: 'My location',
                    ),
                  ),
                ],
              ),
            ),
            // Location count badge
            if (widget.locations.isNotEmpty)
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '${widget.locations.length} location${widget.locations.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
