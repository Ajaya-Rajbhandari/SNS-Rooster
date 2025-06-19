import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/profile_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../config/api_config.dart'; // Import ApiConfig
import 'package:sns_rooster/widgets/app_drawer.dart'; // Add this import

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
  final TextEditingController _emergencyContactController = TextEditingController();
  final TextEditingController _emergencyPhoneController = TextEditingController();
  final TextEditingController _emergencyContactRelationshipController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = false; // For local operations like save, image pick
  bool _isEditingPersonal = false;
  bool _isEditingEmergency = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
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
        _emergencyContactRelationshipController.text = emergencyContactData['relationship'] ?? '';
      } else {
        // Fallback for potentially flat structure if 'emergencyContact' is not a map
        // This matches how _saveProfile is structured if it sends flat properties
        _emergencyContactController.text = userProfile['emergencyContactName'] ?? '';
        _emergencyPhoneController.text = userProfile['emergencyContactPhone'] ?? '';
        _emergencyContactRelationshipController.text = userProfile['emergencyContactRelationship'] ?? '';
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
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      bool success = await profileProvider.updateProfilePicture(image.path);
      setState(() {
        _isLoading = false;
      });
      if (success) {
        // Optionally, show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated successfully!')),
        );
      } else {
        // Optionally, show an error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(profileProvider.error ?? 'Failed to update profile picture.')),
        );
      }
    } else {
      // User canceled the picker
      print('No image selected.');
    }
  }

  Future<void> _pickAndUploadDocument(String documentType) async {
    try {
      print('Attempting to upload $documentType');

      // File picking logic
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(source: ImageSource.gallery);

      if (file == null) {
        print('No file selected.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No file selected.')),
        );
        return;
      }

      print('File selected: ${file.path}');

      // File size validation
      final fileSize = await file.length();
      if (fileSize > 5 * 1024 * 1024) {
        print('File size exceeds limit.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File size must be less than 5MB.')),
        );
        return;
      }

      // Upload logic
      setState(() {
        _isLoading = true;
      });

      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      final success = await profileProvider.uploadDocument(file.path, documentType);

      setState(() {
        _isLoading = false;
      });

      if (success) {
        print('Document uploaded successfully.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document uploaded successfully!')),
        );
      } else {
        print('Failed to upload document.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(profileProvider.error ?? 'Failed to upload document.')),
        );
      }
    } catch (e) {
      print('Error during document upload: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred during upload. Please try again.')),
      );
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isLoading = true;
    });
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    
    Map<String, dynamic> updates = {
      'firstName': _firstNameController.text,
      'lastName': _lastNameController.text,
      // 'email': _emailController.text, // Email is not editable, so don't send for update
      'phone': _phoneController.text,
      'address': _addressController.text,
      // Assuming backend expects these as top-level properties for now
      'emergencyContactName': _emergencyContactController.text,
      'emergencyContactPhone': _emergencyPhoneController.text,
      'emergencyContactRelationship': _emergencyContactRelationshipController.text, // Added
    };

    await profileProvider.updateProfile(updates);
    setState(() {
      _isLoading = false;
      _isEditing = false;
      _isEditingPersonal = false;
      _isEditingEmergency = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileProvider = Provider.of<ProfileProvider>(context);

    String? avatarUrl = profileProvider.profile?['avatar'];
    ImageProvider? backgroundImage;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      if (avatarUrl.startsWith('http')) {
        backgroundImage = NetworkImage(avatarUrl);
      } else {
        // Construct a base URL for images, removing '/api' if present
        String imageBaseUrl = ApiConfig.baseUrl;
        if (imageBaseUrl.endsWith('/api')) {
          imageBaseUrl = imageBaseUrl.substring(0, imageBaseUrl.length - '/api'.length);
        }

        // Prepend imageBaseUrl if it's a relative path
        String fullUrl = (imageBaseUrl.endsWith('/') || avatarUrl.startsWith('/'))
            ? "$imageBaseUrl${avatarUrl.startsWith('/') ? avatarUrl.substring(1) : avatarUrl}"
            : "$imageBaseUrl/$avatarUrl";
        
        // Ensure no double slashes, except for http://
        fullUrl = fullUrl.replaceFirst('//', '/').replaceFirst(':/', '://');
        // Correct common issue: if avatarUrl starts with /uploads and imageBaseUrl ends with /, remove one slash
        if (avatarUrl.startsWith('/uploads') && imageBaseUrl.endsWith('/')) {
            fullUrl = "${imageBaseUrl.substring(0, imageBaseUrl.length -1)}$avatarUrl";
        } else if (!avatarUrl.startsWith('/') && !imageBaseUrl.endsWith('/')) {
            fullUrl = "$imageBaseUrl/$avatarUrl";
        } else {
            // Default concatenation, then clean up double slashes
            fullUrl = "$imageBaseUrl$avatarUrl".replaceAll(RegExp(r'(?<!:)/{2,}'), '/');
        }

        backgroundImage = NetworkImage(fullUrl);
        print('Constructed Avatar URL for Profile: $fullUrl'); // For debugging
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
                if (!_isEditing) {
                  _isEditingPersonal = false;
                  _isEditingEmergency = false;
                  _saveProfile();
                } else {
                  // When entering edit mode, load current data into controllers
                  final currentProfileProvider = Provider.of<ProfileProvider>(context, listen: false);
                  _loadUserDataInternal(currentProfileProvider); // Use the internal loader
                }
              });
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: profileProvider.isLoading && !_isLoading // Show main loader if profileProvider is loading AND local op isn't active
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
                        child: Column(
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
                              profileProvider.profile?['fullName'] ?? profileProvider.profile?['firstName'] ?? '', // Fallback to firstName if fullName is not available
                              style: theme.textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              profileProvider.profile?['email'] ?? '',
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: _isEditing ? _pickAndUploadImage : null,
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Change Photo'),
                            ),
                          ],
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Personal Information',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                IconButton(
                                  icon: Icon(_isEditingPersonal ? Icons.check : Icons.edit, color: Colors.blueAccent),
                                  onPressed: () {
                                    if (_isEditing) { // Only allow toggling section edit if main edit is active
                                      setState(() {
                                        _isEditingPersonal = !_isEditingPersonal;
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _firstNameController,
                              label: 'First Name',
                              icon: Icons.person,
                              enabled: _isEditing && _isEditingPersonal, // Modified
                            ),
                            _buildTextField(
                              controller: _lastNameController,
                              label: 'Last Name',
                              icon: Icons.person,
                              enabled: _isEditing && _isEditingPersonal, // Modified
                            ),
                            _buildTextField(
                              controller: _emailController,
                              label: 'Email',
                              icon: Icons.email,
                              enabled: false, // Email usually not editable by user directly
                            ),
                            _buildTextField(
                              controller: _phoneController,
                              label: 'Phone',
                              icon: Icons.phone,
                              enabled: _isEditing && _isEditingPersonal, // Modified
                            ),
                            _buildTextField(
                              controller: _addressController,
                              label: 'Address',
                              icon: Icons.home,
                              enabled: _isEditing && _isEditingPersonal, // Modified
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
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Emergency Contact',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  IconButton(
                                    icon: Icon(_isEditingEmergency ? Icons.check : Icons.edit, color: Colors.blueAccent),
                                    onPressed: () {
                                      if (_isEditing) { // Only allow toggling section edit if main edit is active
                                        setState(() {
                                          _isEditingEmergency = !_isEditingEmergency;
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _emergencyContactController,
                                label: 'Contact Name',
                                icon: Icons.person_pin_rounded,
                                enabled: _isEditing && _isEditingEmergency, // Modified
                              ),
                              _buildTextField(
                                controller: _emergencyPhoneController,
                                label: 'Contact Phone',
                                icon: Icons.phone_iphone,
                                enabled: _isEditing && _isEditingEmergency, // Modified
                              ),
                              _buildTextField(
                                controller: _emergencyContactRelationshipController,
                                label: 'Relationship',
                                icon: Icons.people,
                                enabled: _isEditing && _isEditingEmergency, // Modified
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
                                  style: theme.textTheme.titleLarge?.copyWith(
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
                                      await _pickAndUploadDocument('idCard');
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.file_present),
                                    label: const Text('Upload Passport'),
                                    onPressed: () async {
                                      await _pickAndUploadDocument('passport');
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text('Accepted formats: PDF, JPG, PNG', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Save Button
                      if (_isEditing)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator()
                                : const Text('Save Changes'),
                          ),
                        ),
                    ],
                  ),
                ),
                if (_isLoading)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.3),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
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
