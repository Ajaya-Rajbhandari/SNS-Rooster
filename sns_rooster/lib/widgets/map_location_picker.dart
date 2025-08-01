import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class MapLocationPicker extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final double initialRadius;
  final Function(double latitude, double longitude, double radius)
      onLocationSelected;

  const MapLocationPicker({
    Key? key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialRadius = 100.0,
    required this.onLocationSelected,
  }) : super(key: key);

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};

  double? _selectedLatitude;
  double? _selectedLongitude;
  double _radius = 100.0;
  String _address = '';
  bool _isLoadingAddress = false;

  @override
  void initState() {
    super.initState();
    _selectedLatitude = widget.initialLatitude;
    _selectedLongitude = widget.initialLongitude;
    _radius = widget.initialRadius;

    if (_selectedLatitude != null && _selectedLongitude != null) {
      _updateMarker();
      _getAddressFromCoordinates();
    } else {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setDefaultLocation();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _setDefaultLocation();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _setDefaultLocation();
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _selectedLatitude = position.latitude;
        _selectedLongitude = position.longitude;
      });

      _updateMarker();
      _getAddressFromCoordinates();

      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(
              LatLng(_selectedLatitude!, _selectedLongitude!)),
        );
      }
    } catch (e) {
      _setDefaultLocation();
    }
  }

  void _setDefaultLocation() {
    setState(() {
      _selectedLatitude = -33.8688; // Sydney coordinates
      _selectedLongitude = 151.2093;
    });
    _updateMarker();
    _getAddressFromCoordinates();
  }

  void _updateMarker() {
    if (_selectedLatitude != null && _selectedLongitude != null) {
      setState(() {
        _markers = {
          Marker(
            markerId: const MarkerId('selected_location'),
            position: LatLng(_selectedLatitude!, _selectedLongitude!),
            draggable: true,
            onDragEnd: (LatLng newPosition) {
              setState(() {
                _selectedLatitude = newPosition.latitude;
                _selectedLongitude = newPosition.longitude;
              });
              _getAddressFromCoordinates();
            },
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        };

        _circles = {
          Circle(
            circleId: const CircleId('geofence'),
            center: LatLng(_selectedLatitude!, _selectedLongitude!),
            radius: _radius,
            fillColor: Colors.blue.withValues(alpha: 0.2),
            strokeColor: Colors.blue,
            strokeWidth: 2,
          ),
        };
      });
    }
  }

  Future<void> _getAddressFromCoordinates() async {
    if (_selectedLatitude == null || _selectedLongitude == null) return;

    setState(() {
      _isLoadingAddress = true;
    });

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _selectedLatitude!,
        _selectedLongitude!,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _address =
              '${place.street ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''} ${place.postalCode ?? ''}'
                  .trim();
        });
      }
    } catch (e) {
      setState(() {
        _address = 'Address not available';
      });
    } finally {
      setState(() {
        _isLoadingAddress = false;
      });
    }
  }

  void _onMapTap(LatLng position) {
    setState(() {
      _selectedLatitude = position.latitude;
      _selectedLongitude = position.longitude;
    });
    _updateMarker();
    _getAddressFromCoordinates();
  }

  void _onRadiusChanged(double value) {
    setState(() {
      _radius = value;
    });
    _updateMarker();
  }

  void _confirmLocation() {
    if (_selectedLatitude != null && _selectedLongitude != null) {
      widget.onLocationSelected(
          _selectedLatitude!, _selectedLongitude!, _radius);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Location',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Map Container
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: GoogleMap(
                    onMapCreated: (GoogleMapController controller) {
                      _mapController = controller;
                      if (_selectedLatitude != null &&
                          _selectedLongitude != null) {
                        controller.animateCamera(
                          CameraUpdate.newLatLng(
                            LatLng(_selectedLatitude!, _selectedLongitude!),
                          ),
                        );
                      }
                    },
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                        _selectedLatitude ?? -33.8688,
                        _selectedLongitude ?? 151.2093,
                      ),
                      zoom: 15,
                    ),
                    onTap: _onMapTap,
                    markers: _markers,
                    circles: _circles,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Location Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Selected Location:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_isLoadingAddress)
                    const Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Loading address...'),
                      ],
                    )
                  else if (_address.isNotEmpty)
                    Text(_address),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Lat: ${_selectedLatitude?.toStringAsFixed(6) ?? 'N/A'}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Lng: ${_selectedLongitude?.toStringAsFixed(6) ?? 'N/A'}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Radius Slider
            Row(
              children: [
                const Text('Geofence Radius: '),
                Expanded(
                  child: Slider(
                    value: _radius,
                    min: 50,
                    max: 500,
                    divisions: 9,
                    label: '${_radius.round()}m',
                    onChanged: _onRadiusChanged,
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Text(
                    '${_radius.round()}m',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        _selectedLatitude != null && _selectedLongitude != null
                            ? _confirmLocation
                            : null,
                    child: const Text('Confirm Location'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
