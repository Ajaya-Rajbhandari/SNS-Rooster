import 'package:flutter/material.dart';
import 'package:sns_rooster/utils/logger.dart';
import 'package:provider/provider.dart';
import '../../providers/profile_provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/api_config.dart'; // Import ApiConfig
import 'package:sns_rooster/widgets/app_drawer.dart'; // Add this import
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_settings_provider.dart';
import '../../widgets/admin_side_navigation.dart';
import 'package:flutter/services.dart';
import 'package:sns_rooster/services/global_notification_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

void showDocumentDialog(BuildContext context, String? url) {
  if (url == null || url.isEmpty) return;
  final isPdf = url.toLowerCase().endsWith('.pdf');
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: SizedBox(
          width: 350,
          height: 500,
          child: isPdf
              ? SfPdfViewer.network(url)
              : InteractiveViewer(
                  child: Image.network(url,
                      fit: BoxFit.contain,
                      errorBuilder: (ctx, error, stack) =>
                          const Center(child: Text('Failed to load image'))),
                ),
        ),
      );
    },
  );
}

String formatDate(String? isoString) {
  if (isoString == null || isoString.isEmpty) return '';
  try {
    final date = DateTime.parse(isoString);
    return DateFormat('yyyy-MM-dd').format(date);
  } catch (_) {
    return isoString;
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _emergencyContactController =
      TextEditingController();
  final TextEditingController _emergencyPhoneController =
      TextEditingController();
  final TextEditingController _emergencyContactRelationshipController =
      TextEditingController();

  bool _isLoading = false; // For local operations like save, image pick
  bool _isEditingPersonal = false;
  bool _isEditingEmergency = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileProvider =
          Provider.of<ProfileProvider>(context, listen: false);
      if (!profileProvider.isInitialized) {
        profileProvider.refreshProfile().then((_) {
          if (mounted) {
            _loadUserDataInternal(profileProvider);
          }
        });
      } else {
        _loadUserDataInternal(profileProvider);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Always reload user data from provider when dependencies change
    final profileProvider = Provider.of<ProfileProvider>(context);
    _loadUserDataInternal(profileProvider);
  }

  void _loadUserDataInternal(ProfileProvider profileProvider) {
    final userProfile = profileProvider.profile;
    if (userProfile != null) {
      _firstNameController.text = userProfile['firstName'] ?? '';
      _lastNameController.text = userProfile['lastName'] ?? '';
      _emailController.text = userProfile['email'] ?? '';
      _phoneController.text = userProfile['phone'] ?? '';
      _addressController.text = userProfile['address'] ?? '';

      var emergencyContactData = userProfile['emergencyContact'];
      if (emergencyContactData is Map) {
        _emergencyContactController.text = emergencyContactData['name'] ?? '';
        _emergencyPhoneController.text = emergencyContactData['phone'] ?? '';
        _emergencyContactRelationshipController.text =
            emergencyContactData['relationship'] ?? '';
      } else if (emergencyContactData is String) {
        _emergencyContactController.text = emergencyContactData;
        _emergencyPhoneController.text = userProfile['emergencyPhone'] ?? '';
        _emergencyContactRelationshipController.text =
            userProfile['emergencyRelationship'] ?? '';
      } else {
        _emergencyContactController.text =
            userProfile['emergencyContactName'] ?? '';
        _emergencyPhoneController.text =
            userProfile['emergencyContactPhone'] ?? '';
        _emergencyContactRelationshipController.text =
            userProfile['emergencyContactRelationship'] ?? '';
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _isLoading = true;
      });
      final profileProvider =
          Provider.of<ProfileProvider>(context, listen: false);
      bool success;
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        success = await profileProvider.updateProfilePicture(
            imageBytes: bytes, fileName: image.name);
      } else {
        success =
            await profileProvider.updateProfilePicture(imagePath: image.path);
      }
      setState(() {
        _isLoading = false;
      });
      if (success) {
        // Optionally, show a success message
        GlobalNotificationService()
            .showSuccess('Profile picture updated successfully!');
      } else {
        // Optionally, show an error message
        GlobalNotificationService().showError(
            profileProvider.error ?? 'Failed to update profile picture.');
      }
    } else {
      // User canceled the picker
      log('No image selected.');
    }
  }

  Future<void> _pickAndUploadDocument(String documentType) async {
    try {
      log('Attempting to upload $documentType');

      // File picking logic (cross-platform)
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'png', 'doc', 'docx'],
      );

      if (result == null) {
        log('No file selected.');
        GlobalNotificationService().showError('No file selected.');
        return;
      }

      final file = result.files.first;
      log('File selected: ${file.name}');

      // File size validation
      final fileSize = file.size;
      if (fileSize > 5 * 1024 * 1024) {
        log('File size exceeds limit.');
        GlobalNotificationService()
            .showError('File size must be less than 5MB.');
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final profileProvider =
          Provider.of<ProfileProvider>(context, listen: false);
      bool success = false;
      if (kIsWeb) {
        // On web, upload using bytes
        success = await profileProvider.uploadDocument(
            fileBytes: file.bytes!,
            fileName: file.name,
            documentType: documentType);
      } else {
        // On mobile/desktop, upload using file path
        success = await profileProvider.uploadDocument(
            filePath: file.path!, documentType: documentType);
      }

      setState(() {
        _isLoading = false;
      });

      if (success) {
        log('Document uploaded successfully.');
        await profileProvider.refreshProfile();
        GlobalNotificationService()
            .showSuccess('Document uploaded successfully!');
      } else {
        log('Failed to upload document.');
        GlobalNotificationService()
            .showError(profileProvider.error ?? 'Failed to upload document.');
      }
    } catch (e) {
      log('Error during document upload: $e');
      GlobalNotificationService()
          .showError('An error occurred during upload. Please try again.');
    }
  }

  Future<void> _savePersonalInfo() async {
    // Validation for personal information only
    String firstName = _firstNameController.text.trim();
    String lastName = _lastNameController.text.trim();
    String phone = _phoneController.text.trim();
    String email = _emailController.text.trim();
    String address = _addressController.text.trim();
    final emailRegex = RegExp(
        r"^[a-zA-Z0-9.!#\$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*");

    if (firstName.isEmpty) {
      GlobalNotificationService().showError('First name is required.');
      return;
    }
    if (lastName.isEmpty) {
      GlobalNotificationService().showError('Last name is required.');
      return;
    }
    if (email.isEmpty || !emailRegex.hasMatch(email)) {
      GlobalNotificationService()
          .showError('Please enter a valid email address.');
      return;
    }
    if (phone.isEmpty || phone.length < 8) {
      GlobalNotificationService()
          .showError('Please enter a valid phone number (at least 8 digits).');
      return;
    }
    if (address.isEmpty) {
      GlobalNotificationService().showError('Address is required.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);
    Map<String, dynamic> updates = {
      'firstName': _firstNameController.text,
      'lastName': _lastNameController.text,
      'phone': _phoneController.text,
      'address': _addressController.text,
    };

    try {
      await profileProvider.updateProfile(updates);
      GlobalNotificationService()
          .showSuccess('Personal information updated successfully!');
    } catch (e) {
      GlobalNotificationService()
          .showError('Failed to update personal information: $e');
    } finally {
      setState(() {
        _isLoading = false;
        _isEditingPersonal = false;
      });
    }
  }

  Future<void> _saveEmergencyContact() async {
    // Validation for emergency contact only
    String emergencyContact = _emergencyContactController.text.trim();
    String emergencyPhone = _emergencyPhoneController.text.trim();
    String emergencyRelationship =
        _emergencyContactRelationshipController.text.trim();

    if (emergencyContact.isEmpty) {
      GlobalNotificationService()
          .showError('Emergency contact name is required.');
      return;
    }
    if (emergencyPhone.isEmpty || emergencyPhone.length < 8) {
      GlobalNotificationService().showError(
          'Please enter a valid emergency contact phone (at least 8 digits).');
      return;
    }
    if (emergencyRelationship.isEmpty) {
      GlobalNotificationService().showError('Relationship is required.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);
    Map<String, dynamic> updates = {
      'emergencyContact': _emergencyContactController.text,
      'emergencyPhone': _emergencyPhoneController.text,
      'emergencyRelationship': _emergencyContactRelationshipController.text,
    };

    try {
      await profileProvider.updateProfile(updates);
      GlobalNotificationService()
          .showSuccess('Emergency contact updated successfully!');
    } catch (e) {
      GlobalNotificationService()
          .showError('Failed to update emergency contact: $e');
    } finally {
      setState(() {
        _isLoading = false;
        _isEditingEmergency = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null) {
      // Not logged in, show fallback or redirect
      return Scaffold(
        body: Center(child: Text('Not logged in. Please log in.')),
      );
    }
    final isAdmin = user['role'] == 'admin';
    if (isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('Access denied')), // Or redirect
        drawer: const AdminSideNavigation(currentRoute: '/profile'),
      );
    }
    final theme = Theme.of(context);
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, _) {
        if (profileProvider.isLoading || profileProvider.profile == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Profile')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        // Always update text fields with latest profile data
        _loadUserDataInternal(profileProvider);
        String? avatarUrl = profileProvider.profile?['avatar'];
        ImageProvider? backgroundImage;
        if (avatarUrl != null && avatarUrl.isNotEmpty) {
          if (avatarUrl.startsWith('http')) {
            backgroundImage = NetworkImage(avatarUrl);
          } else {
            String imageBaseUrl = ApiConfig.baseUrl;
            if (imageBaseUrl.endsWith('/api')) {
              imageBaseUrl = imageBaseUrl.substring(
                  0, imageBaseUrl.length - '/api'.length);
            }
            String fullUrl = (imageBaseUrl.endsWith('/') ||
                    avatarUrl.startsWith('/'))
                ? "$imageBaseUrl${avatarUrl.startsWith('/') ? avatarUrl.substring(1) : avatarUrl}"
                : "$imageBaseUrl/$avatarUrl";
            fullUrl = fullUrl.replaceFirst('//', '/').replaceFirst(':/', '://');
            if (avatarUrl.startsWith('/uploads') &&
                imageBaseUrl.endsWith('/')) {
              fullUrl =
                  "${imageBaseUrl.substring(0, imageBaseUrl.length - 1)}$avatarUrl";
            } else if (!avatarUrl.startsWith('/') &&
                !imageBaseUrl.endsWith('/')) {
              fullUrl = "$imageBaseUrl/$avatarUrl";
            } else {
              fullUrl = "$imageBaseUrl$avatarUrl"
                  .replaceAll(RegExp(r'(?<!:)/{2,}'), '/');
            }
            backgroundImage = NetworkImage(fullUrl);
            log('Constructed Avatar URL for Profile: $fullUrl');
          }
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
          ),
          drawer: const AppDrawer(),
          body: profileProvider.isLoading && !_isLoading
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Profile Header
                          Center(
                            child: Consumer<ProfileProvider>(
                              builder: (context, profileProvider, _) {
                                final profile = profileProvider.profile;
                                return Column(
                                  children: [
                                    CircleAvatar(
                                      radius: 48,
                                      backgroundImage: backgroundImage,
                                      child: backgroundImage == null
                                          ? const Icon(Icons.person, size: 48)
                                          : null,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      profile?['fullName'] ??
                                          profile?['firstName'] ??
                                          '',
                                      style: theme.textTheme.titleLarge,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      profile?['email'] ?? '',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    ElevatedButton.icon(
                                      onPressed: _pickAndUploadImage,
                                      icon: const Icon(Icons.camera_alt),
                                      label: const Text('Change Photo'),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Personal Information Section
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Personal Information',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        _isEditingPersonal
                                            ? Icons.check
                                            : Icons.edit,
                                        color: Colors.blueAccent,
                                      ),
                                      onPressed: () async {
                                        if (_isEditingPersonal) {
                                          await _savePersonalInfo();
                                        } else {
                                          setState(() {
                                            _isEditingPersonal = true;
                                          });
                                        }
                                      },
                                      tooltip: _isEditingPersonal
                                          ? 'Save'
                                          : 'Edit section',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: _firstNameController,
                                  label: 'First Name',
                                  icon: Icons.person,
                                  enabled: _isEditingPersonal,
                                ),
                                _buildTextField(
                                  controller: _lastNameController,
                                  label: 'Last Name',
                                  icon: Icons.person,
                                  enabled: _isEditingPersonal,
                                ),
                                _buildTextField(
                                  controller: _emailController,
                                  label: 'Email',
                                  icon: Icons.email,
                                  enabled: false,
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                _buildTextField(
                                  controller: _phoneController,
                                  label: 'Phone',
                                  icon: Icons.phone,
                                  enabled: _isEditingPersonal,
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                ),
                                _buildTextField(
                                  controller: _addressController,
                                  label: 'Address',
                                  icon: Icons.home,
                                  enabled: _isEditingPersonal,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Emergency Contact',
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          _isEditingEmergency
                                              ? Icons.check
                                              : Icons.edit,
                                          color: Colors.blueAccent,
                                        ),
                                        onPressed: () async {
                                          if (_isEditingEmergency) {
                                            await _saveEmergencyContact();
                                          } else {
                                            setState(() {
                                              _isEditingEmergency = true;
                                            });
                                          }
                                        },
                                        tooltip: _isEditingEmergency
                                            ? 'Save'
                                            : 'Edit section',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    controller: _emergencyContactController,
                                    label: 'Contact Name',
                                    icon: Icons.person_pin_rounded,
                                    enabled: _isEditingEmergency,
                                  ),
                                  _buildTextField(
                                    controller: _emergencyPhoneController,
                                    label: 'Contact Phone',
                                    icon: Icons.phone_iphone,
                                    enabled: _isEditingEmergency,
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly
                                    ],
                                  ),
                                  _buildTextField(
                                    controller:
                                        _emergencyContactRelationshipController,
                                    label: 'Relationship',
                                    icon: Icons.people,
                                    enabled: _isEditingEmergency,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Document Upload Section
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.file_present,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Document Upload',
                                      style:
                                          theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        icon: const Icon(Icons.file_present),
                                        label: const Text('Upload ID Card'),
                                        onPressed: () async {
                                          await _pickAndUploadDocument(
                                              'idCard');
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        icon: const Icon(Icons.file_present),
                                        label: const Text('Upload Passport'),
                                        onPressed: () async {
                                          await _pickAndUploadDocument(
                                              'passport');
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                const Text('Accepted formats: PDF, JPG, PNG',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey)),
                                const SizedBox(height: 16),
                                // Document status display
                                Consumer<ProfileProvider>(
                                  builder: (context, profileProvider, _) {
                                    final profile = profileProvider.profile;
                                    final documents =
                                        profile?['documents'] ?? [];
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ...documents
                                            .asMap()
                                            .entries
                                            .map((entry) {
                                          final idx = entry.key;
                                          final document = entry.value;
                                          final String? docPath =
                                              document['path']?.toString();
                                          final bool hasFile =
                                              docPath != null &&
                                                  docPath.isNotEmpty;
                                          final String? docUrl = hasFile
                                              ? '${ApiConfig.baseUrl.split('/api').first}$docPath'
                                              : null;
                                          String status =
                                              (document['status'] ?? 'pending')
                                                  .toString();
                                          if (!hasFile) {
                                            status = 'not_uploaded';
                                          }
                                          Color statusColor;
                                          String statusLabel;
                                          switch (status) {
                                            case 'verified':
                                              statusColor = Colors.green;
                                              statusLabel = 'Verified';
                                              break;
                                            case 'rejected':
                                              statusColor = Colors.red;
                                              statusLabel = 'Rejected';
                                              break;
                                            case 'not_uploaded':
                                              statusColor = Colors.grey;
                                              statusLabel = 'Not Uploaded';
                                              break;
                                            default:
                                              statusColor = Colors.orange;
                                              statusLabel = 'Pending';
                                          }
                                          return ListTile(
                                            leading: const Icon(
                                                Icons.file_present,
                                                color: Colors.blue),
                                            title: Row(
                                              children: [
                                                Expanded(
                                                    child: Text(
                                                        document['name'] ??
                                                            '')),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: statusColor
                                                        .withOpacity(0.15),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Text(
                                                    statusLabel,
                                                    style: TextStyle(
                                                        color: statusColor,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            subtitle: hasFile
                                                ? Text(
                                                    'Uploaded: ${document['fileName'] ?? (document['filename'] ?? '')}')
                                                : const Text(
                                                    'No file uploaded'),
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(
                                                      Icons.visibility),
                                                  tooltip: 'View',
                                                  onPressed: hasFile
                                                      ? () =>
                                                          showDocumentDialog(
                                                              context, docUrl)
                                                      : null,
                                                ),
                                                if (status == 'rejected')
                                                  IconButton(
                                                    icon: const Icon(
                                                        Icons.refresh,
                                                        color: Colors.orange),
                                                    tooltip: 'Replace',
                                                    onPressed: () async {
                                                      await _pickAndUploadDocument(
                                                          document['type'] ??
                                                              '');
                                                    },
                                                  ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Education Section (conditional)
                          Consumer<AdminSettingsProvider>(
                            builder: (context, adminSettings, _) {
                              if (adminSettings.educationSectionEnabled) {
                                return Column(
                                  children: [
                                    _EducationSection(),
                                    const SizedBox(height: 32),
                                  ],
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                          // Certificates Section (conditional)
                          Consumer<AdminSettingsProvider>(
                            builder: (context, adminSettings, _) {
                              if (adminSettings.certificatesSectionEnabled) {
                                return _CertificateSection();
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                          // Save buttons are now integrated into individual sections
                        ],
                      ),
                    ),
                    if (_isLoading)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withOpacity(0.3),
                          child:
                              const Center(child: CircularProgressIndicator()),
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey[100],
        ),
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emergencyContactController.dispose();
    _emergencyPhoneController.dispose();
    _emergencyContactRelationshipController.dispose();
    super.dispose();
  }
}

// --- Education Section Widget ---
class _EducationSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    final educationList = List<Map<String, dynamic>>.from(
        profileProvider.profile?['education'] ?? []);
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Education',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.blueAccent),
                  onPressed: () => _showEducationDialog(context, null, null),
                ),
              ],
            ),
            ...educationList.isEmpty
                ? [
                    const Text('No education added.',
                        style: TextStyle(color: Colors.grey))
                  ]
                : educationList.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final edu = entry.value;
                    final startDate = edu['startDate'] != null &&
                            edu['startDate'].toString().isNotEmpty
                        ? edu['startDate'].toString().substring(0, 10)
                        : null;
                    final endDate = edu['endDate'] != null &&
                            edu['endDate'].toString().isNotEmpty
                        ? edu['endDate'].toString().substring(0, 10)
                        : null;
                    final dateRange = (startDate != null && endDate != null)
                        ? '$startDate to $endDate'
                        : (startDate ?? (endDate ?? ''));
                    return ListTile(
                      leading: const Icon(Icons.school, color: Colors.blue),
                      title: Text(edu['degree'] ?? ''),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text([
                            edu['institution'] ?? '',
                            edu['fieldOfStudy'] ?? '',
                            if (dateRange.isNotEmpty) dateRange
                          ]
                              .where(
                                  (e) => e != null && e.toString().isNotEmpty)
                              .join(' â€¢ ')),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if ((edu['certificate'] ?? '').toString().isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.remove_red_eye,
                                  color: Colors.blueAccent),
                              tooltip: 'View Certificate',
                              onPressed: () async {
                                showDocumentDialog(context, edu['certificate']);
                              },
                            ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.orange),
                            onPressed: () =>
                                _showEducationDialog(context, edu, idx),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteEducation(context, idx),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
          ],
        ),
      ),
    ); // <-- closes the Card widget
  }

  void _showEducationDialog(
      BuildContext context, Map<String, dynamic>? edu, int? idx) {
    final degreeController = TextEditingController(text: edu?['degree'] ?? '');
    final institutionController =
        TextEditingController(text: edu?['institution'] ?? '');
    final fieldOfStudyController =
        TextEditingController(text: edu?['fieldOfStudy'] ?? '');
    final startDateController =
        TextEditingController(text: formatDate(edu?['startDate']));
    final endDateController =
        TextEditingController(text: formatDate(edu?['endDate']));
    String? documentPath = edu?['certificate'] ?? edu?['document'];
    ValueNotifier<bool> isUploading = ValueNotifier(false);
    ValueNotifier<bool> isSaving = ValueNotifier(false);
    ValueNotifier<String?> errorText = ValueNotifier(null);
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(idx == null ? 'Add Education' : 'Edit Education'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: degreeController,
                    decoration: const InputDecoration(labelText: 'Degree')),
                TextField(
                    controller: institutionController,
                    decoration:
                        const InputDecoration(labelText: 'Institution')),
                TextField(
                    controller: fieldOfStudyController,
                    decoration:
                        const InputDecoration(labelText: 'Field of Study')),
                TextField(
                    controller: startDateController,
                    decoration: const InputDecoration(
                        labelText: 'Start Date (YYYY-MM-DD)')),
                TextField(
                    controller: endDateController,
                    decoration: const InputDecoration(
                        labelText: 'End Date (YYYY-MM-DD)')),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload Certificate'),
                      onPressed: isUploading.value
                          ? null
                          : () async {
                              final picker = ImagePicker();
                              final XFile? file = await picker.pickImage(
                                  source: ImageSource.gallery);
                              if (file != null) {
                                setState(() => isUploading.value = true);
                                final profileProvider =
                                    Provider.of<ProfileProvider>(context,
                                        listen: false);
                                final success =
                                    await profileProvider.uploadDocument(
                                        filePath: file.path,
                                        documentType: 'education');
                                if (success) {
                                  await profileProvider.refreshProfile();
                                  final updatedProfile =
                                      profileProvider.profile;
                                  final updatedList =
                                      List<Map<String, dynamic>>.from(
                                          updatedProfile?['education'] ?? []);
                                  if (idx != null && idx < updatedList.length) {
                                    documentPath = updatedList[idx]
                                            ['certificate'] ??
                                        updatedList[idx]['document'];
                                  } else if (updatedList.isNotEmpty) {
                                    documentPath =
                                        updatedList.last['certificate'] ??
                                            updatedList.last['document'];
                                  }
                                }
                                setState(() => isUploading.value = false);
                              }
                            },
                    ),
                    if ((documentPath?.isNotEmpty ?? false))
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(documentPath!.split('/').last,
                            style: const TextStyle(fontSize: 12)),
                      ),
                  ],
                ),
                ValueListenableBuilder<String?>(
                  valueListenable: errorText,
                  builder: (context, value, _) => value == null
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(value,
                              style: const TextStyle(color: Colors.red)),
                        ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ValueListenableBuilder<bool>(
              valueListenable: isSaving,
              builder: (context, saving, _) => TextButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (degreeController.text.trim().isEmpty ||
                            institutionController.text.trim().isEmpty ||
                            fieldOfStudyController.text.trim().isEmpty) {
                          setState(() => errorText.value =
                              'Degree, Institution, and Field of Study are required.');
                          return;
                        }
                        final startDate = startDateController.text.trim();
                        final endDate = endDateController.text.trim();
                        final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
                        if (!dateRegex.hasMatch(startDate) ||
                            !dateRegex.hasMatch(endDate)) {
                          setState(() => errorText.value =
                              'Start and End Date must be in YYYY-MM-DD format.');
                          return;
                        }
                        setState(() {
                          errorText.value = null;
                          isSaving.value = true;
                        });
                        final profileProvider = Provider.of<ProfileProvider>(
                            context,
                            listen: false);
                        final educationList = List<Map<String, dynamic>>.from(
                            profileProvider.profile?['education'] ?? []);
                        final newEdu = <String, dynamic>{
                          'degree': degreeController.text.trim(),
                          'institution': institutionController.text.trim(),
                          'fieldOfStudy': fieldOfStudyController.text.trim(),
                          'startDate': startDate,
                          'endDate': endDate,
                        };
                        if (documentPath?.isNotEmpty == true) {
                          newEdu['certificate'] = documentPath;
                        }
                        // Remove any keys with empty string values
                        newEdu.removeWhere((k, v) =>
                            v == null || (v is String && v.trim().isEmpty));
                        if (idx == null) {
                          educationList.add(newEdu);
                        } else {
                          educationList[idx] = newEdu;
                        }
                        // Optionally log the payload for debugging
                        // log({'education': educationList});
                        final success = await profileProvider
                            .updateProfile({'education': educationList});
                        setState(() => isSaving.value = false);
                        if (success) {
                          Navigator.pop(ctx);
                          GlobalNotificationService()
                              .showSuccess('Education saved.');
                        } else {
                          setState(() => errorText.value =
                              profileProvider.error ?? 'Failed to save.');
                        }
                      },
                child: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    ); // showDialog
  }

  void _deleteEducation(BuildContext context, int? idx) async {
    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);
    final educationList = List<Map<String, dynamic>>.from(
        profileProvider.profile?['education'] ?? []);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Education'),
        content:
            const Text('Are you sure you want to delete this education entry?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (idx != null && idx < educationList.length) {
                educationList.removeAt(idx);
              }
              await profileProvider.updateProfile({'education': educationList});
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// --- Certificate Section Widget ---
class _CertificateSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    final certList = List<Map<String, dynamic>>.from(
        profileProvider.profile?['certificates'] ?? []);
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Certificates',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.blueAccent),
                  onPressed: () => _showCertificateDialog(context, null, null),
                ),
              ],
            ),
            if (certList.isEmpty)
              const Text('No certificates added.',
                  style: TextStyle(color: Colors.grey))
            else
              ...certList.asMap().entries.map((entry) {
                final idx = entry.key;
                final cert = entry.value;
                final issuer = cert['issuer'] ?? '';
                final date = cert['date'] ?? '';
                return ListTile(
                  leading:
                      const Icon(Icons.workspace_premium, color: Colors.green),
                  title: Text(cert['name'] ?? ''),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text([issuer, date]
                          .where((e) => e != null && e.toString().isNotEmpty)
                          .join(' â€¢ ')),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if ((cert['document'] ?? cert['file'] ?? '')
                          .toString()
                          .isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.remove_red_eye,
                              color: Colors.blueAccent),
                          tooltip: 'View Document',
                          onPressed: () async {
                            showDocumentDialog(
                                context, cert['document'] ?? cert['file']);
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        onPressed: () =>
                            _showCertificateDialog(context, cert, idx),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteCertificate(context, idx),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    ); // <-- closes the Card widget
  }

  void _showCertificateDialog(
      BuildContext context, Map<String, dynamic>? cert, int? idx) {
    final nameController = TextEditingController(text: cert?['name'] ?? '');
    final issuerController = TextEditingController(text: cert?['issuer'] ?? '');
    final dateController =
        TextEditingController(text: cert?['date']?.toString() ?? '');
    String? documentPath = cert?['document'];
    ValueNotifier<bool> isUploading = ValueNotifier(false);
    ValueNotifier<bool> isSaving = ValueNotifier(false);
    ValueNotifier<String?> errorText = ValueNotifier(null);
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: Text(idx == null ? 'Add Certificate' : 'Edit Certificate'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nameController,
                    decoration:
                        const InputDecoration(labelText: 'Certificate Name')),
                TextField(
                    controller: issuerController,
                    decoration: const InputDecoration(labelText: 'Issuer')),
                TextField(
                    controller: dateController,
                    decoration: const InputDecoration(labelText: 'Date')),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload Document'),
                      onPressed: isUploading.value
                          ? null
                          : () async {
                              final picker = ImagePicker();
                              final XFile? file = await picker.pickImage(
                                  source: ImageSource.gallery);
                              if (file != null) {
                                setState(() => isUploading.value = true);
                                final profileProvider =
                                    Provider.of<ProfileProvider>(context,
                                        listen: false);
                                final success =
                                    await profileProvider.uploadDocument(
                                        filePath: file.path,
                                        documentType: 'certificates');
                                if (success) {
                                  await profileProvider.refreshProfile();
                                  final updatedProfile =
                                      profileProvider.profile;
                                  final updatedList =
                                      List<Map<String, dynamic>>.from(
                                          updatedProfile?['certificates'] ??
                                              []);
                                  if (idx != null && idx < updatedList.length) {
                                    documentPath = updatedList[idx]['document'];
                                  } else if (updatedList.isNotEmpty) {
                                    documentPath = updatedList.last['document'];
                                  }
                                }
                                setState(() => isUploading.value = false);
                              }
                            },
                    ),
                    if ((documentPath?.isNotEmpty ?? false))
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(documentPath!.split('/').last,
                            style: const TextStyle(fontSize: 12)),
                      ),
                  ],
                ),
                ValueListenableBuilder<String?>(
                  valueListenable: errorText,
                  builder: (context, value, _) => value == null
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(value,
                              style: const TextStyle(color: Colors.red)),
                        ),
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel')),
              ValueListenableBuilder<bool>(
                valueListenable: isSaving,
                builder: (context, saving, _) => TextButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (nameController.text.trim().isEmpty ||
                              issuerController.text.trim().isEmpty) {
                            setState(() => errorText.value =
                                'Certificate Name and Issuer are required.');
                            return;
                          }
                          setState(() {
                            errorText.value = null;
                            isSaving.value = true;
                          });
                          final profileProvider = Provider.of<ProfileProvider>(
                              context,
                              listen: false);
                          final certList = List<Map<String, dynamic>>.from(
                              profileProvider.profile?['certificates'] ?? []);
                          final newCert = {
                            'name': nameController.text,
                            'issuer': issuerController.text,
                            'date': dateController.text,
                            'document': documentPath ?? '',
                          };
                          if (idx == null) {
                            certList.add(newCert);
                          } else {
                            certList[idx] = newCert;
                          }
                          final success = await profileProvider
                              .updateProfile({'certificates': certList});
                          setState(() => isSaving.value = false);
                          if (success) {
                            Navigator.pop(ctx);
                            GlobalNotificationService()
                                .showSuccess('Certificate saved.');
                          } else {
                            setState(() => errorText.value =
                                profileProvider.error ?? 'Failed to save.');
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Save'),
                ),
              ),
            ],
          );
        },
      ),
    ); // showDialog
  }

  void _deleteCertificate(BuildContext context, int? idx) async {
    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);
    final certList = List<Map<String, dynamic>>.from(
        profileProvider.profile?['certificates'] ?? []);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Certificate'),
        content:
            const Text('Are you sure you want to delete this certificate?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (idx != null && idx < certList.length) {
                certList.removeAt(idx);
              }
              await profileProvider.updateProfile({'certificates': certList});
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
