import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class WebMapPicker extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final double initialRadius;
  final Function(double latitude, double longitude, double radius)
      onLocationSelected;

  const WebMapPicker({
    Key? key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialRadius = 100.0,
    required this.onLocationSelected,
  }) : super(key: key);

  @override
  State<WebMapPicker> createState() => _WebMapPickerState();
}

class _WebMapPickerState extends State<WebMapPicker> {
  late WebViewController _controller;
  double _radius = 100.0;
  String _address = '';
  bool _isLoadingAddress = false;
  bool _isLoadingLocation = false;
  double? _selectedLatitude;
  double? _selectedLongitude;

  @override
  void initState() {
    super.initState();
    _radius = widget.initialRadius;
    _selectedLatitude = widget.initialLatitude;
    _selectedLongitude = widget.initialLongitude;

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
      ..loadRequest(Uri.parse('https://www.google.com/maps'));
  }

  void _injectMapScript() {
    final lat = _selectedLatitude ?? -33.8688;
    final lng = _selectedLongitude ?? 151.2093;

    final script = '''
      // Create a simple map interface
      document.body.innerHTML = '';
      
      const container = document.createElement('div');
      container.style.cssText = 'width: 100%; height: 100vh; position: relative;';
      
      const mapDiv = document.createElement('div');
      mapDiv.style.cssText = 'width: 100%; height: 100%; background: #f0f0f0; position: relative;';
      
      const overlay = document.createElement('div');
      overlay.style.cssText = 'position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); text-align: center; z-index: 1000;';
      overlay.innerHTML = \`
        <div style="background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1);">
          <h3 style="margin: 0 0 10px 0;">Interactive Map</h3>
          <p style="margin: 0 0 15px 0; color: #666;">Click anywhere on the map to select a location</p>
          <div style="display: flex; gap: 10px; justify-content: center;">
            <button onclick="selectLocation($lat, $lng)" style="padding: 8px 16px; background: #007bff; color: white; border: none; border-radius: 4px; cursor: pointer;">Use Current</button>
            <button onclick="window.flutter_inappwebview.callHandler('locationSelected', $lat, $lng)" style="padding: 8px 16px; background: #28a745; color: white; border: none; border-radius: 4px; cursor: pointer;">Confirm</button>
          </div>
        </div>
      \`;
      
      const coordinates = document.createElement('div');
      coordinates.style.cssText = 'position: absolute; bottom: 20px; left: 20px; background: rgba(0,0,0,0.8); color: white; padding: 10px; border-radius: 4px; font-family: monospace;';
      coordinates.textContent = \`Lat: \${$lat.toFixed(6)} | Lng: \${$lng.toFixed(6)}\`;
      
      const radius = document.createElement('div');
      radius.style.cssText = 'position: absolute; bottom: 20px; right: 20px; background: rgba(0,123,255,0.8); color: white; padding: 10px; border-radius: 4px;';
      radius.textContent = \`Radius: \${$_radius}m\`;
      
      mapDiv.appendChild(overlay);
      mapDiv.appendChild(coordinates);
      mapDiv.appendChild(radius);
      
      // Add click handler
      mapDiv.addEventListener('click', function(e) {
        if (e.target === mapDiv) {
          const rect = mapDiv.getBoundingClientRect();
          const x = e.clientX - rect.left;
          const y = e.clientY - rect.top;
          
          // Convert click to coordinates (simplified)
          const lat = $lat + (y - rect.height/2) * 0.001;
          const lng = $lng + (x - rect.width/2) * 0.001;
          
          coordinates.textContent = \`Lat: \${lat.toFixed(6)} | Lng: \${lng.toFixed(6)}\`;
          window.flutter_inappwebview.callHandler('locationSelected', lat, lng);
        }
      });
      
      container.appendChild(mapDiv);
      document.body.appendChild(container);
      
      function selectLocation(lat, lng) {
        coordinates.textContent = \`Lat: \${lat.toFixed(6)} | Lng: \${lng.toFixed(6)}\`;
        window.flutter_inappwebview.callHandler('locationSelected', lat, lng);
      }
    ''';

    _controller.runJavaScript(script);
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
        _selectedLatitude = position.latitude;
        _selectedLongitude = position.longitude;
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
      _selectedLatitude = -33.8688;
      _selectedLongitude = 151.2093;
    });
    _injectMapScript();
    _getAddressFromCoordinates();
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
      _selectedLatitude = lat;
      _selectedLongitude = lng;
    });
    _getAddressFromCoordinates();
  }

  void _confirmLocation() {
    if (_selectedLatitude != null && _selectedLongitude != null) {
      widget.onLocationSelected(
          _selectedLatitude!, _selectedLongitude!, _radius);
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location first')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Location on Map',
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
                  child: WebViewWidget(controller: _controller),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Address Display
            if (_address.isNotEmpty)
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
                          : Text(_address),
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
                    onChanged: (value) {
                      setState(() {
                        _radius = value;
                      });
                      _injectMapScript();
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

            const SizedBox(height: 16),

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
