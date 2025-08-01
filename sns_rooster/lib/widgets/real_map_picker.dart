import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';

class RealMapPicker extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final double initialRadius;
  final Function(double latitude, double longitude, double radius)
      onLocationSelected;

  const RealMapPicker({
    Key? key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialRadius = 100.0,
    required this.onLocationSelected,
  }) : super(key: key);

  @override
  State<RealMapPicker> createState() => _RealMapPickerState();
}

class _RealMapPickerState extends State<RealMapPicker> {
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _addressController = TextEditingController();
  double _radius = 100.0;
  bool _isLoadingAddress = false;
  bool _isLoadingLocation = false;
  bool _isMapExpanded = false;
  double _zoom = 15.0;
  double _centerLat = 37.421998;
  double _centerLng = -122.08400;
  double _selectedLat = 37.421998;
  double _selectedLng = -122.08400;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _radius = widget.initialRadius;

    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedLat = widget.initialLatitude!;
      _selectedLng = widget.initialLongitude!;
      _centerLat = widget.initialLatitude!;
      _centerLng = widget.initialLongitude!;
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
    _addressController.dispose();
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
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Location request timed out');
        },
      );

      setState(() {
        _selectedLat = position.latitude;
        _selectedLng = position.longitude;
        _centerLat = position.latitude;
        _centerLng = position.longitude;
        _latController.text = position.latitude.toStringAsFixed(6);
        _lngController.text = position.longitude.toStringAsFixed(6);
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
      _selectedLat = 37.421998;
      _selectedLng = -122.08400;
      _centerLat = 37.421998;
      _centerLng = -122.08400;
      _latController.text = '37.421998';
      _lngController.text = '-122.08400';
    });
    _getAddressFromCoordinates();
  }

  Future<void> _getAddressFromCoordinates() async {
    setState(() {
      _isLoadingAddress = true;
    });

    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(_selectedLat, _selectedLng).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Address lookup timed out');
        },
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        final address =
            '${place.street ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''} ${place.postalCode ?? ''}'
                .trim();
        setState(() {
          _addressController.text = address;
        });
      } else {
        setState(() {
          _addressController.text = '';
        });
      }
    } catch (e) {
      setState(() {
        _addressController.text = '';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAddress = false;
        });
      }
    }
  }

  void _onMapTap(double lat, double lng) {
    setState(() {
      _selectedLat = lat;
      _selectedLng = lng;
      _latController.text = lat.toStringAsFixed(6);
      _lngController.text = lng.toStringAsFixed(6);
    });
    _getAddressFromCoordinates();
  }

  void _onMapDrag(double lat, double lng) {
    setState(() {
      _centerLat = lat;
      _centerLng = lng;
      _isDragging = true;
    });
  }

  void _onMapDragEnd() {
    setState(() {
      _isDragging = false;
    });
  }

  void _onZoomChanged(double zoom) {
    setState(() {
      _zoom = zoom;
    });
  }

  void _openInMaps() {
    final url = 'https://www.google.com/maps?q=$_selectedLat,$_selectedLng';
    launchUrl(Uri.parse(url));
  }

  void _confirmLocation() {
    widget.onLocationSelected(_selectedLat, _selectedLng, _radius);
    Navigator.of(context).pop();
  }

  void _toggleMapExpansion() {
    setState(() {
      _isMapExpanded = !_isMapExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.85,
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
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.location_on,
                        color: Colors.blue, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Select Location on Map',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.close, size: 20),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Real Map Section
                    Container(
                      height: _isMapExpanded ? 400 : 300,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            // Real Map Tiles
                            _buildRealMap(),

                            // Map Controls
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Column(
                                children: [
                                  // Expand/Collapse Button
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.1),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: IconButton(
                                      onPressed: _toggleMapExpansion,
                                      icon: Icon(
                                        _isMapExpanded
                                            ? Icons.fullscreen_exit
                                            : Icons.fullscreen,
                                        color: Colors.blue,
                                        size: 20,
                                      ),
                                      padding: const EdgeInsets.all(8),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Zoom Controls
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.1),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        IconButton(
                                          onPressed: () =>
                                              _onZoomChanged(_zoom + 1),
                                          icon: const Icon(Icons.add, size: 20),
                                          padding: const EdgeInsets.all(8),
                                        ),
                                        IconButton(
                                          onPressed: () =>
                                              _onZoomChanged(_zoom - 1),
                                          icon: const Icon(Icons.remove,
                                              size: 20),
                                          padding: const EdgeInsets.all(8),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Center Location Pin
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(50),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.location_on,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.9),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.1),
                                          blurRadius: 5,
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      '${_radius.round()}m radius',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Geofence Circle
                            if (!_isDragging)
                              Center(
                                child: Container(
                                  width: _radius *
                                      2 /
                                      _zoom *
                                      100, // Approximate pixel calculation
                                  height: _radius * 2 / _zoom * 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.blue.withValues(alpha: 0.6),
                                      width: 2,
                                    ),
                                    color: Colors.blue.withValues(alpha: 0.1),
                                  ),
                                ),
                              ),

                            // Open in Maps Button
                            Positioned(
                              bottom: 12,
                              left: 12,
                              child: ElevatedButton.icon(
                                onPressed: _openInMaps,
                                icon: const Icon(Icons.open_in_new, size: 16),
                                label: const Text('Open in Maps'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.blue,
                                  elevation: 2,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                            ),

                            // Tap Instructions
                            if (_isDragging)
                              Positioned(
                                top: 50,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.black.withValues(alpha: 0.7),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'Tap to select location',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Coordinates Section
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
                          child: _buildInputField(
                            controller: _latController,
                            label: 'Latitude',
                            icon: Icons.navigation,
                            readOnly: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInputField(
                            controller: _lngController,
                            label: 'Longitude',
                            icon: Icons.navigation,
                            readOnly: true,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Address Section
                    const Text(
                      'Address',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildInputField(
                      controller: _addressController,
                      label: 'Street Address',
                      icon: Icons.location_city,
                      readOnly: true,
                      suffix: _isLoadingAddress
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : null,
                    ),

                    const SizedBox(height: 24),

                    // Radius Section
                    Row(
                      children: [
                        const Icon(Icons.radio_button_checked,
                            color: Colors.blue),
                        const SizedBox(width: 8),
                        const Text(
                          'Geofence Radius',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_radius.round()}m',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: Colors.blue,
                        inactiveTrackColor: Colors.blue.withValues(alpha: 0.2),
                        thumbColor: Colors.blue,
                        overlayColor: Colors.blue.withValues(alpha: 0.1),
                        trackHeight: 4,
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 8),
                        overlayShape:
                            const RoundSliderOverlayShape(overlayRadius: 16),
                      ),
                      child: Slider(
                        value: _radius,
                        min: 50,
                        max: 500,
                        divisions: 9,
                        onChanged: (value) {
                          setState(() {
                            _radius = value;
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 32),

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
                                        strokeWidth: 2))
                                : const Icon(Icons.my_location),
                            label: Text(_isLoadingLocation
                                ? 'Getting Location...'
                                : 'Use Current Location'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(
                                  color: Colors.blue.withValues(alpha: 0.5)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _confirmLocation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: const Text(
                              'Confirm Location',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
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

  Widget _buildRealMap() {
    return GestureDetector(
      onTapDown: (details) {
        // Convert tap position to coordinates
        final RenderBox renderBox = context.findRenderObject() as RenderBox;
        final localPosition = renderBox.globalToLocal(details.globalPosition);

        // Calculate coordinates based on tap position
        final latOffset =
            (localPosition.dy - 150) * 0.0001 / _zoom; // Approximate
        final lngOffset =
            (localPosition.dx - 200) * 0.0001 / _zoom; // Approximate

        final newLat = _centerLat - latOffset;
        final newLng = _centerLng + lngOffset;

        _onMapTap(newLat, newLng);
      },
      onPanUpdate: (details) {
        // Handle map dragging
        final latOffset = details.delta.dy * 0.0001 / _zoom;
        final lngOffset = details.delta.dx * 0.0001 / _zoom;

        final newLat = _centerLat - latOffset;
        final newLng = _centerLng + lngOffset;

        _onMapDrag(newLat, newLng);
      },
      onPanEnd: (details) {
        _onMapDragEnd();
      },
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade50,
              Colors.blue.shade100,
              Colors.green.shade50,
            ],
          ),
        ),
        child: CustomPaint(
          painter: RealMapPainter(
            centerLat: _centerLat,
            centerLng: _centerLng,
            zoom: _zoom,
            selectedLat: _selectedLat,
            selectedLng: _selectedLng,
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blue),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          labelStyle: TextStyle(color: Colors.grey.shade600),
        ),
        style: const TextStyle(fontSize: 14),
      ),
    );
  }
}

class RealMapPainter extends CustomPainter {
  final double centerLat;
  final double centerLng;
  final double zoom;
  final double selectedLat;
  final double selectedLng;

  RealMapPainter({
    required this.centerLat,
    required this.centerLng,
    required this.zoom,
    required this.selectedLat,
    required this.selectedLng,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw base map pattern
    _drawMapTiles(canvas, size);

    // Draw roads
    _drawRoads(canvas, size);

    // Draw landmarks
    _drawLandmarks(canvas, size);

    // Draw grid
    _drawGrid(canvas, size);
  }

  void _drawMapTiles(Canvas canvas, Size size) {
    // Simulate map tiles with different colors
    const tileSize = 50.0;
    final colors = [
      Colors.green.shade100,
      Colors.green.shade200,
      Colors.grey.shade100,
      Colors.grey.shade200,
      Colors.blue.shade100,
    ];

    for (double x = 0; x < size.width; x += tileSize) {
      for (double y = 0; y < size.height; y += tileSize) {
        final color = colors[((x + y) / tileSize).floor() % colors.length];
        final rect = Rect.fromLTWH(x, y, tileSize, tileSize);
        canvas.drawRect(rect, Paint()..color = color);
      }
    }
  }

  void _drawRoads(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Main roads
    canvas.drawLine(Offset(0, size.height * 0.3),
        Offset(size.width, size.height * 0.3), roadPaint);
    canvas.drawLine(Offset(0, size.height * 0.7),
        Offset(size.width, size.height * 0.7), roadPaint);
    canvas.drawLine(Offset(size.width * 0.3, 0),
        Offset(size.width * 0.3, size.height), roadPaint);
    canvas.drawLine(Offset(size.width * 0.7, 0),
        Offset(size.width * 0.7, size.height), roadPaint);

    // Secondary roads
    final secondaryRoadPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(0, size.height * 0.5),
        Offset(size.width, size.height * 0.5), secondaryRoadPaint);
    canvas.drawLine(Offset(size.width * 0.5, 0),
        Offset(size.width * 0.5, size.height), secondaryRoadPaint);
  }

  void _drawLandmarks(Canvas canvas, Size size) {
    // Draw buildings
    final buildingPaint = Paint()
      ..color = Colors.grey.shade600
      ..style = PaintingStyle.fill;

    // Office buildings
    canvas.drawRect(Rect.fromLTWH(size.width * 0.2, size.height * 0.2, 40, 60),
        buildingPaint);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.6, size.height * 0.3, 50, 70),
        buildingPaint);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.4, size.height * 0.6, 45, 55),
        buildingPaint);

    // Park areas
    final parkPaint = Paint()
      ..color = Colors.green.shade300
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
        Offset(size.width * 0.8, size.height * 0.8), 30, parkPaint);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.05)
      ..strokeWidth = 0.5;

    // Draw coordinate grid
    for (double i = 0; i < size.width; i += 20) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double i = 0; i < size.height; i += 20) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
