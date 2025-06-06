import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'widgets/recent_activity_section.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _profileImage;

  // Profile data state
  String name = 'John Doe';
  String role = 'Software Engineer';
  String email = 'john.doe@example.com';
  String phone = '+1 234 567 890';
  String address = '123 Main Street, City, Country';
  String employeeId = 'EMP123456';
  String dateOfJoining = '01 Jan 2022';
  String department = 'Development';

  List<String> _recentActivities = [
    'Logged in',
    'Updated profile picture',
    'Submitted leave request',
    'Checked notifications',
  ];


  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source != null) {
      final picked = await picker.pickImage(source: source, imageQuality: 80);
      if (picked != null) {
        setState(() {
          _profileImage = File(picked.path);
        });
      }
    }
  }

  void _openEditProfileSheet() async {
    final updatedProfile = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _EditProfileSheet(
        name: name,
        role: role,
        email: email,
        phone: phone,
        address: address,
        employeeId: employeeId,
        dateOfJoining: dateOfJoining,
        department: department,
      ),
    );

    if (updatedProfile != null) {
      setState(() {
        name = updatedProfile['name'] ?? name;
        role = updatedProfile['role'] ?? role;
        email = updatedProfile['email'] ?? email;
        phone = updatedProfile['phone'] ?? phone;
        address = updatedProfile['address'] ?? address;
        employeeId = updatedProfile['employeeId'] ?? employeeId;
        dateOfJoining = updatedProfile['dateOfJoining'] ?? dateOfJoining;
        department = updatedProfile['department'] ?? department;

        _recentActivities.insert(0, 'Profile updated on \${DateTime.now()}');
        if (_recentActivities.length > 10) {
          _recentActivities.removeLast();
        }
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated!')));
    }
  }

  List<String> getRecentActivities() {
    return _recentActivities;
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Profile',
            onPressed: _openEditProfileSheet,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 54,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!)
                          : const AssetImage(
                                  'assets/images/profile_placeholder.png',
                                )
                                as ImageProvider,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: _pickProfileImage,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(name, style: Theme.of(context).textTheme.headlineSmall),
            Text(role, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _ProfileInfoRow(
                      icon: Icons.email,
                      label: 'Email',
                      value: email,
                    ),
                    _ProfileInfoRow(
                      icon: Icons.phone,
                      label: 'Phone',
                      value: phone,
                    ),
                    _ProfileInfoRow(
                      icon: Icons.location_on,
                      label: 'Address',
                      value: address,
                    ),
                    _ProfileInfoRow(
                      icon: Icons.badge,
                      label: 'Employee ID',
                      value: employeeId,
                    ),
                    _ProfileInfoRow(
                      icon: Icons.calendar_today,
                      label: 'Date of Joining',
                      value: dateOfJoining,
                    ),
                    _ProfileInfoRow(
                      icon: Icons.business,
                      label: 'Department',
                      value: department,
                    ),
            RecentActivitySection(
              activities: _recentActivities,
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
}

class _ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileInfoRow({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  final String name;
  final String role;
  final String email;
  final String phone;
  final String address;
  final String employeeId;
  final String dateOfJoining;
  final String department;

  const _EditProfileSheet({
    Key? key,
    required this.name,
    required this.role,
    required this.email,
    required this.phone,
    required this.address,
    required this.employeeId,
    required this.dateOfJoining,
    required this.department,
  }) : super(key: key);

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late String name;
  late String role;
  late String email;
  late String phone;
  late String address;
  late String employeeId;
  late String dateOfJoining;
  late String department;

  @override
  void initState() {
    super.initState();
    name = widget.name;
    role = widget.role;
    email = widget.email;
    phone = widget.phone;
    address = widget.address;
    employeeId = widget.employeeId;
    dateOfJoining = widget.dateOfJoining;
    department = widget.department;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Edit Profile',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: name,
                decoration: const InputDecoration(labelText: 'Name'),
                onChanged: (v) => name = v,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter your name' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: role,
                decoration: const InputDecoration(labelText: 'Role'),
                onChanged: (v) => role = v,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter your role' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: email,
                decoration: const InputDecoration(labelText: 'Email'),
                onChanged: (v) => email = v,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter your email' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: phone,
                decoration: const InputDecoration(labelText: 'Phone'),
                onChanged: (v) => phone = v,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter your phone' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: address,
                decoration: const InputDecoration(labelText: 'Address'),
                onChanged: (v) => address = v,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter your address' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: employeeId,
                decoration: const InputDecoration(labelText: 'Employee ID'),
                onChanged: (v) => employeeId = v,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter your employee ID' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: dateOfJoining,
                decoration: const InputDecoration(labelText: 'Date of Joining'),
                onChanged: (v) => dateOfJoining = v,
                validator: (v) => v == null || v.isEmpty
                    ? 'Enter your date of joining'
                    : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: department,
                decoration: const InputDecoration(labelText: 'Department'),
                onChanged: (v) => department = v,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter your department' : null,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        Navigator.pop(context, {
                          'name': name,
                          'role': role,
                          'email': email,
                          'phone': phone,
                          'address': address,
                          'employeeId': employeeId,
                          'dateOfJoining': dateOfJoining,
                          'department': department,
                        });
                      }
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
