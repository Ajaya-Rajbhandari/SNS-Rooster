import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sns_rooster/providers/auth_provider.dart';
import 'package:sns_rooster/providers/feature_provider.dart';
import 'package:sns_rooster/services/api_service.dart';
import 'package:sns_rooster/config/api_config.dart';
import 'package:sns_rooster/widgets/admin_side_navigation.dart';
import 'package:sns_rooster/widgets/location_list_item.dart';
import 'package:sns_rooster/widgets/google_maps_location_widget.dart';
import 'package:sns_rooster/widgets/web_google_maps_widget.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sns_rooster/utils/logger.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shimmer/shimmer.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sns_rooster/widgets/company_style_location_picker.dart';
import 'package:sns_rooster/widgets/employee_assignment_dialog.dart';
import 'package:sns_rooster/services/location_settings_service.dart';
import 'package:sns_rooster/utils/test_location_settings_connection.dart';
import 'package:sns_rooster/utils/test_subscription_features.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

class LocationManagementScreen extends StatefulWidget {
  const LocationManagementScreen({super.key});

  @override
  State<LocationManagementScreen> createState() =>
      _LocationManagementScreenState();
}

class _LocationManagementScreenState extends State<LocationManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _countryController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _capacityController = TextEditingController(text: '50');
  final _gracePeriodController = TextEditingController(text: '15');
  final _timezoneController = TextEditingController(text: 'UTC');
  final _startTimeController = TextEditingController(text: '09:00');
  final _endTimeController = TextEditingController(text: '17:00');
  final _descriptionController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _searchController = TextEditingController();

  List<Map<String, dynamic>> _locations = [];
  List<Map<String, dynamic>> _filteredLocations = [];
  bool _isLoading = false;
  bool _isCreating = false;
  Map<String, dynamic>? _editingLocation;

  // Location related variables
  double? _selectedLatitude;
  double? _selectedLongitude;
  double _geofenceRadius = 100.0;
  bool _isLoadingLocation = false;
  bool _isLoadingAddress = false;
  bool _isCreatingLocation = false;
  bool _isSearching = false;
  bool _showSearchResults = false;
  List<Placemark> _searchResults = [];
  bool _useCustomCoordinates = false;
  bool _showCreateForm = false;
  bool _showMap = false;
  bool _showMapPreview = false;
  final MapController _mapController = MapController();
  final LocationSettingsService _locationSettingsService =
      LocationSettingsService();

  // Settings state variables
  int _defaultGeofenceRadius = 100;
  String _defaultStartTime = '09:00';
  String _defaultEndTime = '17:00';
  int _defaultCapacity = 50;
  bool _locationUpdatesEnabled = true;
  bool _employeeAssignmentsEnabled = true;
  bool _capacityAlertsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadLocations();
    _getCurrentLocation();
    _loadLocationSettings();

    // Test backend connection for debugging
    LocationSettingsConnectionTest.testConnection();

    // Test subscription features for debugging
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final featureProvider =
          Provider.of<FeatureProvider>(context, listen: false);

      SubscriptionFeaturesTest.testSubscriptionFeatures(featureProvider);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _capacityController.dispose();
    _gracePeriodController.dispose();
    _timezoneController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _descriptionController.dispose();
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
      // Skip location service on web for now
      if (kIsWeb) {
        // Set default coordinates for web testing
        setState(() {
          _selectedLatitude = -33.8688; // Sydney coordinates
          _selectedLongitude = 151.2093;
          _isLoadingLocation = false;
        });
        return;
      }

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
        _isLoadingLocation = false;
      });
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
      _isLoadingLocation = false;
    });
  }

  Future<void> _loadLocations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ApiService(baseUrl: ApiConfig.baseUrl);

      // Debug: Check if we have authentication
      final authHeader = await apiService.getAuthorizationHeader();
      Logger.info('Auth header: $authHeader');
      Logger.info('API Base URL: ${ApiConfig.baseUrl}');

      // Check if user is authenticated
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      Logger.info('User authenticated: ${authProvider.isAuthenticated}');
      Logger.info('User role: ${authProvider.user?['role']}');
      Logger.info('User company ID: ${authProvider.user?['companyId']}');

      final response = await apiService.get('/locations');

      if (response.success) {
        setState(() {
          _locations =
              List<Map<String, dynamic>>.from(response.data['locations'] ?? []);
          _filteredLocations = _locations; // Initialize filtered list
        });
        Logger.info('Successfully loaded ${_locations.length} locations');
      } else {
        Logger.error('Failed to load locations: ${response.message}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(response.message ?? 'Failed to load locations')),
        );

        // Set empty list to show the empty state
        setState(() {
          _locations = [];
          _filteredLocations = [];
        });
      }
    } catch (e) {
      Logger.error('Error loading locations: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error loading locations')),
      );

      // Set empty list to show the empty state
      setState(() {
        _locations = [];
        _filteredLocations = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedLatitude == null || _selectedLongitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set location coordinates')),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final apiService = ApiService(baseUrl: ApiConfig.baseUrl);

      // Get the current user ID for createdBy field
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUserId =
          authProvider.user?['_id'] ?? authProvider.user?['id'];

      // Debug logging
      Logger.info('Current user ID: $currentUserId');
      Logger.info('User authenticated: ${authProvider.isAuthenticated}');
      Logger.info('User data: ${authProvider.user}');

      // Check if we have a valid user ID
      if (currentUserId == null) {
        Logger.error('No valid user ID found for createdBy field');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Authentication error. Please log in again.')),
        );
        return;
      }

      final locationData = {
        'name': _nameController.text.trim(),
        'address': {
          'street': _streetController.text.trim(),
          'city': _cityController.text.trim(),
          'state': _stateController.text.trim(),
          'postalCode': _postalCodeController.text.trim(),
          'country': _countryController.text.trim(),
        },
        'coordinates': {
          'latitude': _selectedLatitude,
          'longitude': _selectedLongitude,
        },
        'contactInfo': {
          'phone': _phoneController.text.trim(),
          'email': _emailController.text.trim(),
        },
        'settings': {
          'capacity': int.tryParse(_capacityController.text) ?? 50,
          'geofenceRadius': _geofenceRadius,
          'gracePeriod': int.tryParse(_gracePeriodController.text) ?? 15,
          'timezone': _timezoneController.text.trim(),
          'workingHours': {
            'start': _startTimeController.text.trim(),
            'end': _endTimeController.text.trim(),
          },
        },
        'description': _descriptionController.text.trim(),
        'createdBy': currentUserId, // Add the createdBy field
      };

      // Debug logging for location data
      Logger.info('Location data being sent: $locationData');

      ApiResponse response;

      if (_editingLocation != null) {
        // Update existing location
        response = await apiService.put(
            '/locations/${_editingLocation!['_id']}', locationData);
        Logger.info('Update response success: ${response.success}');
        Logger.info('Update response message: ${response.message}');
      } else {
        // Create new location
        response = await apiService.post('/locations', locationData);
        Logger.info('Create response success: ${response.success}');
        Logger.info('Create response message: ${response.message}');
      }

      // Debug logging for response
      Logger.info('Server response data: ${response.data}');

      if (response.success) {
        final message = _editingLocation != null
            ? 'Location updated successfully!'
            : 'Location created successfully!';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        _hideCreateForm();
        _loadLocations();
      } else {
        final action = _editingLocation != null ? 'updating' : 'creating';
        Logger.error('Location $action failed: ${response.message}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(response.message ?? 'Failed to ${action} location')),
        );
      }
    } catch (e) {
      final action = _editingLocation != null ? 'updating' : 'creating';
      Logger.error('Error $action location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error $action location')),
      );
    } finally {
      setState(() {
        _isCreating = false;
      });
    }
  }

  void _showInteractiveMapPicker() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CompanyStyleLocationPicker(
          initialLatitude: _selectedLatitude,
          initialLongitude: _selectedLongitude,
          initialRadius: _geofenceRadius,
          onLocationSelected: (latitude, longitude, radius) {
            setState(() {
              _selectedLatitude = latitude;
              _selectedLongitude = longitude;
              _geofenceRadius = radius;
            });

            // Auto-fill coordinates
            _latController.text = latitude.toStringAsFixed(6);
            _lngController.text = longitude.toStringAsFixed(6);

            // Get address from coordinates
            _getAddressFromCoordinates();
          },
        ),
      ),
    );
  }

  void _showCreateLocationDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.9,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Create New Location',
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
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Location Selection Section
                        const Text(
                          'Location Selection',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),

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
                                  fontSize: 14,
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
                                  prefixIcon: const Icon(Icons.search,
                                      color: Colors.blue),
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
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border:
                                        Border.all(color: Colors.grey.shade200),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
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
                                                    CircularProgressIndicator(
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
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
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
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  subtitle: Text(
                                                    placemark.country ?? '',
                                                    style: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontSize: 12),
                                                  ),
                                                  onTap: () =>
                                                      _selectSearchResult(
                                                          placemark),
                                                );
                                              },
                                            ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Location Methods Section
                        Row(
                          children: [
                            Expanded(
                              child: _buildMethodCard(
                                icon: Icons.my_location,
                                title: 'Current Location',
                                subtitle: 'Use GPS location',
                                onTap: _isLoadingLocation
                                    ? null
                                    : _getCurrentLocation,
                                isLoading: _isLoadingLocation,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildMethodCard(
                                icon: Icons.map,
                                title: 'Interactive Map',
                                subtitle: 'Select on map',
                                onTap: _showInteractiveMapPicker,
                                color: Colors.purple,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMethodCard(
                                icon: Icons.edit_location,
                                title: 'Custom Coordinates',
                                subtitle: 'Enter manually',
                                onTap: () {
                                  setState(() {
                                    _useCustomCoordinates =
                                        !_useCustomCoordinates;
                                  });
                                },
                                isSelected: _useCustomCoordinates,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),

                        if (_useCustomCoordinates) ...[
                          const SizedBox(height: 12),
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
                                  'Enter Coordinates',
                                  style: TextStyle(
                                    fontSize: 14,
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
                                        onChanged: (_) =>
                                            _onCoordinatesChanged(),
                                        decoration: const InputDecoration(
                                          labelText: 'Latitude',
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _lngController,
                                        onChanged: (_) =>
                                            _onCoordinatesChanged(),
                                        decoration: const InputDecoration(
                                          labelText: 'Longitude',
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],

                        if (_selectedLatitude != null &&
                            _selectedLongitude != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle,
                                    color: Colors.green),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Location Set: ${_selectedLatitude!.toStringAsFixed(6)}, ${_selectedLongitude!.toStringAsFixed(6)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),

                        // Geofence Radius Display
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.radio_button_checked,
                                  color: Colors.blue),
                              const SizedBox(width: 8),
                              const Text('Geofence Radius: '),
                              Text(
                                '${_geofenceRadius.round()}m',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title:
                                          const Text('Adjust Geofence Radius'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                              'Current radius: ${_geofenceRadius.round()}m'),
                                          const SizedBox(height: 16),
                                          Slider(
                                            value: _geofenceRadius,
                                            min: 25,
                                            max: 1000,
                                            divisions: 39,
                                            onChanged: (value) {
                                              setState(() {
                                                _geofenceRadius = value;
                                              });
                                            },
                                          ),
                                          Text('${_geofenceRadius.round()}m'),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(),
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(),
                                          child: const Text('OK'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                child: const Text('Adjust'),
                              ),
                            ],
                          ),
                        ),

                        // Basic Information
                        const Text(
                          'Basic Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Location Name *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value?.trim().isEmpty == true) {
                              return 'Location name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Address Information
                        const Text(
                          'Address Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _streetController,
                          decoration: const InputDecoration(
                            labelText: 'Street Address *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value?.trim().isEmpty == true) {
                              return 'Street address is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _cityController,
                                decoration: const InputDecoration(
                                  labelText: 'City *',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value?.trim().isEmpty == true) {
                                    return 'City is required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _stateController,
                                decoration: const InputDecoration(
                                  labelText: 'State/Province',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _postalCodeController,
                                decoration: const InputDecoration(
                                  labelText: 'Postal Code *',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value?.trim().isEmpty == true) {
                                    return 'Postal code is required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _countryController,
                                decoration: const InputDecoration(
                                  labelText: 'Country *',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value?.trim().isEmpty == true) {
                                    return 'Country is required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Contact Information
                        const Text(
                          'Contact Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _phoneController,
                                decoration: const InputDecoration(
                                  labelText: 'Phone',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _emailController,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Settings
                        const Text(
                          'Settings',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _capacityController,
                                decoration: const InputDecoration(
                                  labelText: 'Capacity',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _gracePeriodController,
                                decoration: const InputDecoration(
                                  labelText: 'Grace Period (min)',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _timezoneController,
                          decoration: const InputDecoration(
                            labelText: 'Timezone',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _startTimeController,
                                decoration: const InputDecoration(
                                  labelText: 'Start Time',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _endTimeController,
                                decoration: const InputDecoration(
                                  labelText: 'End Time',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isCreating ? null : _submitForm,
                    child: _isCreating
                        ? const CircularProgressIndicator()
                        : Text(_editingLocation != null ? 'Update' : 'Create'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Location selection methods integrated into the form

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

        // Auto-fill address fields
        _streetController.text = placemark.street ?? '';
        _cityController.text = placemark.locality ?? '';
        _stateController.text = placemark.administrativeArea ?? '';
        _postalCodeController.text = placemark.postalCode ?? '';
        _countryController.text = placemark.country ?? '';

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
        // Auto-fill address fields if they're empty
        if (_streetController.text.isEmpty)
          _streetController.text = place.street ?? '';
        if (_cityController.text.isEmpty)
          _cityController.text = place.locality ?? '';
        if (_stateController.text.isEmpty)
          _stateController.text = place.administrativeArea ?? '';
        if (_postalCodeController.text.isEmpty)
          _postalCodeController.text = place.postalCode ?? '';
        if (_countryController.text.isEmpty)
          _countryController.text = place.country ?? '';
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Widget _buildMethodCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    bool isLoading = false,
    bool isSelected = false,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    icon,
                    color: isSelected ? color : Colors.grey[600],
                    size: 24,
                  ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Colors.black87,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final featureProvider = Provider.of<FeatureProvider>(context);

    // Check if multi-location feature is available
    if (!featureProvider.isFeatureEnabled('multiLocation')) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Location Management'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blue.shade50, Colors.white],
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_off,
                  size: 80,
                  color: Colors.blue,
                ),
                SizedBox(height: 16),
                Text(
                  'Multi-Location Support',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'This feature is available in Professional and Enterprise plans',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Upgrade your plan to access location management features',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Location Management',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLocations,
          ),
        ],
      ),
      drawer: const AdminSideNavigation(currentRoute: '/location_management'),
      body: RefreshIndicator(
        onRefresh: _loadLocations,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue, Colors.blue.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Manage Your Locations',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Create and manage locations for attendance tracking',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Consumer<FeatureProvider>(
                                builder: (context, featureProvider, child) {
                                  return Text(
                                    'Plan: ${featureProvider.subscriptionPlanName}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _buildStatCard(
                          icon: Icons.location_on,
                          title: 'Total Locations',
                          value: '${_locations.length}',
                          color: Colors.white.withOpacity(0.15),
                          iconColor: Colors.white,
                          textColor: Colors.white,
                        ),
                        const SizedBox(width: 12),
                        _buildStatCard(
                          icon: Icons.check_circle,
                          title: 'Active Locations',
                          value:
                              '${_locations.where((l) => l['status'] == 'active').length}',
                          color: Colors.white.withOpacity(0.15),
                          iconColor: Colors.white,
                          textColor: Colors.white,
                        ),
                        const SizedBox(width: 12),
                        _buildStatCard(
                          icon: Icons.people,
                          title: 'Total Capacity',
                          value:
                              '${_locations.fold<int>(0, (sum, l) => sum + ((l['settings']?['capacity'] ?? 0) as int))}',
                          color: Colors.white.withOpacity(0.15),
                          iconColor: Colors.white,
                          textColor: Colors.white,
                        ),
                        const SizedBox(width: 12),
                        _buildStatCard(
                          icon: Icons.person,
                          title: 'Active Users',
                          value:
                              '${_locations.fold<int>(0, (sum, l) => sum + ((l['activeUsers'] ?? 0) as int))}',
                          color: Colors.white.withOpacity(0.15),
                          iconColor: Colors.white,
                          textColor: Colors.white,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action Bar
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search locations...',
                          prefixIcon:
                              const Icon(Icons.search, color: Colors.grey),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear,
                                      color: Colors.grey),
                                  onPressed: () {
                                    _searchController.clear();
                                    _filterLocations();
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onChanged: (value) => _filterLocations(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Action Buttons
                    Row(
                      children: [
                        // Primary Action Button
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: _showCreateLocationForm,
                            icon: const Icon(Icons.add_location),
                            label: const Text(
                              'Create Location',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                              shadowColor: Colors.blue.withOpacity(0.3),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Map View Button
                        Expanded(
                          flex: 1,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _showMapPreview = !_showMapPreview;
                              });
                            },
                            icon:
                                Icon(_showMapPreview ? Icons.list : Icons.map),
                            label: Text(_showMapPreview ? 'List' : 'Map'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor:
                                  _showMapPreview ? Colors.white : Colors.blue,
                              backgroundColor: _showMapPreview
                                  ? Colors.blue
                                  : Colors.transparent,
                              side: BorderSide(
                                  color: _showMapPreview
                                      ? Colors.blue
                                      : Colors.blue),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Actions Menu Button
                        if (_locations.isNotEmpty)
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              onPressed: () {
                                _showActionsMenu(context);
                              },
                              icon: const Icon(Icons.more_vert),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.all(16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Create Form or Locations List
              Consumer<FeatureProvider>(
                builder: (context, featureProvider, child) {
                  if (!featureProvider.hasLocationManagement) {
                    return _buildFeatureUnavailableState();
                  }

                  return _showCreateForm
                      ? _buildCreateForm()
                      : _isLoading
                          ? _buildLoadingShimmer()
                          : _filteredLocations.isEmpty
                              ? _buildEmptyState()
                              : _buildLocationsList();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    Color? iconColor,
    Color? textColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: iconColor ?? Colors.blue,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor ?? Colors.black87,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: iconColor ?? Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return Column(
      children: List.generate(3, (index) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_off,
              size: 80,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Locations Found',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first location to get started with attendance tracking',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _showCreateLocationForm,
            icon: const Icon(Icons.add_location),
            label: const Text('Create First Location'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureUnavailableState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock,
              size: 80,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Location Management Unavailable',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Location management features are not available in your current subscription plan.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              children: [
                const Text(
                  'Available Plans:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                const Text('• Professional: Basic location management'),
                const Text('• Enterprise: Advanced location features'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    _showUpgradeDialog('Location Management');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Learn More'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationsList() {
    if (_showMapPreview) {
      return SingleChildScrollView(
        child: Column(
          children: [
            // Map Preview
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                height: 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                  color: Colors.grey.shade100,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      // Google Maps - Use web-specific widget for web, original widget for mobile
                      kIsWeb
                          ? WebGoogleMapsWidget(
                              locations: _filteredLocations,
                              height: 300,
                              onMarkerTap: (location) {
                                _showLocationDetails(location);
                              },
                              onMapTap: () {
                                // Handle map tap if needed
                              },
                            )
                          : GoogleMapsLocationWidget(
                              locations: _filteredLocations,
                              height: 300,
                              onMarkerTap: (location) {
                                _showLocationDetails(location);
                              },
                              onMapTap: () {
                                // Handle map tap if needed
                              },
                            ),
                    ],
                  ),
                ),
              ),
            ),
            // Locations List below map
            AnimationLimiter(
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filteredLocations.length,
                itemBuilder: (context, index) {
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: LocationListItem(
                          location: _filteredLocations[index],
                          onEdit: () {
                            _editLocation(_filteredLocations[index]);
                          },
                          onDelete: () {
                            _deleteLocation(_filteredLocations[index]);
                          },
                          onAssign: () {
                            _showEmployeeAssignmentDialog(
                                _filteredLocations[index]);
                          },
                          onTap: () {
                            // TODO: Implement view details functionality
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20), // Bottom padding
          ],
        ),
      );
    }

    // Original list view when map preview is disabled
    return AnimationLimiter(
      child: Column(
        children: List.generate(_filteredLocations.length, (index) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: LocationListItem(
                    location: _filteredLocations[index],
                    onEdit: () {
                      _editLocation(_filteredLocations[index]);
                    },
                    onDelete: () {
                      _deleteLocation(_filteredLocations[index]);
                    },
                    onAssign: () {
                      _showEmployeeAssignmentDialog(_filteredLocations[index]);
                    },
                    onTap: () {
                      // TODO: Implement view details functionality
                    },
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  void _showCreateLocationForm() {
    print('Creating location form with settings:');
    print('  - Default Capacity: $_defaultCapacity');
    print('  - Default Geofence Radius: $_defaultGeofenceRadius');
    print('  - Default Start Time: $_defaultStartTime');
    print('  - Default End Time: $_defaultEndTime');

    // Reset form
    _formKey.currentState?.reset();
    _nameController.clear();
    _streetController.clear();
    _cityController.clear();
    _stateController.clear();
    _postalCodeController.clear();
    _countryController.clear();
    _phoneController.clear();
    _emailController.clear();

    // Use loaded settings from backend instead of hardcoded values
    _capacityController.text = _defaultCapacity.toString();
    _geofenceRadius = _defaultGeofenceRadius.toDouble();
    _gracePeriodController.text = '15';
    _timezoneController.text = 'UTC';
    _startTimeController.text = _defaultStartTime;
    _endTimeController.text = _defaultEndTime;

    _descriptionController.clear();
    _latController.clear();
    _lngController.clear();
    _searchController.clear();
    _selectedLatitude = null;
    _selectedLongitude = null;
    _showSearchResults = false;
    _useCustomCoordinates = false;

    setState(() {
      _showCreateForm = true;
    });

    print('Form created with backend settings applied');
  }

  void _hideCreateForm() {
    setState(() {
      _showCreateForm = false;
      _editingLocation = null; // Reset editing state
    });
  }

  void _showActionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.refresh, color: Colors.blue),
              title: const Text('Refresh Locations'),
              onTap: () {
                Navigator.pop(context);
                _loadLocations();
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_download, color: Colors.green),
              title: const Text('Export Data'),
              onTap: () {
                Navigator.pop(context);
                _exportLocationData();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.orange),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                _showLocationSettings();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEmployeeAssignmentDialog(Map<String, dynamic> location) {
    showDialog(
      context: context,
      builder: (context) => EmployeeAssignmentDialog(
        location: location,
        onAssign: (employeeId) async {
          await _assignEmployeeToLocation(employeeId, location['_id']);
        },
        onRemove: (employeeId) async {
          await _removeEmployeeFromLocation(employeeId, location['_id']);
        },
        onChangeLocation: (employeeId, newLocationId) async {
          await _changeEmployeeLocation(employeeId, newLocationId);
        },
      ),
    );
  }

  Future<void> _assignEmployeeToLocation(
      String employeeId, String locationId) async {
    try {
      final apiService = ApiService(baseUrl: ApiConfig.baseUrl);
      final response = await apiService.put(
        '/employees/$employeeId/location',
        {'locationId': locationId},
      );

      if (response.success) {
        // Send notification to company admins about the assignment
        await _sendLocationAssignmentNotification(employeeId, locationId);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Employee assigned to location successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Failed to assign employee'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error assigning employee: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildCreateForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.blue, Colors.blueAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add_location,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _editingLocation != null
                              ? 'Edit Location'
                              : 'Create New Location',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _editingLocation != null
                              ? 'Update location details and settings'
                              : 'Add a new location for attendance tracking',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _hideCreateForm,
                    icon: Container(
                      padding: const EdgeInsets.all(8),
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

            const SizedBox(height: 20),

            // Location Selection Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Location Selection',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

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
                            fontSize: 14,
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
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
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
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.blue
                                                    .withOpacity(0.1),
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
                                                  fontWeight: FontWeight.w500),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            subtitle: Text(
                                              placemark.country ?? '',
                                              style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 12),
                                            ),
                                            onTap: () =>
                                                _selectSearchResult(placemark),
                                          );
                                        },
                                      ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Location Methods Section
                  Row(
                    children: [
                      Expanded(
                        child: _buildMethodCard(
                          icon: Icons.my_location,
                          title: 'Current Location',
                          subtitle: 'Use GPS location',
                          onTap:
                              _isLoadingLocation ? null : _getCurrentLocation,
                          isLoading: _isLoadingLocation,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMethodCard(
                          icon: Icons.map,
                          title: 'Interactive Map',
                          subtitle: 'Select on map',
                          onTap: _showInteractiveMapPicker,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMethodCard(
                          icon: Icons.edit_location,
                          title: 'Custom Coordinates',
                          subtitle: 'Enter manually',
                          onTap: () {
                            setState(() {
                              _useCustomCoordinates = !_useCustomCoordinates;
                            });
                          },
                          isSelected: _useCustomCoordinates,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),

                  if (_useCustomCoordinates) ...[
                    const SizedBox(height: 16),
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
                            'Enter Coordinates',
                            style: TextStyle(
                              fontSize: 14,
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
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (_selectedLatitude != null &&
                      _selectedLongitude != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Location Set: ${_selectedLatitude!.toStringAsFixed(6)}, ${_selectedLongitude!.toStringAsFixed(6)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Geofence Radius
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.radio_button_checked,
                            color: Colors.blue),
                        const SizedBox(width: 8),
                        const Text('Geofence Radius: '),
                        Text(
                          '${_geofenceRadius.round()}m',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Adjust Geofence Radius'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                        'Current radius: ${_geofenceRadius.round()}m'),
                                    const SizedBox(height: 16),
                                    Slider(
                                      value: _geofenceRadius,
                                      min: 25,
                                      max: 1000,
                                      divisions: 39,
                                      onChanged: (value) {
                                        setState(() {
                                          _geofenceRadius = value;
                                        });
                                      },
                                    ),
                                    Text('${_geofenceRadius.round()}m'),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: const Text('Adjust'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Basic Information
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Basic Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Location Name *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value?.trim().isEmpty == true) {
                        return 'Location name is required';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Address Information
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Address Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _streetController,
                    decoration: const InputDecoration(
                      labelText: 'Street Address *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value?.trim().isEmpty == true) {
                        return 'Street address is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _cityController,
                          decoration: const InputDecoration(
                            labelText: 'City *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value?.trim().isEmpty == true) {
                              return 'City is required';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _stateController,
                          decoration: const InputDecoration(
                            labelText: 'State/Province',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _postalCodeController,
                          decoration: const InputDecoration(
                            labelText: 'Postal Code *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value?.trim().isEmpty == true) {
                              return 'Postal code is required';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _countryController,
                          decoration: const InputDecoration(
                            labelText: 'Country *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value?.trim().isEmpty == true) {
                              return 'Country is required';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Contact Information
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Contact Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Settings
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _capacityController,
                          decoration: const InputDecoration(
                            labelText: 'Capacity',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _gracePeriodController,
                          decoration: const InputDecoration(
                            labelText: 'Grace Period (minutes)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _timezoneController,
                          decoration: const InputDecoration(
                            labelText: 'Timezone',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _startTimeController,
                          decoration: const InputDecoration(
                            labelText: 'Start Time',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _endTimeController,
                          decoration: const InputDecoration(
                            labelText: 'End Time',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Action Buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _hideCreateForm,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isCreating ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        shadowColor: Colors.blue.withOpacity(0.3),
                      ),
                      child: _isCreating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              _editingLocation != null
                                  ? 'Update Location'
                                  : 'Create Location',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _filterLocations() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredLocations = _locations.where((location) {
        final name = location['name']?.toString().toLowerCase() ?? '';
        final address =
            location['address']?['street']?.toString().toLowerCase() ?? '';
        final city =
            location['address']?['city']?.toString().toLowerCase() ?? '';
        final state =
            location['address']?['state']?.toString().toLowerCase() ?? '';
        final postalCode =
            location['address']?['postalCode']?.toString().toLowerCase() ?? '';
        final country =
            location['address']?['country']?.toString().toLowerCase() ?? '';

        return name.contains(query) ||
            address.contains(query) ||
            city.contains(query) ||
            state.contains(query) ||
            postalCode.contains(query) ||
            country.contains(query);
      }).toList();
    });
  }

  void _showLocationDetails(Map<String, dynamic> location) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(location['name'] ?? 'Location Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Address: ${_getLocationAddress(location)}'),
            const SizedBox(height: 8),
            Text('Status: ${location['status'] ?? 'Unknown'}'),
            if (location['settings']?['capacity'] != null)
              Text('Capacity: ${location['settings']['capacity']} people'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement edit functionality
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
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

  void _editLocation(Map<String, dynamic> location) {
    // Store the location being edited
    _editingLocation = location;

    // Populate form with location data
    _nameController.text = location['name'] ?? '';
    _streetController.text = location['address']?['street'] ?? '';
    _cityController.text = location['address']?['city'] ?? '';
    _stateController.text = location['address']?['state'] ?? '';
    _postalCodeController.text = location['address']?['postalCode'] ?? '';
    _countryController.text = location['address']?['country'] ?? '';
    _phoneController.text = location['contactInfo']?['phone'] ?? '';
    _emailController.text = location['contactInfo']?['email'] ?? '';
    _capacityController.text = '${location['settings']?['capacity'] ?? 50}';
    _geofenceRadius =
        (location['settings']?['geofenceRadius'] ?? 100).toDouble();
    _gracePeriodController.text =
        '${location['settings']?['gracePeriod'] ?? 15}';
    _timezoneController.text = location['settings']?['timezone'] ?? 'UTC';
    _startTimeController.text =
        location['settings']?['workingHours']?['start'] ?? '09:00';
    _endTimeController.text =
        location['settings']?['workingHours']?['end'] ?? '17:00';
    _descriptionController.text = location['description'] ?? '';

    // Set coordinates
    if (location['coordinates'] != null) {
      _selectedLatitude = location['coordinates']['latitude']?.toDouble();
      _selectedLongitude = location['coordinates']['longitude']?.toDouble();
      _latController.text = '${_selectedLatitude ?? ''}';
      _lngController.text = '${_selectedLongitude ?? ''}';
    }

    setState(() {
      _showCreateForm = true;
      _isCreating = false; // This is edit mode, not create mode
    });
  }

  void _deleteLocation(Map<String, dynamic> location) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Location'),
        content: Text(
            'Are you sure you want to delete "${location['name']}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performDeleteLocation(location['_id']);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _performDeleteLocation(String locationId) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final apiService = ApiService(baseUrl: ApiConfig.baseUrl);
      final response = await apiService.delete('/locations/$locationId');

      if (response.success) {
        // Remove from local list
        setState(() {
          _locations.removeWhere((location) => location['_id'] == locationId);
          _filterLocations();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Location deleted successfully'),
            backgroundColor: Colors.green.shade600,
          ),
        );
      } else {
        throw Exception(response.message ?? 'Failed to delete location');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting location: ${error.toString()}'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _removeEmployeeFromLocation(
      String employeeId, String locationId) async {
    try {
      final apiService = ApiService(baseUrl: ApiConfig.baseUrl);
      final response =
          await apiService.delete('/employees/$employeeId/location');

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Employee removed from location successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh locations to update counts
        _loadLocations();
      } else {
        throw Exception(response.message ?? 'Failed to remove employee');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error removing employee: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _changeEmployeeLocation(
      String employeeId, String newLocationId) async {
    try {
      final apiService = ApiService(baseUrl: ApiConfig.baseUrl);
      final response = await apiService.put('/employees/$employeeId/location', {
        'locationId': newLocationId,
      });

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Employee location changed successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh locations to update counts
        _loadLocations();
      } else {
        throw Exception(
            response.message ?? 'Failed to change employee location');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Error changing employee location: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadLocationSettings() async {
    try {
      print('Loading location settings from backend...');

      final geofenceRadius =
          await _locationSettingsService.getDefaultGeofenceRadius();
      final workingHours =
          await _locationSettingsService.getDefaultWorkingHours();
      final capacity = await _locationSettingsService.getDefaultCapacity();
      final notifications =
          await _locationSettingsService.getNotificationSettings();

      print('Loaded settings:');
      print('  - Geofence Radius: $geofenceRadius');
      print(
          '  - Working Hours: ${workingHours['start']} - ${workingHours['end']}');
      print('  - Capacity: $capacity');
      print('  - Notifications: $notifications');

      setState(() {
        _defaultGeofenceRadius = geofenceRadius;
        _defaultStartTime = workingHours['start'] ?? '09:00';
        _defaultEndTime = workingHours['end'] ?? '17:00';
        _defaultCapacity = capacity;
        _locationUpdatesEnabled = notifications['locationUpdates'] ?? true;
        _employeeAssignmentsEnabled =
            notifications['employeeAssignments'] ?? true;
        _capacityAlertsEnabled = notifications['capacityAlerts'] ?? false;
      });

      print('Settings loaded successfully and applied to state');
    } catch (error) {
      // Use default values if loading fails
      print('Error loading location settings: $error');
      print('Using default values:');
      print('  - Geofence Radius: $_defaultGeofenceRadius');
      print('  - Working Hours: $_defaultStartTime - $_defaultEndTime');
      print('  - Capacity: $_defaultCapacity');
    }
  }

  Future<void> _exportLocationData() async {
    try {
      print('Starting export process...');

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Prepare data for export
      final exportData = {
        'exportDate': DateTime.now().toIso8601String(),
        'totalLocations': _locations.length,
        'activeLocations':
            _locations.where((l) => l['status'] == 'active').length,
        'totalCapacity': _locations.fold<int>(
            0, (sum, l) => sum + ((l['settings']?['capacity'] ?? 0) as int)),
        'totalActiveUsers': _locations.fold<int>(
            0, (sum, l) => sum + ((l['activeUsers'] ?? 0) as int)),
        'locations': _locations
            .map((location) => {
                  'name': location['name'],
                  'address': location['address'],
                  'status': location['status'],
                  'capacity': location['settings']?['capacity'] ?? 0,
                  'activeUsers': location['activeUsers'] ?? 0,
                  'currentEmployees': location['currentEmployees'] ?? 0,
                  'geofenceRadius':
                      location['settings']?['geofenceRadius'] ?? 100,
                  'workingHours': location['settings']?['workingHours'],
                  'createdAt': location['createdAt'],
                  'updatedAt': location['updatedAt'],
                })
            .toList(),
      };

      // Convert to JSON string
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

      print('JSON data prepared, length: ${jsonString.length}');
      print('Platform: ${kIsWeb ? 'Web' : 'Mobile'}');

      // Close loading dialog first
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Wait a bit for the dialog to close properly
      await Future.delayed(const Duration(milliseconds: 200));

      // Now show the export dialog for all platforms
      print('Showing export dialog');
      _showExportDialog(context, jsonString);
    } catch (error) {
      // Close loading dialog if open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error exporting data: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showLocationSettings() {
    showDialog(
      context: context,
      builder: (context) => Consumer<FeatureProvider>(
        builder: (context, featureProvider, child) {
          final hasLocationSettings = featureProvider.hasLocationSettings;
          final hasLocationNotifications =
              featureProvider.hasLocationNotifications;
          final hasLocationGeofencing = featureProvider.hasLocationGeofencing;
          final hasLocationCapacity = featureProvider.hasLocationCapacity;

          return AlertDialog(
            title: const Text('Location Management Settings'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Configure location management preferences and default settings.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                if (hasLocationGeofencing) ...[
                  _buildSettingsOption(
                    icon: Icons.location_on,
                    title: 'Default Geofence Radius',
                    subtitle: 'Set default radius for new locations',
                    onTap: () => _showGeofenceSettings(),
                  ),
                  const SizedBox(height: 10),
                ] else ...[
                  _buildFeatureLockOption(
                    icon: Icons.location_on,
                    title: 'Default Geofence Radius',
                    subtitle: 'Available in Professional plan and above',
                    featureName: 'Geofencing',
                  ),
                  const SizedBox(height: 10),
                ],
                if (hasLocationSettings) ...[
                  _buildSettingsOption(
                    icon: Icons.access_time,
                    title: 'Default Working Hours',
                    subtitle: 'Set default working hours for new locations',
                    onTap: () => _showWorkingHoursSettings(),
                  ),
                  const SizedBox(height: 10),
                ] else ...[
                  _buildFeatureLockOption(
                    icon: Icons.access_time,
                    title: 'Default Working Hours',
                    subtitle: 'Available in Professional plan and above',
                    featureName: 'Location Settings',
                  ),
                  const SizedBox(height: 10),
                ],
                if (hasLocationCapacity) ...[
                  _buildSettingsOption(
                    icon: Icons.people,
                    title: 'Default Capacity',
                    subtitle: 'Set default capacity for new locations',
                    onTap: () => _showCapacitySettings(),
                  ),
                  const SizedBox(height: 10),
                ] else ...[
                  _buildFeatureLockOption(
                    icon: Icons.people,
                    title: 'Default Capacity',
                    subtitle: 'Available in Professional plan and above',
                    featureName: 'Location Capacity',
                  ),
                  const SizedBox(height: 10),
                ],
                if (hasLocationNotifications) ...[
                  _buildSettingsOption(
                    icon: Icons.notifications,
                    title: 'Notification Settings',
                    subtitle: 'Configure location-related notifications',
                    onTap: () => _showNotificationSettings(),
                  ),
                ] else ...[
                  _buildFeatureLockOption(
                    icon: Icons.notifications,
                    title: 'Notification Settings',
                    subtitle: 'Available in Professional plan and above',
                    featureName: 'Location Notifications',
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSettingsOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureLockOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required String featureName,
  }) {
    return InkWell(
      onTap: () => _showUpgradeDialog(featureName),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey.shade400, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.lock, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Future<void> _sendLocationAssignmentNotification(
      String employeeId, String locationId) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      final userName = user?['name'] ?? 'Admin';

      // Get employee and location details for the notification
      final apiService = ApiService(baseUrl: ApiConfig.baseUrl);

      // Get employee details
      final employeeResponse = await apiService.get('/employees/$employeeId');
      final employeeName =
          employeeResponse.success ? employeeResponse.data['name'] : 'Employee';

      // Get location details
      final locationResponse = await apiService.get('/locations/$locationId');
      final locationName =
          locationResponse.success ? locationResponse.data['name'] : 'Location';

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}',
        },
        body: jsonEncode({
          'title': 'Employee Location Assignment',
          'message':
              '$employeeName has been assigned to $locationName by $userName',
          'type': 'location_assignment',
          'role': 'admin',
          'link': '/admin/location-management',
        }),
      );

      if (response.statusCode == 201) {
        print('Location assignment notification sent successfully');
      } else {
        print(
            'Failed to send location assignment notification: ${response.statusCode}');
      }
    } catch (error) {
      print('Error sending location assignment notification: $error');
    }
  }

  Future<void> _sendLocationSettingsNotification(
      String settingType, String details) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      final userName = user?['name'] ?? 'Admin';

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}',
        },
        body: jsonEncode({
          'title': 'Location Settings Updated',
          'message':
              '$settingType settings have been updated by $userName. $details',
          'type': 'location_settings',
          'role': 'admin',
          'link': '/admin/location-management',
        }),
      );

      if (response.statusCode == 201) {
        print('Location settings notification sent successfully');
      } else {
        print(
            'Failed to send location settings notification: ${response.statusCode}');
      }
    } catch (error) {
      print('Error sending location settings notification: $error');
    }
  }

  void _showUpgradeDialog(String featureName) {
    showDialog(
      context: context,
      builder: (context) => Consumer<FeatureProvider>(
        builder: (context, featureProvider, child) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.lock, color: Colors.orange),
                const SizedBox(width: 8),
                const Text('Feature Locked'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'The "$featureName" feature is not available in your current plan (${featureProvider.subscriptionPlanName}).',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                const Text(
                  'To access this feature, please contact your administrator to upgrade your subscription plan.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Available Plans:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                          '• Professional: Location management features'),
                      const Text('• Enterprise: All features included'),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showGeofenceSettings() {
    Navigator.pop(context); // Close settings dialog

    showDialog(
      context: context,
      builder: (context) => Consumer<FeatureProvider>(
        builder: (context, featureProvider, child) {
          if (!featureProvider.hasLocationGeofencing) {
            return AlertDialog(
              title: const Text('Feature Not Available'),
              content: const Text(
                'Geofence settings are not available in your current subscription plan. Please upgrade to access this feature.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            );
          }

          final radiusController =
              TextEditingController(text: _defaultGeofenceRadius.toString());

          return AlertDialog(
            title: const Text('Default Geofence Radius'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                    'Set the default geofence radius for new locations:'),
                const SizedBox(height: 20),
                TextFormField(
                  controller: radiusController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Radius (meters)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final radius = int.tryParse(radiusController.text) ?? 100;
                    await _locationSettingsService.updateLocationSettings({
                      'defaultGeofenceRadius': radius,
                    });

                    setState(() {
                      _defaultGeofenceRadius = radius;
                    });

                    // Send notification to company admins
                    await _sendLocationSettingsNotification('Geofence Radius',
                        'Updated default radius to ${radius} meters');

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Default geofence radius updated'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error updating settings: $error'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showWorkingHoursSettings() {
    Navigator.pop(context); // Close settings dialog

    final startController = TextEditingController(text: _defaultStartTime);
    final endController = TextEditingController(text: _defaultEndTime);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Default Working Hours'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Set the default working hours for new locations:'),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: startController,
                    decoration: const InputDecoration(
                      labelText: 'Start Time',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: endController,
                    decoration: const InputDecoration(
                      labelText: 'End Time',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _locationSettingsService.updateLocationSettings({
                  'defaultWorkingHours': {
                    'start': startController.text,
                    'end': endController.text,
                  },
                });

                setState(() {
                  _defaultStartTime = startController.text;
                  _defaultEndTime = endController.text;
                });

                // Send notification to company admins
                await _sendLocationSettingsNotification('Working Hours',
                    'Updated default working hours to ${startController.text} - ${endController.text}');

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Default working hours updated'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error updating settings: $error'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showCapacitySettings() {
    Navigator.pop(context); // Close settings dialog

    final capacityController =
        TextEditingController(text: _defaultCapacity.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Default Capacity'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Set the default capacity for new locations:'),
            const SizedBox(height: 20),
            TextFormField(
              controller: capacityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Capacity (people)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final capacity = int.tryParse(capacityController.text) ?? 50;
                await _locationSettingsService.updateLocationSettings({
                  'defaultCapacity': capacity,
                });

                setState(() {
                  _defaultCapacity = capacity;
                });

                // Send notification to company admins
                await _sendLocationSettingsNotification('Capacity',
                    'Updated default capacity to ${capacity} employees');

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Default capacity updated'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error updating settings: $error'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings() {
    Navigator.pop(context); // Close settings dialog

    bool locationUpdates = _locationUpdatesEnabled;
    bool employeeAssignments = _employeeAssignmentsEnabled;
    bool capacityAlerts = _capacityAlertsEnabled;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Notification Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Configure location-related notifications:'),
              const SizedBox(height: 20),
              SwitchListTile(
                title: const Text('Location Updates'),
                subtitle: const Text('Notify when location details change'),
                value: locationUpdates,
                onChanged: (value) {
                  setDialogState(() {
                    locationUpdates = value;
                  });
                },
              ),
              SwitchListTile(
                title: const Text('Employee Assignments'),
                subtitle:
                    const Text('Notify when employees are assigned/removed'),
                value: employeeAssignments,
                onChanged: (value) {
                  setDialogState(() {
                    employeeAssignments = value;
                  });
                },
              ),
              SwitchListTile(
                title: const Text('Capacity Alerts'),
                subtitle: const Text('Notify when location reaches capacity'),
                value: capacityAlerts,
                onChanged: (value) {
                  setDialogState(() {
                    capacityAlerts = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _locationSettingsService.updateLocationSettings({
                    'notifications': {
                      'locationUpdates': locationUpdates,
                      'employeeAssignments': employeeAssignments,
                      'capacityAlerts': capacityAlerts,
                    },
                  });

                  setState(() {
                    _locationUpdatesEnabled = locationUpdates;
                    _employeeAssignmentsEnabled = employeeAssignments;
                    _capacityAlertsEnabled = capacityAlerts;
                  });

                  // Send notification to company admins
                  final enabledFeatures = <String>[];
                  if (locationUpdates) enabledFeatures.add('Location Updates');
                  if (employeeAssignments)
                    enabledFeatures.add('Employee Assignments');
                  if (capacityAlerts) enabledFeatures.add('Capacity Alerts');

                  await _sendLocationSettingsNotification(
                      'Notification Settings',
                      'Updated notification preferences: ${enabledFeatures.join(', ')}');

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notification settings updated'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating settings: $error'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // Show export dialog for mobile or fallback
  void _showExportDialog(BuildContext context, String jsonString) {
    print('Showing export dialog with data length: ${jsonString.length}');

    // Use a post-frame callback to ensure the context is valid
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Location Data Export'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Location data has been prepared for export. You can copy the data below:',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: SizedBox(
                    height: 300,
                    child: SingleChildScrollView(
                      child: SelectableText(
                        jsonString,
                        style: const TextStyle(
                            fontSize: 12, fontFamily: 'monospace'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Close'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  // Copy to clipboard
                  Clipboard.setData(ClipboardData(text: jsonString));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Data copied to clipboard'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copy'),
              ),
            ],
          ),
        );
      }
    });
  }
}
