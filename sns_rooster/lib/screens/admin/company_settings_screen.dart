import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/company_settings_provider.dart';
import '../../services/company_settings_service.dart';

class CompanySettingsScreen extends StatefulWidget {
  const CompanySettingsScreen({super.key});

  @override
  State<CompanySettingsScreen> createState() => _CompanySettingsScreenState();
}

class _CompanySettingsScreenState extends State<CompanySettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();

  // Controllers for form fields
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

  // Simple fields
  String _employeeCount = '1-10';
  String _logoUrl = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeDefaults();
    _loadSettings();
  }

  void _initializeDefaults() {
    _nameController.text = 'Your Company Name';
    _countryController.text = 'Nepal';
  }

  Future<void> _loadSettings() async {
    final provider =
        Provider.of<CompanySettingsProvider>(context, listen: false);
    await provider.load();
    final s = provider.settings;
    if (s != null && mounted) {
      setState(() {
        _nameController.text = s['name'] ?? 'Your Company Name';
        _legalNameController.text = s['legalName'] ?? '';
        _addressController.text = s['address'] ?? '';
        _cityController.text = s['city'] ?? '';
        _stateController.text = s['state'] ?? '';
        _postalCodeController.text = s['postalCode'] ?? '';
        _countryController.text = s['country'] ?? 'Nepal';
        _phoneController.text = s['phone'] ?? '';
        _emailController.text = s['email'] ?? '';
        _websiteController.text = s['website'] ?? '';
        _taxIdController.text = s['taxId'] ?? '';
        _registrationNumberController.text = s['registrationNumber'] ?? '';
        _descriptionController.text = s['description'] ?? '';
        _industryController.text = s['industry'] ?? '';
        _establishedYearController.text =
            s['establishedYear']?.toString() ?? '';
        _employeeCount = s['employeeCount'] ?? '1-10';
        _logoUrl = s['logoUrl'] ?? '';
        _isLoading = false;
      });
    } else {
      setState(() {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Company Information')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Company Information')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Company logo section
              _buildLogoSection(theme),
              const Divider(height: 32),

              // Basic Information
              _buildBasicInformation(theme),
              const Divider(height: 32),

              // Contact Information
              _buildContactInformation(theme),
              const Divider(height: 32),

              // Legal & Business Information
              _buildLegalInformation(theme),
              const Divider(height: 32),

              // Additional Information
              _buildAdditionalInformation(theme),
              const SizedBox(height: 32),

              // Save Button
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Company Information'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Company Logo', style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        Consumer<CompanySettingsProvider>(
          builder: (context, provider, child) {
            final logoUrl = provider.logoUrl;
            return Row(
              children: [
                // Logo preview
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outline),
                    borderRadius: BorderRadius.circular(8),
                    color: theme.colorScheme.surfaceVariant,
                  ),
                  child: logoUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            logoUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.business,
                              size: 48,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.business,
                          size: 48,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                ),
                const SizedBox(width: 16),
                // Upload buttons
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ElevatedButton.icon(
                        onPressed: provider.isUploading
                            ? null
                            : () => _pickLogo(ImageSource.gallery),
                        icon: provider.isUploading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.photo_library),
                        label: Text(provider.isUploading
                            ? 'Uploading...'
                            : 'Choose from Gallery'),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: provider.isUploading
                            ? null
                            : () => _pickLogo(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Take Photo'),
                      ),
                      const SizedBox(height: 8),
                      if (logoUrl.isNotEmpty && !provider.isUploading)
                        TextButton.icon(
                          onPressed: _removeLogo,
                          icon: const Icon(Icons.delete, color: Colors.red),
                          label: const Text('Remove Logo',
                              style: TextStyle(color: Colors.red)),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          'Recommended: Square image, at least 200x200px, max 5MB',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildBasicInformation(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Basic Information', style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Company Name *',
            hintText: 'Enter your company display name',
          ),
          validator: (v) =>
              v?.trim().isEmpty == true ? 'Company name is required' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _legalNameController,
          decoration: const InputDecoration(
            labelText: 'Legal Name',
            hintText: 'Official registered company name',
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _industryController,
                decoration: const InputDecoration(
                  labelText: 'Industry',
                  hintText: 'e.g., Technology, Healthcare',
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _establishedYearController,
                decoration: const InputDecoration(
                  labelText: 'Established Year',
                  hintText: 'YYYY',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v?.trim().isNotEmpty == true) {
                    final year = int.tryParse(v!);
                    final currentYear = DateTime.now().year;
                    if (year == null || year < 1800 || year > currentYear) {
                      return 'Invalid year';
                    }
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _employeeCount,
          decoration: const InputDecoration(labelText: 'Company Size'),
          items: const [
            DropdownMenuItem(value: '1-10', child: Text('1-10 employees')),
            DropdownMenuItem(value: '11-50', child: Text('11-50 employees')),
            DropdownMenuItem(value: '51-200', child: Text('51-200 employees')),
            DropdownMenuItem(
                value: '201-500', child: Text('201-500 employees')),
            DropdownMenuItem(value: '500+', child: Text('500+ employees')),
          ],
          onChanged: (v) => setState(() => _employeeCount = v ?? '1-10'),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Company Description',
            hintText: 'Brief description of your company',
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildContactInformation(ThemeData theme) {
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
                decoration: const InputDecoration(
                  labelText: 'City',
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _stateController,
                decoration: const InputDecoration(
                  labelText: 'State/Province',
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
                  labelText: 'Postal Code',
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _countryController,
                decoration: const InputDecoration(
                  labelText: 'Country',
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
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '+977-XXX-XXXXXXX',
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

  Widget _buildLegalInformation(ThemeData theme) {
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
                  labelText: 'Tax ID / VAT Number',
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

  Widget _buildAdditionalInformation(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Additional Information', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        Card(
          color: theme.colorScheme.surfaceVariant,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 20, color: theme.colorScheme.primary),
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

  Future<void> _pickLogo(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final provider =
            Provider.of<CompanySettingsProvider>(context, listen: false);
        final success = await provider.uploadLogo(File(pickedFile.path));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success
                  ? 'Logo uploaded successfully!'
                  : 'Failed to upload logo: ${provider.error}'),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeLogo() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Logo'),
        content:
            const Text('Are you sure you want to remove the company logo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Update company settings to remove logo
      final provider =
          Provider.of<CompanySettingsProvider>(context, listen: false);
      final currentSettings = provider.settings ?? {};
      currentSettings['logoUrl'] = '';

      final success = await provider.save(currentSettings);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Logo removed!'
                : 'Failed to remove logo: ${provider.error}'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'name': _nameController.text.trim(),
      'legalName': _legalNameController.text.trim(),
      'address': _addressController.text.trim(),
      'city': _cityController.text.trim(),
      'state': _stateController.text.trim(),
      'postalCode': _postalCodeController.text.trim(),
      'country': _countryController.text.trim(),
      'phone': _phoneController.text.trim(),
      'email': _emailController.text.trim(),
      'website': _websiteController.text.trim(),
      'taxId': _taxIdController.text.trim(),
      'registrationNumber': _registrationNumberController.text.trim(),
      'description': _descriptionController.text.trim(),
      'industry': _industryController.text.trim(),
      'establishedYear': _establishedYearController.text.trim().isNotEmpty
          ? int.tryParse(_establishedYearController.text.trim())
          : null,
      'employeeCount': _employeeCount,
      'logoUrl': _logoUrl, // Keep existing logo URL
    };

    final provider =
        Provider.of<CompanySettingsProvider>(context, listen: false);
    final success = await provider.save(data);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Company information saved!'
              : 'Failed to save company information: ${provider.error ?? "Unknown error"}'),
          duration: const Duration(seconds: 5),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

      // Log the error for debugging
      if (!success) {
        print('Company settings save failed: ${provider.error}');
      }
    }
  }
}
