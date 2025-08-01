import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'fallback_map_widget.dart';

class GoogleMapsLocationWidget extends StatefulWidget {
  final List<Map<String, dynamic>> locations;
  final double height;
  final Function(Map<String, dynamic> location)? onMarkerTap;
  final VoidCallback? onMapTap;

  const GoogleMapsLocationWidget({
    Key? key,
    required this.locations,
    this.height = 300,
    this.onMarkerTap,
    this.onMapTap,
  }) : super(key: key);

  @override
  State<GoogleMapsLocationWidget> createState() =>
      _GoogleMapsLocationWidgetState();
}

class _GoogleMapsLocationWidgetState extends State<GoogleMapsLocationWidget> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  bool _isLoading = true;
  bool _useFallback = false;
  LatLng? _centerLocation;

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
            markerId: MarkerId('location_${location['_id'] ?? i}'),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(
              title: location['name'] ?? 'Unknown Location',
              snippet: _getLocationAddress(location),
              onTap: () {
                if (widget.onMarkerTap != null) {
                  widget.onMarkerTap!(location);
                }
              },
            ),
            icon: _getMarkerIcon(location['status'] ?? 'active'),
            onTap: () {
              if (widget.onMarkerTap != null) {
                widget.onMarkerTap!(location);
              }
            },
          ),
        );
      }
    }

    setState(() {
      _markers = markers;
    });
  }

  String _getLocationAddress(Map<String, dynamic> location) {
    final address = location['address'];
    if (address == null) return 'No address available';

    final parts = <String>[];
    if (address['street']?.isNotEmpty == true) parts.add(address['street']);
    if (address['city']?.isNotEmpty == true) parts.add(address['city']);
    if (address['state']?.isNotEmpty == true) parts.add(address['state']);

    return parts.isEmpty ? 'No address available' : parts.join(', ');
  }

  BitmapDescriptor _getMarkerIcon(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case 'inactive':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      case 'maintenance':
        return BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange);
      default:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    }
  }

  void _fitBounds() {
    if (_mapController == null || widget.locations.isEmpty) return;

    final bounds = <LatLng>[];
    for (final location in widget.locations) {
      final coords = location['coordinates'];
      if (coords != null &&
          coords['latitude'] != null &&
          coords['longitude'] != null) {
        bounds.add(LatLng(
          coords['latitude'].toDouble(),
          coords['longitude'].toDouble(),
        ));
      }
    }

    if (bounds.isNotEmpty) {
      final southwest = LatLng(
        bounds.map((p) => p.latitude).reduce((a, b) => a < b ? a : b),
        bounds.map((p) => p.longitude).reduce((a, b) => a < b ? a : b),
      );
      final northeast = LatLng(
        bounds.map((p) => p.latitude).reduce((a, b) => a > b ? a : b),
        bounds.map((p) => p.longitude).reduce((a, b) => a > b ? a : b),
      );

      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(southwest: southwest, northeast: northeast),
          50.0,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // For web platform, always use fallback map
    if (kIsWeb) {
      print('🗺️ Web platform detected - using fallback map');
      return FallbackMapWidget(
        locations: widget.locations,
        height: widget.height,
        onMarkerTap: widget.onMarkerTap,
        onMapTap: widget.onMapTap,
      );
    }

    print('🗺️ Mobile platform detected - attempting to use Google Maps');
    print('🗺️ Loading state: $_isLoading');
    print('🗺️ Center location: $_centerLocation');
    print('🗺️ Markers count: ${_markers.length}');

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

    print('🗺️ Google Maps: Building widget with ${_markers.length} markers');
    print('🗺️ Google Maps: Center location: $_centerLocation');
    print(
        '🗺️ Google Maps: Map controller: ${_mapController != null ? "Ready" : "Not ready"}');
    print('🗺️ Google Maps: Using fallback: $_useFallback');

    // Use fallback if Google Maps tiles are not loading
    if (_useFallback) {
      return FallbackMapWidget(
        locations: widget.locations,
        height: widget.height,
        onMarkerTap: widget.onMarkerTap,
        onMapTap: widget.onMapTap,
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
            GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                print('🗺️ Google Maps: Map created successfully');
                _mapController = controller;
                // Fit bounds after map is created
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  print('🗺️ Google Maps: Fitting bounds');
                  _fitBounds();
                });
              },
              onCameraMoveStarted: () {
                print('🗺️ Google Maps: Camera move started');
              },
              initialCameraPosition: CameraPosition(
                target: _centerLocation!,
                zoom: 12.0,
              ),
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: true, // Enable zoom controls for debugging
              mapToolbarEnabled: true, // Enable map toolbar for debugging
              onTap: (_) {
                if (widget.onMapTap != null) {
                  widget.onMapTap!();
                }
              },
              onCameraMove: (position) {
                print('🗺️ Google Maps: Camera moved to ${position.target}');
              },
              onCameraIdle: () {
                print('🗺️ Google Maps: Camera idle');
              },
              mapType: MapType.normal, // Explicitly set map type
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
                        onPressed: _fitBounds,
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
                        if (_centerLocation != null && _mapController != null) {
                          _mapController!.animateCamera(
                            CameraUpdate.newLatLng(_centerLocation!),
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
            // Toggle map type button
            Positioned(
              bottom: 16,
              left: 16,
              child: Container(
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
                  icon: Icon(
                    _useFallback ? Icons.map : Icons.grid_on,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _useFallback = !_useFallback;
                    });
                    print(
                        '🗺️ Google Maps: Toggled to ${_useFallback ? "fallback" : "Google Maps"}');
                  },
                  tooltip: _useFallback
                      ? 'Switch to Google Maps'
                      : 'Switch to fallback map',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
