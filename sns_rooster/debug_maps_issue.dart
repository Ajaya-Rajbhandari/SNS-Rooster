import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapsDebugScreen extends StatefulWidget {
  const MapsDebugScreen({Key? key}) : super(key: key);

  @override
  State<MapsDebugScreen> createState() => _MapsDebugScreenState();
}

class _MapsDebugScreenState extends State<MapsDebugScreen> {
  GoogleMapController? _mapController;
  bool _isLoading = true;
  String _debugInfo = '';
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    try {
      setState(() {
        _debugInfo = 'Initializing map...\n';
      });

      // Check location permissions
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission permission = await Geolocator.checkPermission();

      setState(() {
        _debugInfo += 'Location Service Enabled: $serviceEnabled\n';
        _debugInfo += 'Location Permission: $permission\n';
      });

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _debugInfo +=
            'Current Position: ${position.latitude}, ${position.longitude}\n';
        _markers = {
          Marker(
            markerId: const MarkerId('current_location'),
            position: LatLng(position.latitude, position.longitude),
            infoWindow: const InfoWindow(
              title: 'Current Location',
              snippet: 'Your current position',
            ),
          ),
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _debugInfo += 'Error: ${e.toString()}\n';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maps Debug'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Debug Info Panel
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Debug Information:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _debugInfo,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Map Container
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading map...'),
                      ],
                    ),
                  )
                : GoogleMap(
                    onMapCreated: (GoogleMapController controller) {
                      _mapController = controller;
                      setState(() {
                        _debugInfo += 'Map created successfully!\n';
                      });
                    },
                    initialCameraPosition: const CameraPosition(
                      target: LatLng(27.700239, 85.333336), // Kathmandu
                      zoom: 15,
                    ),
                    markers: _markers,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    zoomControlsEnabled: true,
                    mapToolbarEnabled: true,
                    onCameraMove: (CameraPosition position) {
                      setState(() {
                        _debugInfo +=
                            'Camera moved to: ${position.target.latitude}, ${position.target.longitude}\n';
                      });
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _debugInfo = ''; // Clear debug info
          });
          _initializeMap();
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
