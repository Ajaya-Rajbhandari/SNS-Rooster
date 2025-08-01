import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sns_rooster/providers/auth_provider.dart';
import 'package:sns_rooster/services/company_settings_service.dart';
import 'package:sns_rooster/services/firebase_storage_service.dart';
import 'package:sns_rooster/config/api_config.dart';
import 'package:sns_rooster/widgets/admin_side_navigation.dart';
import 'package:sns_rooster/providers/feature_provider.dart';

class EditCompanyFormScreen extends StatefulWidget {
  const EditCompanyFormScreen({Key? key}) : super(key: key);

  @override
  State<EditCompanyFormScreen> createState() => _EditCompanyFormScreenState();
}

class _EditCompanyFormScreenState extends State<EditCompanyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();

  // Form controllers
  final _nameController = TextEditingController();
  final _legalNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _countryController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _registrationNumberController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _industryController = TextEditingController();
  final _establishedYearController = TextEditingController();

  // State variables
  String _logoUrl = '';
  File? _selectedLogoFile;
  Uint8List? _selectedLogoBytes;
  String? _selectedLogoFileName;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Load company settings directly from the service
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final companySettingsService = CompanySettingsService(authProvider);
      final settings = await companySettingsService.fetchSettings();

      if (settings != null) {
        _nameController.text = settings['name'] ?? '';
        _legalNameController.text = settings['legalName'] ?? '';
        _addressController.text = settings['address'] ?? '';
        _cityController.text = settings['city'] ?? '';
        _stateController.text = settings['state'] ?? '';
        _postalCodeController.text = settings['postalCode'] ?? '';
        _countryController.text = settings['country'] ?? 'Australia';
        _phoneController.text = settings['phone'] ?? '';
        _emailController.text = settings['email'] ?? '';
        _websiteController.text = settings['website'] ?? '';
        _taxIdController.text = settings['taxId'] ?? '';
        _registrationNumberController.text =
            settings['registrationNumber'] ?? '';
        _descriptionController.text = settings['description'] ?? '';
        _industryController.text = settings['industry'] ?? '';
        _establishedYearController.text =
            settings['establishedYear']?.toString() ?? '';
        _logoUrl = settings['logoUrl'] ?? '';

        // Debug log for logo URL
        print('DEBUG: Logo URL from settings: $_logoUrl');
        if (_logoUrl.isNotEmpty) {
          final fullLogoUrl = CompanySettingsService.getLogoUrl(_logoUrl);
          print('DEBUG: Full logo URL: $fullLogoUrl');
        }

        setState(() {
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load company settings';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _legalNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _taxIdController.dispose();
    _registrationNumberController.dispose();
    _descriptionController.dispose();
    _industryController.dispose();
    _establishedYearController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          if (kIsWeb) {
            // For web, we need to read the bytes
            pickedFile.readAsBytes().then((bytes) {
              setState(() {
                _selectedLogoBytes = bytes;
                _selectedLogoFileName = pickedFile.name;
                _selectedLogoFile = null;
              });
            });
          } else {
            // For mobile, we can use the file directly
            _selectedLogoFile = File(pickedFile.path);
            _selectedLogoBytes = null;
            _selectedLogoFileName = null;
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveCompanyData() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      if (token == null) {
        throw Exception('No authentication token available');
      }

      // Prepare company data
      final companyData = {
        'name': _nameController.text.trim(),
        'legalName': _legalNameController.text.trim(),
        'industry': _industryController.text.trim(),
        'establishedYear': _establishedYearController.text.trim(),
        'description': _descriptionController.text.trim(),
      };

      // Remove empty fields
      companyData.removeWhere((key, value) => value.isEmpty);

      print('DEBUG: Saving company data: $companyData');

      // Save company information
      await CompanySettingsService(authProvider).saveSettings(companyData);

      // Upload logo if selected
      if (_selectedLogoBytes != null || _selectedLogoFile != null) {
        print('DEBUG: Starting logo upload to local backend');
        print('DEBUG: kIsWeb: $kIsWeb');
        print('DEBUG: _selectedLogoBytes: ${_selectedLogoBytes != null}');
        print('DEBUG: _selectedLogoFile: ${_selectedLogoFile != null}');
        print('DEBUG: _selectedLogoFileName: $_selectedLogoFileName');

        try {
          String? uploadedLogoUrl;

          // Use local backend API instead of Firebase Storage
          final request = http.MultipartRequest(
            'POST',
            Uri.parse('${ApiConfig.baseUrl}/admin/settings/company/logo'),
          );

          request.headers['Authorization'] = 'Bearer $token';

          if (kIsWeb && _selectedLogoBytes != null) {
            print('DEBUG: Uploading web bytes to local backend');
            print('DEBUG: File name: $_selectedLogoFileName');
            print('DEBUG: Bytes length: ${_selectedLogoBytes!.length}');

            // Determine content type from file extension
            String contentType = 'image/jpeg'; // default
            if (_selectedLogoFileName != null) {
              final ext = _selectedLogoFileName!.split('.').last.toLowerCase();
              switch (ext) {
                case 'png':
                  contentType = 'image/png';
                  break;
                case 'gif':
                  contentType = 'image/gif';
                  break;
                case 'jpg':
                case 'jpeg':
                default:
                  contentType = 'image/jpeg';
                  break;
              }
            }

            request.files.add(
              http.MultipartFile.fromBytes(
                'logo',
                _selectedLogoBytes!,
                filename: _selectedLogoFileName ?? 'logo.png',
                contentType: MediaType.parse(contentType),
              ),
            );
          } else if (_selectedLogoFile != null) {
            print('DEBUG: Uploading mobile file to local backend');
            print('DEBUG: File path: ${_selectedLogoFile!.path}');

            request.files.add(
              await http.MultipartFile.fromPath(
                'logo',
                _selectedLogoFile!.path,
              ),
            );
          }

          print('DEBUG: Sending multipart request to local backend');
          final streamedResponse = await request.send();
          final response = await http.Response.fromStream(streamedResponse);

          print('DEBUG: Local backend response status: ${response.statusCode}');
          print('DEBUG: Local backend response body: ${response.body}');

          if (response.statusCode == 200) {
            final responseData = json.decode(response.body);
            uploadedLogoUrl = responseData['logoUrl'];
            print(
                'DEBUG: Logo uploaded successfully to local backend: $uploadedLogoUrl');
          } else {
            throw Exception(
                'Local backend upload failed: ${response.statusCode} - ${response.body}');
          }

          if (uploadedLogoUrl != null) {
            _logoUrl = uploadedLogoUrl;

            // Show success message
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Logo uploaded successfully!'),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 3),
                ),
              );
            }
          }
        } catch (uploadError) {
          print('DEBUG: Local backend upload failed: $uploadError');

          // Show detailed error message
          String errorMessage = 'Failed to upload logo';
          if (uploadError.toString().contains('permission')) {
            errorMessage =
                'Permission denied. Please check your access rights.';
          } else if (uploadError.toString().contains('network')) {
            errorMessage =
                'Network error. Please check your internet connection.';
          } else if (uploadError.toString().contains('413')) {
            errorMessage = 'File too large. Please select a smaller image.';
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(child: Text(errorMessage)),
                  ],
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Dismiss',
                  textColor: Colors.white,
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                ),
              ),
            );
          }
        }
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Company information updated successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Navigate back
        Navigator.of(context).pop();
      }
    } catch (error) {
      print('DEBUG: Error saving company data: $error');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                    'Failed to update company information: ${error.toString()}'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<String?> _uploadLogo(String? token) async {
    try {
      print('DEBUG: Starting logo upload');
      print('DEBUG: kIsWeb: $kIsWeb');
      print('DEBUG: _selectedLogoBytes: ${_selectedLogoBytes != null}');
      print('DEBUG: _selectedLogoFile: ${_selectedLogoFile != null}');
      print('DEBUG: _selectedLogoFileName: $_selectedLogoFileName');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/admin/settings/company/logo'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      if (kIsWeb && _selectedLogoBytes != null) {
        // For web, use bytes
        print('DEBUG: Uploading web bytes');
        print('DEBUG: File name: $_selectedLogoFileName');
        print('DEBUG: Bytes length: ${_selectedLogoBytes!.length}');

        // Determine content type from file extension
        String contentType = 'image/jpeg'; // default
        if (_selectedLogoFileName != null) {
          final ext = _selectedLogoFileName!.split('.').last.toLowerCase();
          switch (ext) {
            case 'png':
              contentType = 'image/png';
              break;
            case 'gif':
              contentType = 'image/gif';
              break;
            case 'jpg':
            case 'jpeg':
            default:
              contentType = 'image/jpeg';
              break;
          }
        }
        print('DEBUG: Content type: $contentType');

        request.files.add(
          http.MultipartFile.fromBytes(
            'logo',
            _selectedLogoBytes!,
            filename: _selectedLogoFileName ?? 'logo.jpg',
            contentType: MediaType.parse(contentType),
          ),
        );
      } else if (_selectedLogoFile != null) {
        // For mobile, use file path
        print('DEBUG: Uploading mobile file');
        print('DEBUG: File path: ${_selectedLogoFile!.path}');

        request.files.add(
          await http.MultipartFile.fromPath('logo', _selectedLogoFile!.path),
        );
      } else {
        throw Exception('No logo file selected');
      }

      print(
          'DEBUG: Sending request to: ${ApiConfig.baseUrl}/admin/settings/company/logo');
      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      print('DEBUG: Response status: ${response.statusCode}');
      print('DEBUG: Response data: $responseData');

      if (response.statusCode == 200) {
        final data = jsonDecode(responseData);
        print('DEBUG: Upload successful, logoUrl: ${data['logoUrl']}');
        return data['logoUrl'];
      } else {
        print('DEBUG: Upload failed with status: ${response.statusCode}');
        print('DEBUG: Error response: $responseData');
        throw Exception(
            'Failed to upload logo: ${response.statusCode} - $responseData');
      }
    } catch (e) {
      print('DEBUG: Upload exception: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload logo: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Edit Company Information'),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Company Information'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      drawer:
          const AdminSideNavigation(currentRoute: '/admin/company_settings'),
      body: Row(
        children: [
          // Side Navigation (Desktop)
          if (MediaQuery.of(context).size.width > 768)
            const SizedBox(
              width: 250,
              child:
                  AdminSideNavigation(currentRoute: '/admin/company_settings'),
            ),

          // Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_errorMessage != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          border: Border.all(color: Colors.red.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),

                    // Company Logo Section
                    _buildLogoSection(theme, colorScheme),
                    const Divider(height: 32),

                    // Basic Information
                    _buildBasicInformation(theme, colorScheme),
                    const Divider(height: 32),

                    // Contact Information
                    _buildContactInformation(theme, colorScheme),
                    const Divider(height: 32),

                    // Legal & Business Information
                    _buildLegalInformation(theme, colorScheme),
                    const Divider(height: 32),

                    // Additional Information
                    _buildAdditionalInformation(theme, colorScheme),
                    const SizedBox(height: 32),

                    // Save Button
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isSaving ? null : _saveCompanyData,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.save),
                            label: Text(_isSaving
                                ? 'Saving...'
                                : 'Save Company Information'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        OutlinedButton(
                          onPressed:
                              _isSaving ? null : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoSection(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Company Logo', style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        Row(
          children: [
            // Logo preview
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.outline),
                borderRadius: BorderRadius.circular(8),
                color: colorScheme.surfaceContainerHighest,
              ),
              child: _buildLogoPreview(colorScheme),
            ),
            const SizedBox(width: 16),
            // Upload buttons
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _pickLogo(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Choose from Gallery'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _pickLogo(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Take Photo'),
                  ),
                  const SizedBox(height: 8),
                  if (_logoUrl.isNotEmpty ||
                      _selectedLogoFile != null ||
                      _selectedLogoBytes != null)
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedLogoFile = null;
                          _selectedLogoBytes = null;
                          _selectedLogoFileName = null;
                          _logoUrl = '';
                        });
                      },
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text('Remove Logo',
                          style: TextStyle(color: Colors.red)),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Recommended: Square image, at least 200x200px, max 5MB',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildLogoPreview(ColorScheme colorScheme) {
    // Show selected logo (web bytes or mobile file)
    if (_selectedLogoBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          _selectedLogoBytes!,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.business,
            size: 48,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    } else if (_selectedLogoFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          _selectedLogoFile!,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.business,
            size: 48,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    } else if (_logoUrl.isNotEmpty) {
      // Show existing logo from URL
      final fullLogoUrl = CompanySettingsService.getLogoUrl(_logoUrl);
      print('DEBUG: Attempting to load logo from: $fullLogoUrl');
      print(
          'DEBUG: URL contains firebasestorage.googleapis.com: ${fullLogoUrl.contains('firebasestorage.googleapis.com')}');
      print(
          'DEBUG: URL contains firebasestorage: ${fullLogoUrl.contains('firebasestorage')}');
      print(
          'DEBUG: URL contains storage.googleapis.com: ${fullLogoUrl.contains('storage.googleapis.com')}');

      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Builder(
          builder: (context) {
            final theme = Theme.of(context);

            // If it's a Firebase Storage URL, use the Firebase Storage service
            if (fullLogoUrl.contains('firebasestorage.googleapis.com') ||
                fullLogoUrl.contains('firebasestorage') ||
                fullLogoUrl.contains('storage.googleapis.com')) {
              print(
                  'DEBUG: Firebase Storage URL detected, using platform-specific loading');

              if (kIsWeb) {
                // For web, try multiple approaches to handle certificate issues
                print(
                    'DEBUG: Web platform - trying multiple approaches for Firebase Storage');

                // Approach 1: Try the original URL
                return Image.network(
                  fullLogoUrl,
                  fit: BoxFit.contain,
                  headers: const {
                    'User-Agent': 'SNS-Rooster-Web-App',
                    'Accept': 'image/*',
                  },
                  errorBuilder: (context, error, stackTrace) {
                    print('DEBUG: Web approach 1 failed: $error');

                    // Approach 2: Try alternative Firebase Storage URL format
                    final alternativeUrl = fullLogoUrl.replaceFirst(
                        'https://sns-rooster-8cca5.firebasestorage.app.storage.googleapis.com',
                        'https://firebasestorage.googleapis.com');
                    print('DEBUG: Trying alternative URL: $alternativeUrl');

                    return Image.network(
                      alternativeUrl,
                      fit: BoxFit.contain,
                      headers: const {
                        'User-Agent': 'SNS-Rooster-Web-App',
                        'Accept': 'image/*',
                      },
                      errorBuilder: (context, error2, stackTrace2) {
                        print('DEBUG: Web approach 2 also failed: $error2');

                        // Approach 3: Try without the problematic domain
                        final simplifiedUrl = fullLogoUrl.replaceFirst(
                            'https://sns-rooster-8cca5.firebasestorage.app.storage.googleapis.com',
                            'https://storage.googleapis.com/sns-rooster-8cca5.appspot.com');
                        print('DEBUG: Trying simplified URL: $simplifiedUrl');

                        return Image.network(
                          simplifiedUrl,
                          fit: BoxFit.contain,
                          headers: const {
                            'User-Agent': 'SNS-Rooster-Web-App',
                            'Accept': 'image/*',
                          },
                          errorBuilder: (context, error3, stackTrace3) {
                            print('DEBUG: All web approaches failed');
                            return _buildLogoErrorState(
                                context,
                                theme,
                                colorScheme,
                                'Web: Certificate issue with Firebase Storage. Please upload a new logo.');
                          },
                        );
                      },
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(strokeWidth: 2),
                            const SizedBox(height: 8),
                            Text(
                              'Loading (Web)',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              } else {
                // For mobile, use Firebase Storage SDK
                return FutureBuilder<Uint8List?>(
                  future:
                      FirebaseStorageService.loadLogoForPlatform(fullLogoUrl),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(strokeWidth: 2),
                              const SizedBox(height: 8),
                              Text(
                                'Loading (Mobile)',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      print(
                          'DEBUG: Firebase Storage download failed: ${snapshot.error}');
                      return _buildLogoErrorState(context, theme, colorScheme,
                          'Firebase Storage download failed. Please upload a new logo.');
                    }

                    if (snapshot.hasData && snapshot.data != null) {
                      print(
                          'DEBUG: Logo loaded successfully, displaying from memory');
                      return Image.memory(
                        snapshot.data!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          print(
                              'DEBUG: Error displaying logo from memory: $error');
                          return _buildLogoErrorState(
                              context, theme, colorScheme);
                        },
                      );
                    }

                    return _buildLogoErrorState(context, theme, colorScheme,
                        'Logo not found. Please upload a new logo.');
                  },
                );
              }
            }

            // For non-Firebase URLs, use regular network loading
            return Image.network(
              fullLogoUrl,
              fit: BoxFit.contain,
              headers: const {
                'User-Agent': 'SNS-Rooster-App',
                'Accept': 'image/*',
              },
              errorBuilder: (context, error, stackTrace) {
                print('DEBUG: Error loading logo from $fullLogoUrl: $error');
                print('DEBUG: Stack trace: $stackTrace');

                // For web, try a different approach if it's a Firebase Storage URL
                if (kIsWeb &&
                    fullLogoUrl.contains('firebasestorage.googleapis.com')) {
                  print(
                      'DEBUG: Web fallback - trying direct network loading for Firebase Storage');
                  return Image.network(
                    fullLogoUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error2, stackTrace2) {
                      print('DEBUG: Web fallback also failed: $error2');
                      return _buildLogoErrorState(context, theme, colorScheme,
                          'Web: Firebase Storage access issue. Please upload a new logo.');
                    },
                  );
                }

                return _buildLogoErrorState(context, theme, colorScheme);
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          strokeWidth: 2,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Loading...',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      );
    } else {
      // Show placeholder
      return Icon(
        Icons.business,
        size: 48,
        color: colorScheme.onSurfaceVariant,
      );
    }
  }

  Widget _buildBasicInformation(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Basic Information', style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),

        // Company Name
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Company Name *',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Company name is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Legal Name
        TextFormField(
          controller: _legalNameController,
          decoration: const InputDecoration(
            labelText: 'Legal Name',
            border: OutlineInputBorder(),
            hintText: 'Legal business name (if different)',
          ),
        ),
        const SizedBox(height: 16),

        // Industry
        TextFormField(
          controller: _industryController,
          decoration: const InputDecoration(
            labelText: 'Industry',
            border: OutlineInputBorder(),
            hintText: 'e.g., Technology, Healthcare, Finance',
          ),
        ),
        const SizedBox(height: 16),

        // Established Year
        TextFormField(
          controller: _establishedYearController,
          decoration: const InputDecoration(
            labelText: 'Established Year',
            border: OutlineInputBorder(),
            hintText: 'e.g., 2020',
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              final year = int.tryParse(value);
              if (year == null || year < 1800 || year > DateTime.now().year) {
                return 'Please enter a valid year';
              }
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Subscription Plan Info
        Consumer<FeatureProvider>(
          builder: (context, featureProvider, _) {
            if (featureProvider.isLoading) {
              return Card(
                color: colorScheme.surfaceContainerHighest,
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Loading subscription plan...'),
                    ],
                  ),
                ),
              );
            }

            return Card(
              color: colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.card_membership,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Subscription Plan',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Current Plan: ${featureProvider.subscriptionPlanName}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Employee Limit: ${featureProvider.maxEmployees} employees',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Current Usage: ${featureProvider.employeeCount} / ${featureProvider.maxEmployees}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        // Company Description
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Company Description',
            border: OutlineInputBorder(),
            hintText: 'Brief description of your company',
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildContactInformation(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Contact Information', style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        TextFormField(
          controller: _addressController,
          decoration: const InputDecoration(
            labelText: 'Street Address',
            hintText: 'Building name, street, area',
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'City'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _stateController,
                decoration: const InputDecoration(labelText: 'State/Province'),
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
                decoration: const InputDecoration(labelText: 'Postal Code'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _countryController,
                decoration: const InputDecoration(labelText: 'Country'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '+61-XXX-XXXXXXX',
                ),
                keyboardType: TextInputType.phone,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'contact@company.com',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v?.trim().isNotEmpty == true) {
                    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                    if (!emailRegex.hasMatch(v!)) {
                      return 'Invalid email format';
                    }
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _websiteController,
          decoration: const InputDecoration(
            labelText: 'Website',
            hintText: 'https://www.company.com',
          ),
          keyboardType: TextInputType.url,
          validator: (v) {
            if (v?.trim().isNotEmpty == true) {
              final websiteRegex = RegExp(r'^https?://[^\s]+$');
              if (!websiteRegex.hasMatch(v!)) {
                return 'Invalid website format (must start with http:// or https://)';
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildLegalInformation(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Legal & Business Information', style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _taxIdController,
                decoration: const InputDecoration(
                  labelText: 'Tax ID / ABN',
                  hintText: 'Business tax identification',
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _registrationNumberController,
                decoration: const InputDecoration(
                  labelText: 'Registration Number',
                  hintText: 'Business registration number',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdditionalInformation(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Additional Information', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        Card(
          color: colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 20, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'How this information is used:',
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• Company logo and name appear on payslips and reports\n'
                  '• Contact information is included in official documents\n'
                  '• Legal information is used for compliance and tax purposes\n'
                  '• All information remains private and secure',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoErrorState(
      BuildContext context, ThemeData theme, ColorScheme colorScheme,
      [String? message]) {
    return GestureDetector(
      onTap: () {
        // Force rebuild to retry loading
        setState(() {});
      },
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image,
              size: 32,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 4),
            Text(
              message ?? 'Logo Error',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              'Tap to retry',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.primary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
