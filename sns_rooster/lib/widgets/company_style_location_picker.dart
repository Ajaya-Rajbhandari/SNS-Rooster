import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';

class CompanyStyleLocationPicker extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final double initialRadius;
  final Function(double latitude, double longitude, double radius)
      onLocationSelected;

  const CompanyStyleLocationPicker({
    Key? key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialRadius = 100.0,
    required this.onLocationSelected,
  }) : super(key: key);

  @override
  State<CompanyStyleLocationPicker> createState() =>
      _CompanyStyleLocationPickerState();
}

class _CompanyStyleLocationPickerState
    extends State<CompanyStyleLocationPicker> {
  final _searchController = TextEditingController();
  final _radiusController = TextEditingController();

  double _radius = 100.0;
  String _searchQuery = '';
  bool _isLoadingLocation = false;
  bool _isSearching = false;
  bool _showSearchResults = false;

  double? _selectedLatitude;
  double? _selectedLongitude;
  String _selectedAddress = '';
  List<Placemark> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _radius = widget.initialRadius;
    _radiusController.text = _radius.round().toString();

    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedLatitude = widget.initialLatitude;
      _selectedLongitude = widget.initialLongitude;
      _getAddressFromCoordinates();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showErrorSnackBar('Location services are disabled');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showErrorSnackBar('Location permission denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showErrorSnackBar('Location permissions are permanently denied');
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        _selectedLatitude = position.latitude;
        _selectedLongitude = position.longitude;
        _isLoadingLocation = false;
      });

      _getAddressFromCoordinates();
      _showSuccessSnackBar('Current location selected');
    } catch (e) {
      _showErrorSnackBar('Could not get current location');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
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

      for (Location location in locations.take(5)) {
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
          _showSearchResults = false;
          _searchController.clear();
        });

        _getAddressFromCoordinates();
        _showSuccessSnackBar('Location selected');
      }
    } catch (e) {
      _showErrorSnackBar('Could not get coordinates for this location');
    }
  }

  Future<void> _getAddressFromCoordinates() async {
    if (_selectedLatitude == null || _selectedLongitude == null) return;

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _selectedLatitude!,
        _selectedLongitude!,
      ).timeout(const Duration(seconds: 5));

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
          _selectedAddress = address;
        });
      }
    } catch (e) {
      setState(() {
        _selectedAddress = 'Address not available';
      });
    }
  }

  void _openInMaps() async {
    if (_selectedLatitude == null || _selectedLongitude == null) return;

    try {
      final url =
          'https://www.google.com/maps?q=$_selectedLatitude,$_selectedLongitude';
      await launchUrl(Uri.parse(url));
    } catch (e) {
      _showErrorSnackBar('Could not open in maps');
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
    } else {
      _showErrorSnackBar('Please select a location first');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Select Location',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_selectedLatitude != null && _selectedLongitude != null)
            TextButton(
              onPressed: _confirmLocation,
              child: const Text(
                'Done',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar (Google Maps Style)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => _searchLocation(value),
                    decoration: InputDecoration(
                      hintText: 'Search for a location',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: Colors.grey[600]),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _showSearchResults = false;
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                if (_showSearchResults) ...[
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _isSearching
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
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
                                    Icon(Icons.search_off, color: Colors.grey),
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
                                  final placemark = _searchResults[index];
                                  final address = [
                                    placemark.street,
                                    placemark.locality,
                                    placemark.administrativeArea,
                                  ]
                                      .where((part) =>
                                          part != null && part.isNotEmpty)
                                      .join(', ');

                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.blue[50],
                                      child: Icon(
                                        Icons.location_on,
                                        color: Colors.blue,
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      address,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      placemark.country ?? '',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                    onTap: () => _selectSearchResult(placemark),
                                  );
                                },
                              ),
                  ),
                ],
              ],
            ),
          ),

          // Current Location Button (Uber Style)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue[50],
                child: Icon(
                  Icons.my_location,
                  color: Colors.blue,
                ),
              ),
              title: const Text(
                'Use current location',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: const Text('GPS location'),
              trailing: _isLoadingLocation
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _isLoadingLocation ? null : _getCurrentLocation,
            ),
          ),

          const Divider(height: 1),

          // Selected Location Display (Apple Maps Style)
          if (_selectedLatitude != null && _selectedLongitude != null) ...[
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selected Location',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green[600]),
                            const SizedBox(width: 8),
                            const Text(
                              'Location Set',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                              ),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: _openInMaps,
                              icon: const Icon(Icons.open_in_new, size: 16),
                              label: const Text('View in Maps'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_selectedAddress.isNotEmpty)
                          Text(
                            _selectedAddress,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          '${_selectedLatitude!.toStringAsFixed(6)}, ${_selectedLongitude!.toStringAsFixed(6)}',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
          ],

          // Radius Configuration (Simple Slider)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Geofence Radius',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: _radius,
                        min: 25,
                        max: 1000,
                        divisions: 39,
                        activeColor: Colors.blue,
                        onChanged: (value) {
                          setState(() {
                            _radius = value;
                            _radiusController.text = value.round().toString();
                          });
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${_radius.round()}m',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '25m',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '1000m',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Spacer(),

          // Bottom Action Button (Google Maps Style)
          if (_selectedLatitude != null && _selectedLongitude != null)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _confirmLocation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Confirm Location',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
