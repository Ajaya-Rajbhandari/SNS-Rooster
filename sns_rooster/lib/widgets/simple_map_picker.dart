import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';

class SimpleMapPicker extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final double initialRadius;
  final Function(double latitude, double longitude, double radius)
      onLocationSelected;

  const SimpleMapPicker({
    Key? key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialRadius = 100.0,
    required this.onLocationSelected,
  }) : super(key: key);

  @override
  State<SimpleMapPicker> createState() => _SimpleMapPickerState();
}

class _SimpleMapPickerState extends State<SimpleMapPicker> {
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _searchController = TextEditingController();

  double _radius = 100.0;
  String _address = '';
  bool _isLoadingAddress = false;
  bool _isLoadingLocation = false;
  bool _isSearching = false;
  bool _showSearchResults = false;

  double? _selectedLatitude;
  double? _selectedLongitude;
  List<Placemark> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _radius = widget.initialRadius;

    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedLatitude = widget.initialLatitude;
      _selectedLongitude = widget.initialLongitude;
      _latController.text = widget.initialLatitude!.toStringAsFixed(6);
      _lngController.text = widget.initialLongitude!.toStringAsFixed(6);
      _getAddressFromCoordinates();
    } else {
      _getCurrentLocation();
    }
  }

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

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

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        _selectedLatitude = position.latitude;
        _selectedLongitude = position.longitude;
        _latController.text = position.latitude.toStringAsFixed(6);
        _lngController.text = position.longitude.toStringAsFixed(6);
        _isLoadingLocation = false;
      });

      _getAddressFromCoordinates();
    } catch (e) {
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
      _selectedLatitude = -33.8688; // Sydney coordinates
      _selectedLongitude = 151.2093;
      _latController.text = '37.421998';
      _lngController.text = '-122.08400';
    });
    _getAddressFromCoordinates();
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _showSearchResults = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _showSearchResults = true;
    });

    try {
      List<Location> locations = await locationFromAddress(query);
      List<Placemark> placemarks = [];

      for (Location location in locations.take(3)) {
        List<Placemark> results = await placemarkFromCoordinates(
          location.latitude,
          location.longitude,
        );
        if (results.isNotEmpty) {
          placemarks.add(results.first);
        }
      }

      setState(() {
        _searchResults = placemarks;
      });
    } catch (e) {
      setState(() {
        _searchResults = [];
      });
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _selectSearchResult(Placemark placemark) async {
    try {
      List<Location> locations = await locationFromAddress(
        [placemark.street, placemark.locality, placemark.administrativeArea]
            .where((part) => part != null && part.isNotEmpty)
            .join(', '),
      );

      if (locations.isNotEmpty) {
        setState(() {
          _selectedLatitude = locations.first.latitude;
          _selectedLongitude = locations.first.longitude;
          _latController.text = locations.first.latitude.toStringAsFixed(6);
          _lngController.text = locations.first.longitude.toStringAsFixed(6);
          _showSearchResults = false;
          _searchController.clear();
        });

        _getAddressFromCoordinates();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not get coordinates for this location')),
        );
      }
    }
  }

  void _onCoordinatesChanged() {
    try {
      final lat = double.tryParse(_latController.text);
      final lng = double.tryParse(_lngController.text);

      if (lat != null &&
          lng != null &&
          lat >= -90 &&
          lat <= 90 &&
          lng >= -180 &&
          lng <= 180) {
        setState(() {
          _selectedLatitude = lat;
          _selectedLongitude = lng;
        });
        _getAddressFromCoordinates();
      }
    } catch (e) {
      // Handle invalid coordinates silently
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
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception('Address lookup timed out');
        },
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        final address = [
          place.street,
          place.locality,
          place.administrativeArea,
          place.postalCode,
          place.country,
        ]
            .where((part) => part != null && part.toString().isNotEmpty)
            .join(', ');

        setState(() {
          _address = address;
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAddress = false;
        });
      }
    }
  }

  void _openInMaps() async {
    if (_selectedLatitude == null || _selectedLongitude == null) return;

    try {
      final url =
          'https://www.google.com/maps?q=$_selectedLatitude,$_selectedLongitude';
      await launchUrl(Uri.parse(url));
    } catch (e) {
      // Handle error silently
    }
  }

  void _confirmLocation() {
    if (_selectedLatitude != null && _selectedLongitude != null) {
      widget.onLocationSelected(
        _selectedLatitude!,
        _selectedLongitude!,
        _radius,
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade600, Colors.blue.shade800],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Location',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Enter coordinates or search for a location',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.shade50,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Search for a Location',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _searchController,
                            onChanged: (value) => _searchLocation(value),
                            decoration: InputDecoration(
                              hintText: 'Search for a location...',
                              prefixIcon:
                                  const Icon(Icons.search, color: Colors.blue),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {
                                          _showSearchResults = false;
                                        });
                                      },
                                    )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          if (_showSearchResults) ...[
                            const SizedBox(height: 8),
                            Container(
                              constraints: const BoxConstraints(maxHeight: 150),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: _isSearching
                                  ? const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2),
                                          ),
                                          SizedBox(width: 12),
                                          Text('Searching...'),
                                        ],
                                      ),
                                    )
                                  : _searchResults.isEmpty
                                      ? const Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Row(
                                            children: [
                                              Icon(Icons.search_off,
                                                  color: Colors.grey),
                                              SizedBox(width: 12),
                                              Text('No locations found'),
                                            ],
                                          ),
                                        )
                                      : ListView.builder(
                                          shrinkWrap: true,
                                          padding: EdgeInsets.zero,
                                          itemCount: _searchResults.length,
                                          itemBuilder: (context, index) {
                                            final placemark =
                                                _searchResults[index];
                                            final address = [
                                              placemark.street,
                                              placemark.locality,
                                              placemark.administrativeArea,
                                            ]
                                                .where((part) =>
                                                    part != null &&
                                                    part.isNotEmpty)
                                                .join(', ');

                                            return ListTile(
                                              leading: Container(
                                                padding:
                                                    const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: const Icon(
                                                    Icons.location_on,
                                                    color: Colors.blue,
                                                    size: 20),
                                              ),
                                              title: Text(
                                                address,
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.w500),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              subtitle: Text(
                                                placemark.country ?? '',
                                                style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 12),
                                              ),
                                              onTap: () => _selectSearchResult(
                                                  placemark),
                                            );
                                          },
                                        ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Coordinates Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.shade50,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Coordinates',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _latController,
                                  onChanged: (_) => _onCoordinatesChanged(),
                                  decoration: const InputDecoration(
                                    labelText: 'Latitude',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _lngController,
                                  onChanged: (_) => _onCoordinatesChanged(),
                                  decoration: const InputDecoration(
                                    labelText: 'Longitude',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Radius Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.shade50,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Geofence Radius',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Slider(
                            value: _radius,
                            min: 25,
                            max: 1000,
                            divisions: 39,
                            onChanged: (value) {
                              setState(() {
                                _radius = value;
                              });
                            },
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('25m'),
                              Text(
                                '${_radius.round()}m',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              const Text('1000m'),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Location Info
                    if (_selectedLatitude != null && _selectedLongitude != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.check_circle,
                                    color: Colors.green),
                                const SizedBox(width: 8),
                                const Text(
                                  'Location Selected',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                const Spacer(),
                                TextButton.icon(
                                  onPressed: _openInMaps,
                                  icon: const Icon(Icons.open_in_new, size: 16),
                                  label: const Text('Open in Maps'),
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
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                  SizedBox(width: 8),
                                  Text('Loading address...'),
                                ],
                              )
                            else if (_address.isNotEmpty)
                              Text(
                                _address,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            const SizedBox(height: 8),
                            Text(
                              'Coordinates: ${_selectedLatitude!.toStringAsFixed(6)}, ${_selectedLongitude!.toStringAsFixed(6)}',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed:
                                _isLoadingLocation ? null : _getCurrentLocation,
                            icon: _isLoadingLocation
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.my_location),
                            label: const Text('Current Location'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _selectedLatitude != null
                                ? _confirmLocation
                                : null,
                            icon: const Icon(Icons.check),
                            label: const Text('Confirm Location'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
