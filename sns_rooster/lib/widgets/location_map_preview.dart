import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';

class LocationMapPreview extends StatefulWidget {
  final List<Map<String, dynamic>> locations;
  final bool showMarkers;
  final double height;
  final VoidCallback? onLocationTap;
  final Function(Map<String, dynamic> location)? onMarkerTap;

  const LocationMapPreview({
    Key? key,
    required this.locations,
    this.showMarkers = true,
    this.height = 300,
    this.onLocationTap,
    this.onMarkerTap,
  }) : super(key: key);

  @override
  State<LocationMapPreview> createState() => _LocationMapPreviewState();
}

class _LocationMapPreviewState extends State<LocationMapPreview> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  bool _isLoading = true;
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

      // Fallback to default location if still no center
      if (_centerLocation == null) {
        _centerLocation = const LatLng(27.7172, 85.3240); // Kathmandu default
      }
    } catch (e) {
      // Set default location on error
      _centerLocation = const LatLng(27.7172, 85.3240); // Kathmandu default
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
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        _centerLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      // Silently handle location errors
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

    final bounds = _calculateBounds();
    if (bounds != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 50.0),
      );
    }
  }

  LatLngBounds? _calculateBounds() {
    if (widget.locations.isEmpty) return null;

    double minLat = 90.0;
    double maxLat = -90.0;
    double minLng = 180.0;
    double maxLng = -180.0;

    for (final location in widget.locations) {
      final coords = location['coordinates'];
      if (coords != null &&
          coords['latitude'] != null &&
          coords['longitude'] != null) {
        final lat = coords['latitude'].toDouble();
        final lng = coords['longitude'].toDouble();

        minLat = min(minLat, lat);
        maxLat = max(maxLat, lat);
        minLng = min(minLng, lng);
        maxLng = max(maxLng, lng);
      }
    }

    if (minLat == 90.0 || maxLat == -90.0) return null;

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  void _openInMaps(LatLng position, String title) async {
    final url =
        'https://www.google.com/maps?q=${position.latitude},${position.longitude}';
    try {
      await launchUrl(Uri.parse(url));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open maps')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _centerLocation == null) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
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
            GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
                // Fit bounds after map is created
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _fitBounds();
                });
              },
              initialCameraPosition: CameraPosition(
                target: _centerLocation!,
                zoom: 12.0,
              ),
              markers: widget.showMarkers ? _markers : {},
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              onTap: (_) {
                if (widget.onLocationTap != null) {
                  widget.onLocationTap!();
                }
              },
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
                            color: Colors.black.withOpacity(0.1),
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
                          color: Colors.black.withOpacity(0.1),
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
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${widget.locations.length} location${widget.locations.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(LocationMapPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.locations != widget.locations) {
      _createMarkers();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fitBounds();
      });
    }
  }
}
