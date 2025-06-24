import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/profile_provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/api_config.dart'; // Import ApiConfig
import 'package:sns_rooster/widgets/app_drawer.dart'; // Add this import
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:intl/intl.dart';

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
                  child: Image.network(url, fit: BoxFit.contain, errorBuilder: (ctx, error, stack) => const Center(child: Text('Failed to load image'))),
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
        _emergencyContactRelationshipController.text = emergencyContactData['relationship'] ?? '';
      } else if (emergencyContactData is String) {
        _emergencyContactController.text = emergencyContactData;
        _emergencyPhoneController.text = userProfile['emergencyPhone'] ?? '';
        _emergencyContactRelationshipController.text = userProfile['emergencyRelationship'] ?? '';
      } else {
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
      // Use backend field names for emergency contact
      'emergencyContact': _emergencyContactController.text,
      'emergencyPhone': _emergencyPhoneController.text,
      // For relationship, add 'emergencyRelationship' for future backend support
      'emergencyRelationship': _emergencyContactRelationshipController.text,
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
              imageBaseUrl = imageBaseUrl.substring(0, imageBaseUrl.length - '/api'.length);
            }
            String fullUrl = (imageBaseUrl.endsWith('/') || avatarUrl.startsWith('/'))
                ? "$imageBaseUrl${avatarUrl.startsWith('/') ? avatarUrl.substring(1) : avatarUrl}"
                : "$imageBaseUrl/$avatarUrl";
            fullUrl = fullUrl.replaceFirst('//', '/').replaceFirst(':/', '://');
            if (avatarUrl.startsWith('/uploads') && imageBaseUrl.endsWith('/')) {
                fullUrl = "${imageBaseUrl.substring(0, imageBaseUrl.length -1)}$avatarUrl";
            } else if (!avatarUrl.startsWith('/') && !imageBaseUrl.endsWith('/')) {
                fullUrl = "$imageBaseUrl/$avatarUrl";
            } else {
                fullUrl = "$imageBaseUrl$avatarUrl".replaceAll(RegExp(r'(?<!:)/{2,}'), '/');
            }
            backgroundImage = NetworkImage(fullUrl);
            print('Constructed Avatar URL for Profile: $fullUrl');
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
                      final currentProfileProvider = Provider.of<ProfileProvider>(context, listen: false);
                      _loadUserDataInternal(currentProfileProvider);
                    }
                  });
                },
              ),
            ],
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
                                      profile?['fullName'] ?? profile?['firstName'] ?? '',
                                      style: theme.textTheme.titleLarge,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      profile?['email'] ?? '',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    ElevatedButton.icon(
                                      onPressed: _isEditing ? _pickAndUploadImage : null,
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
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Personal Information',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    IconButton(
                                      icon: Icon(_isEditingPersonal ? Icons.check : Icons.edit, color: _isEditing ? Colors.blueAccent : Colors.grey),
                                      onPressed: _isEditing
                                          ? () {
                                              setState(() {
                                                _isEditingPersonal = !_isEditingPersonal;
                                              });
                                            }
                                          : null,
                                      tooltip: _isEditing ? (_isEditingPersonal ? 'Done editing section' : 'Edit section') : 'Enable main edit mode to edit',
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
                                        icon: Icon(_isEditingEmergency ? Icons.check : Icons.edit, color: _isEditing ? Colors.blueAccent : Colors.grey),
                                        onPressed: _isEditing
                                            ? () {
                                                setState(() {
                                                  _isEditingEmergency = !_isEditingEmergency;
                                                });
                                              }
                                            : null,
                                        tooltip: _isEditing ? (_isEditingEmergency ? 'Done editing section' : 'Edit section') : 'Enable main edit mode to edit',
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
                                const SizedBox(height: 16),
                                // Document status display
                                Consumer<ProfileProvider>(
                                  builder: (context, profileProvider, _) {
                                    final profile = profileProvider.profile;
                                    final idCardPath = profile?['idCard'];
                                    final passportPath = profile?['passport'];
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        ListTile(
                                          leading: const Icon(Icons.credit_card, color: Colors.blue),
                                          title: const Text('ID Card'),
                                          subtitle: idCardPath != null && idCardPath.isNotEmpty
                                              ? Text('Uploaded: ${idCardPath.split('/').last}')
                                              : const Text('No ID Card uploaded'),
                                          trailing: idCardPath != null && idCardPath.isNotEmpty
                                              ? IconButton(
                                                  icon: const Icon(Icons.visibility),
                                                  onPressed: () async {
                                                    final url = ApiConfig.baseUrl.replaceAll('/api', '')+idCardPath;
                                                    showDocumentDialog(context, url);
                                                  },
                                                )
                                              : null,
                                        ),
                                        ListTile(
                                          leading: const Icon(Icons.book, color: Colors.green),
                                          title: const Text('Passport'),
                                          subtitle: passportPath != null && passportPath.isNotEmpty
                                              ? Text('Uploaded: ${passportPath.split('/').last}')
                                              : const Text('No Passport uploaded'),
                                          trailing: passportPath != null && passportPath.isNotEmpty
                                              ? IconButton(
                                                  icon: const Icon(Icons.visibility),
                                                  onPressed: () async {
                                                    final url = ApiConfig.baseUrl.replaceAll('/api', '')+passportPath;
                                                    showDocumentDialog(context, url);
                                                  },
                                                )
                                              : null,
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Education Section
                          _EducationSection(),
                          const SizedBox(height: 32),
                          // Certificates Section
                          _CertificateSection(),
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
      },
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


// --- Education Section Widget ---
class _EducationSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    final educationList = List<Map<String, dynamic>>.from(profileProvider.profile?['education'] ?? []);
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
                const Text('Education', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.blueAccent),
                  onPressed: () => _showEducationDialog(context, null, null),
                ),
              ],
            ),
            ...educationList.isEmpty
                ? [const Text('No education added.', style: TextStyle(color: Colors.grey))]
                : educationList.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final edu = entry.value;
                    final startDate = edu['startDate'] != null && edu['startDate'].toString().isNotEmpty ? edu['startDate'].toString().substring(0, 10) : null;
                    final endDate = edu['endDate'] != null && edu['endDate'].toString().isNotEmpty ? edu['endDate'].toString().substring(0, 10) : null;
                    final dateRange = (startDate != null && endDate != null)
                        ? '$startDate to $endDate'
                        : (startDate != null ? startDate : (endDate ?? ''));
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
                          ].where((e) => e != null && e.toString().isNotEmpty).join(' • ')),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if ((edu['certificate'] ?? '').toString().isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.remove_red_eye, color: Colors.blueAccent),
                              tooltip: 'View Certificate',
                              onPressed: () => showDocumentDialog(context, edu['certificate']),
                            ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.orange),
                            onPressed: () => _showEducationDialog(context, edu, idx),
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

  void _showEducationDialog(BuildContext context, Map<String, dynamic>? edu, int? idx) {
  final degreeController = TextEditingController(text: edu?['degree'] ?? '');
  final institutionController = TextEditingController(text: edu?['institution'] ?? '');
  final fieldOfStudyController = TextEditingController(text: edu?['fieldOfStudy'] ?? '');
  final startDateController = TextEditingController(text: formatDate(edu?['startDate']));
  final endDateController = TextEditingController(text: formatDate(edu?['endDate']));
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
              TextField(controller: degreeController, decoration: const InputDecoration(labelText: 'Degree')),
              TextField(controller: institutionController, decoration: const InputDecoration(labelText: 'Institution')),
              TextField(controller: fieldOfStudyController, decoration: const InputDecoration(labelText: 'Field of Study')),
              TextField(controller: startDateController, decoration: const InputDecoration(labelText: 'Start Date (YYYY-MM-DD)')),
              TextField(controller: endDateController, decoration: const InputDecoration(labelText: 'End Date (YYYY-MM-DD)')),
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
                            final XFile? file = await picker.pickImage(source: ImageSource.gallery);
                            if (file != null) {
                              setState(() => isUploading.value = true);
                              final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
                              final success = await profileProvider.uploadDocument(file.path, 'education');
                              if (success) {
                                await profileProvider.refreshProfile();
                                final updatedProfile = profileProvider.profile;
                                final updatedList = List<Map<String, dynamic>>.from(updatedProfile?['education'] ?? []);
                                if (idx != null && idx < updatedList.length) {
                                  documentPath = updatedList[idx]['certificate'] ?? updatedList[idx]['document'];
                                } else if (updatedList.isNotEmpty) {
                                  documentPath = updatedList.last['certificate'] ?? updatedList.last['document'];
                                }
                              }
                              setState(() => isUploading.value = false);
                            }
                          },
                  ),
                  if ((documentPath?.isNotEmpty ?? false))
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(documentPath!.split('/').last, style: const TextStyle(fontSize: 12)),
                    ),
                ],
              ),
              ValueListenableBuilder<String?>(
                valueListenable: errorText,
                builder: (context, value, _) => value == null
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(value, style: const TextStyle(color: Colors.red)),
                      ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ValueListenableBuilder<bool>(
            valueListenable: isSaving,
            builder: (context, saving, _) => TextButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (degreeController.text.trim().isEmpty || institutionController.text.trim().isEmpty || fieldOfStudyController.text.trim().isEmpty) {
                        setState(() => errorText.value = 'Degree, Institution, and Field of Study are required.');
                        return;
                      }
                      final startDate = startDateController.text.trim();
                      final endDate = endDateController.text.trim();
                      final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
                      if (!dateRegex.hasMatch(startDate) || !dateRegex.hasMatch(endDate)) {
                        setState(() => errorText.value = 'Start and End Date must be in YYYY-MM-DD format.');
                        return;
                      }
                      setState(() {
                        errorText.value = null;
                        isSaving.value = true;
                      });
                      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
                      final educationList = List<Map<String, dynamic>>.from(profileProvider.profile?['education'] ?? []);
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
                      newEdu.removeWhere((k, v) => v == null || (v is String && v.trim().isEmpty));
                      if (idx == null) {
                        educationList.add(newEdu);
                      } else {
                        educationList[idx] = newEdu;
                      }
                      // Optionally log the payload for debugging
                      // print({'education': educationList});
                      final success = await profileProvider.updateProfile({'education': educationList});
                      setState(() => isSaving.value = false);
                      if (success) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Education saved.')));
                      } else {
                        setState(() => errorText.value = profileProvider.error ?? 'Failed to save.');
                      }
                    },
              child: saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
            ),
          ),
        ],
      ),
    ),
  ); // showDialog
  }

  void _deleteEducation(BuildContext context, int idx) async {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final educationList = List<Map<String, dynamic>>.from(profileProvider.profile?['education'] ?? []);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Education'),
        content: const Text('Are you sure you want to delete this education entry?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              educationList.removeAt(idx);
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
    final certList = List<Map<String, dynamic>>.from(profileProvider.profile?['certificates'] ?? []);
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
                const Text('Certificates', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.blueAccent),
                  onPressed: () => _showCertificateDialog(context, null, null),
                ),
              ],
            ),
            if (certList.isEmpty)
              const Text('No certificates added.', style: TextStyle(color: Colors.grey))
            else
              ...certList.asMap().entries.map((entry) {
                final idx = entry.key;
                final cert = entry.value;
                final issuer = cert['issuer'] ?? '';
                final date = cert['date'] ?? '';
                return ListTile(
                  leading: const Icon(Icons.workspace_premium, color: Colors.green),
                  title: Text(cert['name'] ?? ''),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text([
                        issuer,
                        date
                      ].where((e) => e != null && e.toString().isNotEmpty).join(' • ')),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if ((cert['document'] ?? cert['file'] ?? '').toString().isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.remove_red_eye, color: Colors.blueAccent),
                          tooltip: 'View Document',
                          onPressed: () => showDocumentDialog(context, cert['document'] ?? cert['file']),
                        ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        onPressed: () => _showCertificateDialog(context, cert, idx),
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

  void _showCertificateDialog(BuildContext context, Map<String, dynamic>? cert, int? idx) {
    final nameController = TextEditingController(text: cert?['name'] ?? '');
    final issuerController = TextEditingController(text: cert?['issuer'] ?? '');
    final dateController = TextEditingController(text: cert?['date']?.toString() ?? '');
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
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Certificate Name')),
                TextField(controller: issuerController, decoration: const InputDecoration(labelText: 'Issuer')),
                TextField(controller: dateController, decoration: const InputDecoration(labelText: 'Date')),
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
                              final XFile? file = await picker.pickImage(source: ImageSource.gallery);
                              if (file != null) {
                                setState(() => isUploading.value = true);
                                final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
                                final success = await profileProvider.uploadDocument(file.path, 'certificates');
                                if (success) {
                                  await profileProvider.refreshProfile();
                                  final updatedProfile = profileProvider.profile;
                                  final updatedList = List<Map<String, dynamic>>.from(updatedProfile?['certificates'] ?? []);
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
                        child: Text(documentPath!.split('/').last, style: const TextStyle(fontSize: 12)),
                      ),
                  ],
                ),
                ValueListenableBuilder<String?>(
                  valueListenable: errorText,
                  builder: (context, value, _) => value == null
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(value, style: const TextStyle(color: Colors.red)),
                        ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ValueListenableBuilder<bool>(
                valueListenable: isSaving,
                builder: (context, saving, _) => TextButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (nameController.text.trim().isEmpty || issuerController.text.trim().isEmpty) {
                            setState(() => errorText.value = 'Certificate Name and Issuer are required.');
                            return;
                          }
                          setState(() {
                            errorText.value = null;
                            isSaving.value = true;
                          });
                          final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
                          final certList = List<Map<String, dynamic>>.from(profileProvider.profile?['certificates'] ?? []);
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
                          final success = await profileProvider.updateProfile({'certificates': certList});
                          setState(() => isSaving.value = false);
                          if (success) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Certificate saved.')));
                          } else {
                            setState(() => errorText.value = profileProvider.error ?? 'Failed to save.');
                          }
                        },
                  child: saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
                ),
              ),
            ],
          );
        },
      ),
    ); // showDialog
  }

  void _deleteCertificate(BuildContext context, int idx) async {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final certList = List<Map<String, dynamic>>.from(profileProvider.profile?['certificates'] ?? []);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Certificate'),
        content: const Text('Are you sure you want to delete this certificate?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              certList.removeAt(idx);
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
