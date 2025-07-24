import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ProductionMapPicker extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final double initialRadius;
  final Function(double latitude, double longitude, double radius)
      onLocationSelected;

  const ProductionMapPicker({
    Key? key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialRadius = 100.0,
    required this.onLocationSelected,
  }) : super(key: key);

  @override
  State<ProductionMapPicker> createState() => _ProductionMapPickerState();
}

class _ProductionMapPickerState extends State<ProductionMapPicker> {
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _addressController = TextEditingController();
  double _radius = 100.0;
  String _address = '';
  bool _isLoadingAddress = false;
  bool _isLoadingLocation = false;
  bool _isMapExpanded = false;
  late WebViewController _controller;
  double _selectedLat = 37.421998;
  double _selectedLng = -122.08400;

  @override
  void initState() {
    super.initState();
    _radius = widget.initialRadius;

    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedLat = widget.initialLatitude!;
      _selectedLng = widget.initialLongitude!;
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

    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {
            // Page started loading.
          },
          onPageFinished: (String url) {
            // Page finished loading.
            _injectMapScript();
          },
        ),
      )
      ..loadRequest(Uri.parse('https://www.openstreetmap.org/'));
  }

  void _injectMapScript() {
    final script = '''
      // Clear the page and create our custom map interface
      document.body.innerHTML = '';
      document.body.style.margin = '0';
      document.body.style.padding = '0';
      document.body.style.overflow = 'hidden';
      
      // Create container
      const container = document.createElement('div');
      container.style.cssText = 'width: 100vw; height: 100vh; position: relative;';
      
      // Create map container
      const mapContainer = document.createElement('div');
      mapContainer.id = 'map';
      mapContainer.style.cssText = 'width: 100%; height: 100%; position: relative; background: #f0f0f0;';
      
      // Add OpenStreetMap tiles
      const mapUrl = \`https://tile.openstreetmap.org/15/\${Math.floor($_selectedLat)}\${Math.floor($_selectedLng)}/\${Math.floor(($_selectedLat % 1) * 256)}/\${Math.floor(($_selectedLng % 1) * 256)}.png\`;
      
      // Create map background with multiple tiles
      for (let i = 0; i < 3; i++) {
        for (let j = 0; j < 3; j++) {
          const tile = document.createElement('div');
          tile.style.cssText = \`
            position: absolute;
            top: \${i * 256}px;
            left: \${j * 256}px;
            width: 256px;
            height: 256px;
            background: url('https://tile.openstreetmap.org/15/\${Math.floor($_selectedLat + i * 0.01)}\${Math.floor($_selectedLng + j * 0.01)}/\${Math.floor(($_selectedLat + i * 0.01) % 1) * 256)}/\${Math.floor(($_selectedLng + j * 0.01) % 1) * 256)}.png');
            background-size: cover;
          \`;
          mapContainer.appendChild(tile);
        }
      }
      
      // Add location pin
      const pin = document.createElement('div');
      pin.style.cssText = \`
        position: absolute;
        top: 50%;
        left: 50%;
        transform: translate(-50%, -50%);
        width: 32px;
        height: 32px;
        background: red;
        border-radius: 50% 50% 50% 0;
        transform: translate(-50%, -50%) rotate(-45deg);
        border: 2px solid white;
        box-shadow: 0 2px 4px rgba(0,0,0,0.3);
        cursor: pointer;
        z-index: 1000;
      \`;
      
      // Add pin dot
      const pinDot = document.createElement('div');
      pinDot.style.cssText = \`
        position: absolute;
        top: 50%;
        left: 50%;
        transform: translate(-50%, -50%);
        width: 8px;
        height: 8px;
        background: white;
        border-radius: 50%;
      \`;
      pin.appendChild(pinDot);
      
      // Add radius circle
      const radius = document.createElement('div');
      radius.style.cssText = \`
        position: absolute;
        top: 50%;
        left: 50%;
        transform: translate(-50%, -50%);
        width: \${$_radius * 2}px;
        height: \${$_radius * 2}px;
        border: 2px solid rgba(0, 123, 255, 0.6);
        border-radius: 50%;
        background: rgba(0, 123, 255, 0.1);
        pointer-events: none;
        z-index: 999;
      \`;
      
      // Add coordinates display
      const coords = document.createElement('div');
      coords.style.cssText = \`
        position: absolute;
        bottom: 20px;
        left: 20px;
        background: rgba(0,0,0,0.8);
        color: white;
        padding: 10px;
        border-radius: 8px;
        font-family: monospace;
        font-size: 14px;
        z-index: 1001;
      \`;
      coords.textContent = \`Lat: \${$_selectedLat.toFixed(6)} | Lng: \${$_selectedLng.toFixed(6)}\`;
      
      // Add radius display
      const radiusDisplay = document.createElement('div');
      radiusDisplay.style.cssText = \`
        position: absolute;
        bottom: 20px;
        right: 20px;
        background: rgba(0, 123, 255, 0.9);
        color: white;
        padding: 10px;
        border-radius: 8px;
        font-weight: bold;
        z-index: 1001;
      \`;
      radiusDisplay.textContent = \`Radius: \${$_radius}m\`;
      
      // Add click handler
      mapContainer.addEventListener('click', function(e) {
        if (e.target === mapContainer) {
          const rect = mapContainer.getBoundingClientRect();
          const x = e.clientX - rect.left;
          const y = e.clientY - rect.top;
          
          // Convert click to coordinates (simplified)
          const latOffset = (y - rect.height/2) * 0.001;
          const lngOffset = (x - rect.width/2) * 0.001;
          
          const newLat = $_selectedLat - latOffset;
          const newLng = $_selectedLng + lngOffset;
          
          coords.textContent = \`Lat: \${newLat.toFixed(6)} | Lng: \${newLng.toFixed(6)}\`;
          window.flutter_inappwebview.callHandler('locationSelected', newLat, newLng);
        }
      });
      
      // Add instructions
      const instructions = document.createElement('div');
      instructions.style.cssText = \`
        position: absolute;
        top: 20px;
        left: 50%;
        transform: translateX(-50%);
        background: rgba(0,0,0,0.8);
        color: white;
        padding: 12px 20px;
        border-radius: 20px;
        font-size: 14px;
        z-index: 1001;
      \`;
      instructions.textContent = 'Click anywhere on the map to select location';
      
      mapContainer.appendChild(pin);
      mapContainer.appendChild(radius);
      mapContainer.appendChild(coords);
      mapContainer.appendChild(radiusDisplay);
      mapContainer.appendChild(instructions);
      
      container.appendChild(mapContainer);
      document.body.appendChild(container);
      
      // Function to update location
      window.updateLocation = function(lat, lng) {
        coords.textContent = \`Lat: \${lat.toFixed(6)} | Lng: \${lng.toFixed(6)}\`;
        window.flutter_inappwebview.callHandler('locationSelected', lat, lng);
      };
    ''';

    _controller.runJavaScript(script);
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
        _latController.text = position.latitude.toStringAsFixed(6);
        _lngController.text = position.longitude.toStringAsFixed(6);
      });

      _injectMapScript();
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
      _latController.text = '37.421998';
      _lngController.text = '-122.08400';
    });
    _injectMapScript();
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
          _address = address;
          _addressController.text = address;
        });
      } else {
        setState(() {
          _address = 'Address not available';
          _addressController.text = '';
        });
      }
    } catch (e) {
      setState(() {
        _address = 'Address lookup failed';
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

  void _onLocationSelected(double lat, double lng) {
    setState(() {
      _selectedLat = lat;
      _selectedLng = lng;
      _latController.text = lat.toStringAsFixed(6);
      _lngController.text = lng.toStringAsFixed(6);
    });
    _getAddressFromCoordinates();
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
              color: Colors.black.withOpacity(0.1),
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
                    color: Colors.grey.withOpacity(0.1),
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
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.map, color: Colors.blue, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Select Location on Real Map',
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
                        color: Colors.grey.withOpacity(0.1),
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
                            // Real Map WebView
                            WebViewWidget(controller: _controller),

                            // Map Controls
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
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
                            color: Colors.blue.withOpacity(0.1),
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
                        inactiveTrackColor: Colors.blue.withOpacity(0.2),
                        thumbColor: Colors.blue,
                        overlayColor: Colors.blue.withOpacity(0.1),
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
                          _injectMapScript();
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
                                  color: Colors.blue.withOpacity(0.5)),
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
