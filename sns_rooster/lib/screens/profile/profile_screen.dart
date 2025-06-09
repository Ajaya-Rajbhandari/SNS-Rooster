import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'widgets/recent_activity_section.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/navigation_drawer.dart';
import '../../widgets/user_avatar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  bool _isEditing = false;
  final ImagePicker _picker = ImagePicker();
  bool _isInitialized = false;
  // Track if we are in a mandatory setup flow
  bool _isMandatorySetup = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadProfile();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _emergencyContactController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    print("Loading profile...");
    if (!mounted) return;
    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);
    await profileProvider.fetchProfile();
    print("Profile loaded: ${profileProvider.profile}");

    if (!mounted) return;

    if (profileProvider.profile != null) {
      setState(() {
        _nameController.text = profileProvider.profile!['name'] ?? '';
        _emailController.text = profileProvider.profile!['email'] ?? '';
        _phoneController.text = profileProvider.profile!['phone'] ?? '';
        _emergencyContactController.text =
            profileProvider.profile!['emergencyContact'] ?? '';
        _isInitialized = true;

        // Determine if it's a mandatory setup
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (authProvider.isAuthenticated &&
            (authProvider.user?['isProfileComplete'] == false ||
                profileProvider.profile!['isProfileComplete'] == false)) {
          _isEditing = true; // Force edit mode
          _isMandatorySetup = true;
        }
      });
    } else {
      print("Profile is null, _isInitialized not set.");
      // If profile is null, it means no data, so it's an incomplete profile
      setState(() {
        _isMandatorySetup = true;
        _isEditing = true;
        _isInitialized = true; // Still initialize to show the form
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (!mounted) return;

    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Check if essential fields are complete for setting isProfileComplete to true
    bool complete = _nameController.text.isNotEmpty &&
        _emailController.text.isNotEmpty &&
        _phoneController.text.isNotEmpty &&
        _emergencyContactController
            .text.isNotEmpty; // Add any other required fields

    final updates = {
      'name': _nameController.text,
      'phone': _phoneController.text,
      'emergencyContact': _emergencyContactController.text,
      'isProfileComplete': complete, // Update the flag based on completion
    };

    final success = await profileProvider.updateProfile(updates);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      // If profile was incomplete and now complete, navigate to dashboard
      if (_isMandatorySetup && complete) {
        // Update auth provider's user data for consistency
        authProvider.user?['isProfileComplete'] = true;
        final route = authProvider.user?['role'] == 'admin'
            ? '/admin_dashboard'
            : '/employee_dashboard';
        Navigator.pushReplacementNamed(context, route);
      } else {
        setState(() => _isEditing = false);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(profileProvider.error ?? 'Failed to update profile')),
      );
    }
  }

  Future<void> _updateProfilePicture() async {
    if (!mounted) return;

    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null || !mounted) return;

      print('Debug: Selected image path: ${image.path}');

      final profileProvider =
          Provider.of<ProfileProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await profileProvider.updateProfilePicture(image.path);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated successfully')),
        );
        print(
            'Debug: Profile picture updated. Current avatar path: ${profileProvider.profile?['avatar']}');
        // Update AuthProvider's user data for consistency with dashboard
        authProvider.updateUser(profileProvider.profile!);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  profileProvider.error ?? 'Failed to update profile picture')),
        );
        print(
            'Debug: Failed to update profile picture. Error: ${profileProvider.error}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final profileProvider = Provider.of<ProfileProvider>(context);

    if (profileProvider.error != null) {
      return Scaffold(
          body: Center(child: Text("Error: ${profileProvider.error}")));
    }
    if (!_isInitialized || profileProvider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return WillPopScope(
      onWillPop: () async {
        if (_isMandatorySetup) {
          // Prevent going back if profile setup is mandatory
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Please complete your profile first.')),
          );
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          leading:
              _isMandatorySetup // Only show back button if not mandatory setup
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).pop(),
                    )
                  : Builder(
                      builder: (context) => IconButton(
                        icon: const Icon(Icons.menu),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                    ),
          actions: [
            if (!_isMandatorySetup && !_isEditing)
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => setState(() => _isEditing = true),
              )
            else if (!_isMandatorySetup)
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: _updateProfile,
              ),
            if (_isEditing && !_isMandatorySetup)
              IconButton(
                icon: const Icon(Icons.cancel),
                onPressed: () {
                  setState(() => _isEditing = false);
                  _loadProfile(); // Reset form fields
                },
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile Header with Avatar and Name/Role
                Container(
                  padding: const EdgeInsets.all(16.0),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.shadow.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          UserAvatar(
                              avatarUrl: profileProvider.profile?['avatar'],
                              radius: 60),
                          if (_isEditing)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _updateProfilePicture,
                                child: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: theme.colorScheme.secondary,
                                  child: Icon(Icons.camera_alt,
                                      color: theme.colorScheme.onSecondary,
                                      size: 20),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(authProvider.user?['name'] ?? 'Employee Name',
                          style: theme.textTheme.headlineSmall?.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(authProvider.user?['role'] ?? 'Employee Role',
                          style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.7))),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    prefixIcon:
                        Icon(Icons.person, color: theme.colorScheme.primary),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: theme.colorScheme.primary, width: 2),
                    ),
                  ),
                  enabled: _isEditing,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Please enter your name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon:
                        Icon(Icons.email, color: theme.colorScheme.primary),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: theme.colorScheme.primary, width: 2),
                    ),
                  ),
                  enabled: false, // Email cannot be changed
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon:
                        Icon(Icons.phone, color: theme.colorScheme.primary),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: theme.colorScheme.primary, width: 2),
                    ),
                  ),
                  enabled: _isEditing,
                  keyboardType: TextInputType.phone,
                  validator: (value) => value?.isEmpty ?? true
                      ? 'Please enter your phone number'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emergencyContactController,
                  decoration: InputDecoration(
                    labelText: 'Emergency Contact',
                    prefixIcon: Icon(Icons.emergency_share,
                        color: theme.colorScheme.primary),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: theme.colorScheme.primary, width: 2),
                    ),
                  ),
                  enabled: _isEditing,
                  keyboardType: TextInputType.phone,
                  validator: (value) => value?.isEmpty ?? true
                      ? 'Please enter emergency contact'
                      : null,
                ),
                const SizedBox(height: 24),
                // Work Information Section
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Work Information',
                          style: theme.textTheme.titleLarge?.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(context, 'Department',
                            profileProvider.profile?['department'] ?? 'N/A'),
                        _buildInfoRow(context, 'Position',
                            profileProvider.profile?['position'] ?? 'N/A'),
                        _buildInfoRow(context, 'Role',
                            profileProvider.profile?['role'] ?? 'N/A'),
                        _buildInfoRow(context, 'Employee ID',
                            profileProvider.profile?['employeeId'] ?? 'N/A'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        drawer: const AppNavigationDrawer(),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7))),
          Text(value,
              style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
