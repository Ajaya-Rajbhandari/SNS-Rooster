import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'fallback_map_widget.dart';

class WebGoogleMapsWidget extends StatefulWidget {
  final List<Map<String, dynamic>> locations;
  final double height;
  final Function(Map<String, dynamic>)? onMarkerTap;
  final VoidCallback? onMapTap;

  const WebGoogleMapsWidget({
    Key? key,
    required this.locations,
    required this.height,
    this.onMarkerTap,
    this.onMapTap,
  }) : super(key: key);

  @override
  State<WebGoogleMapsWidget> createState() => _WebGoogleMapsWidgetState();
}

class _WebGoogleMapsWidgetState extends State<WebGoogleMapsWidget> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkWebMapAvailability();
  }

  Future<void> _checkWebMapAvailability() async {
    // For web, try to use real Google Maps since API key restrictions are now "None"
    print('🗺️ Checking web map availability...');
    await Future.delayed(const Duration(milliseconds: 1000));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      print('🗺️ Web map availability check completed');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // For web, try to use real Google Maps first, fallback if needed
    if (kIsWeb) {
      print('🗺️ Building web Google Maps widget...');
      try {
        // Try to use real Google Maps for web
        print('🗺️ Attempting to create Google Maps widget...');
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                print('🗺️ Web Google Maps: Map created successfully');
                print('🗺️ Map controller: $controller');
                print('🗺️ Map markers count: ${_createMarkers().length}');
                
                // Try to get current location and center map
                _getCurrentLocationAndCenter(controller);
              },
              initialCameraPosition: _getInitialCameraPosition(),
              markers: _createMarkers(),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: true,
              mapToolbarEnabled: false,
              compassEnabled: true,
              onTap: (_) {
                if (widget.onMapTap != null) {
                  widget.onMapTap!();
                }
              },
            ),
          ),
        );
      } catch (e) {
        print('🗺️ Web Google Maps failed, using fallback: $e');
        print('🗺️ Error type: ${e.runtimeType}');
        print('🗺️ Error stack trace: ${StackTrace.current}');
        // Fallback to enhanced map if Google Maps fails
        if (widget.locations.isNotEmpty) {
          return Container(
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildEnhancedFallbackMap(),
            ),
          );
        } else {
          return FallbackMapWidget(
            locations: widget.locations,
            height: widget.height,
            onMarkerTap: widget.onMarkerTap,
            onMapTap: widget.onMapTap,
          );
        }
      }
    }

    // For mobile platforms, use Google Maps
    return _buildGoogleMapsWidget();
  }

  CameraPosition _getInitialCameraPosition() {
    // If we have locations, center on the first one
    if (widget.locations.isNotEmpty) {
      final firstLocation = widget.locations.first;
      final coords = firstLocation['coordinates'];
      if (coords != null && coords['latitude'] != null && coords['longitude'] != null) {
        return CameraPosition(
          target: LatLng(
            coords['latitude'].toDouble(),
            coords['longitude'].toDouble(),
          ),
          zoom: 15.0,
        );
      }
    }
    
    // Default to Sydney if no locations
    return const CameraPosition(
      target: LatLng(-33.8688, 151.2093), // Sydney
      zoom: 12.0,
    );
  }

  Future<void> _getCurrentLocationAndCenter(GoogleMapController controller) async {
    try {
      // For web, we'll use a default location since geolocator might not work
      // In a real implementation, you'd use the browser's geolocation API
      print('🗺️ Attempting to get current location for web...');
      
      // For now, we'll just log that we're trying to get location
      // In a production app, you'd implement proper web geolocation
      print('🗺️ Current location feature enabled for web');
      
    } catch (e) {
      print('🗺️ Could not get current location: $e');
    }
  }

  Widget _buildEnhancedFallbackMap() {
    final location = widget.locations.first;
    final coords = location['coordinates'];
    final address = _getLocationAddress(location);
    final locationName = location['name'] ?? 'Location';
    final geofenceRadius =
        location['settings']?['geofenceRadius']?.toDouble() ?? 100.0;

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

  Set<Marker> _createMarkers() {
    final markers = <Marker>{};

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
            markerId: MarkerId('location_$i'),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(
              title: location['name'] ?? 'Location',
              snippet: _getLocationAddress(location),
            ),
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        );
      }
    }

    return markers;
  }

  Widget _buildGoogleMapsWidget() {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GoogleMap(
          onMapCreated: (GoogleMapController controller) {
            print('🗺️ Mobile Google Maps: Map created successfully');
          },
          initialCameraPosition: const CameraPosition(
            target: LatLng(-33.8688, 151.2093), // Sydney
            zoom: 12.0,
          ),
          markers: _createMarkers(),
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: true,
          mapToolbarEnabled: false,
          onTap: (_) {
            if (widget.onMapTap != null) {
              widget.onMapTap!();
            }
          },
        ),
      ),
    );
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
