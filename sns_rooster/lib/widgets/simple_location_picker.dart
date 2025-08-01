import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';

class SimpleLocationPicker extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final double initialRadius;
  final Function(double latitude, double longitude, double radius)
      onLocationSelected;

  const SimpleLocationPicker({
    Key? key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialRadius = 100.0,
    required this.onLocationSelected,
  }) : super(key: key);

  @override
  State<SimpleLocationPicker> createState() => _SimpleLocationPickerState();
}

class _SimpleLocationPickerState extends State<SimpleLocationPicker> {
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  double _radius = 100.0;
  String _address = '';
  bool _isLoadingAddress = false;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _radius = widget.initialRadius;

    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _latController.text = widget.initialLatitude!.toStringAsFixed(6);
      _lngController.text = widget.initialLongitude!.toStringAsFixed(6);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _getAddressFromCoordinates();
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _getCurrentLocation();
      });
    }
  }

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setDefaultLocation();
        return;
      }

      // Check location permission
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

      // Get current position with timeout
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Location request timed out');
        },
      );

      setState(() {
        _latController.text = position.latitude.toStringAsFixed(6);
        _lngController.text = position.longitude.toStringAsFixed(6);
      });

      _getAddressFromCoordinates();
    } catch (e) {
      // Handle any errors gracefully
      _setDefaultLocation();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not get current location: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  void _setDefaultLocation() {
    setState(() {
      _latController.text = '-33.8688';
      _lngController.text = '151.2093';
    });
    _getAddressFromCoordinates();
  }

  Future<void> _getAddressFromCoordinates() async {
    final lat = double.tryParse(_latController.text);
    final lng = double.tryParse(_lngController.text);

    if (lat == null || lng == null) return;

    setState(() {
      _isLoadingAddress = true;
    });

    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(lat, lng).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Address lookup timed out');
        },
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _address =
              '${place.street ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''} ${place.postalCode ?? ''}'
                  .trim();
        });
      } else {
        setState(() {
          _address = 'Address not available';
        });
      }
    } catch (e) {
      setState(() {
        _address = 'Address lookup failed';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not get address: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAddress = false;
        });
      }
    }
  }

  void _onCoordinatesChanged() {
    try {
      final lat = double.tryParse(_latController.text);
      final lng = double.tryParse(_lngController.text);

      // Only lookup address if both coordinates are valid
      if (lat != null &&
          lng != null &&
          lat >= -90 &&
          lat <= 90 &&
          lng >= -180 &&
          lng <= 180) {
        _getAddressFromCoordinates();
      } else {
        setState(() {
          _address = 'Enter valid coordinates';
        });
      }
    } catch (e) {
      setState(() {
        _address = 'Invalid coordinates';
      });
    }
  }

  void _confirmLocation() {
    final lat = double.tryParse(_latController.text);
    final lng = double.tryParse(_lngController.text);

    if (lat != null && lng != null) {
      widget.onLocationSelected(lat, lng, _radius);
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid coordinates')),
      );
    }
  }

  void _openInMaps() {
    final lat = _latController.text;
    final lng = _lngController.text;

    if (lat.isNotEmpty && lng.isNotEmpty) {
      final url = 'https://www.google.com/maps?q=$lat,$lng';
      launchUrl(Uri.parse(url));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height *
            0.75, // Reduced height to prevent overflow
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

            // Map Preview
            Container(
              height: 150, // Reduced height
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade100,
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.map,
                            size: 40, color: Colors.grey), // Smaller icon
                        const SizedBox(height: 8),
                        const Text(
                          'Location Preview',
                          style: TextStyle(
                            fontSize: 14, // Smaller text
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _openInMaps,
                          icon: const Icon(Icons.open_in_new,
                              size: 16), // Smaller icon
                          label: const Text('Open in Maps',
                              style: TextStyle(fontSize: 12)), // Smaller text
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8), // Smaller padding
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Geofence circle indicator
                  if (_latController.text.isNotEmpty &&
                      _lngController.text.isNotEmpty)
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4), // Smaller padding
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.8),
                          borderRadius:
                              BorderRadius.circular(12), // Smaller radius
                        ),
                        child: Text(
                          '${_radius.round()}m',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12, // Smaller text
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 12), // Reduced spacing

            // Coordinates Input
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _latController,
                    decoration: const InputDecoration(
                      labelText: 'Latitude',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => _onCoordinatesChanged(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _lngController,
                    decoration: const InputDecoration(
                      labelText: 'Longitude',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => _onCoordinatesChanged(),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12), // Reduced spacing

            // Address Display
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_city, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _isLoadingAddress
                        ? const Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: 8),
                              Text('Loading address...'),
                            ],
                          )
                        : Text(_address.isNotEmpty
                            ? _address
                            : 'Enter coordinates to see address'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12), // Reduced spacing

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
                    onChanged: (value) {
                      setState(() {
                        _radius = value;
                      });
                    },
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

            const Spacer(), // This pushes the buttons to the bottom

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                    icon: _isLoadingLocation
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.my_location),
                    label: Text(_isLoadingLocation
                        ? 'Getting Location...'
                        : 'Use Current Location'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _confirmLocation,
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
