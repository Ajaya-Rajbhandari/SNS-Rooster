import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sns_rooster/providers/company_settings_provider.dart';
import 'package:sns_rooster/providers/auth_provider.dart';
import 'package:sns_rooster/services/company_settings_service.dart';
import 'package:sns_rooster/services/firebase_storage_service.dart';
import 'dart:typed_data';

class CompanyDetailsWidget extends StatefulWidget {
  const CompanyDetailsWidget({Key? key}) : super(key: key);

  @override
  State<CompanyDetailsWidget> createState() => _CompanyDetailsWidgetState();
}

class _CompanyDetailsWidgetState extends State<CompanyDetailsWidget> {
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    // Trigger load after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCompanySettings();
    });
  }

  void _initializeCompanySettings() {
    if (!_hasInitialized) {
      _hasInitialized = true;
      final companySettingsProvider =
          Provider.of<CompanySettingsProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (authProvider.isAuthenticated &&
          companySettingsProvider.settings == null) {
        companySettingsProvider.autoLoad();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CompanySettingsProvider>(
      builder: (context, companySettingsProvider, child) {
        // Trigger initialization if not done yet
        if (!_hasInitialized) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _initializeCompanySettings();
          });
        }

        if (companySettingsProvider.isLoading) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        if (companySettingsProvider.settings == null) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Text('Company information not available'),
              ),
            ),
          );
        }

        final settings = companySettingsProvider.settings!;
        final companyInfo = settings['companyInfo'] ??
            settings; // Handle both nested and flat structure
        final logoUrl =
            CompanySettingsService.getLogoUrl(companyInfo['logoUrl']);

        return Card(
          margin: const EdgeInsets.all(8.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Company Logo
                    if (logoUrl.isNotEmpty)
                      Container(
                        width: 60,
                        height: 60,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _buildLogoWidget(logoUrl),
                        ),
                      )
                    else
                      Container(
                        width: 60,
                        height: 60,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Icon(
                          Icons.business,
                          size: 30,
                          color: Colors.grey.shade400,
                        ),
                      ),

                    // Company Name and Status
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            companyInfo['name'] ?? 'Your Company Name',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Active',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildCompanyDetails(companyInfo),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompanyDetails(Map<String, dynamic> companyInfo) {
    final details = <Widget>[];

    // Add company details if available
    if (companyInfo['address']?.isNotEmpty == true) {
      details.add(_buildDetailRow('Address', companyInfo['address']));
    }

    if (companyInfo['city']?.isNotEmpty == true ||
        companyInfo['state']?.isNotEmpty == true) {
      final location = [
        companyInfo['city'],
        companyInfo['state'],
        companyInfo['postalCode']
      ].where((s) => s?.isNotEmpty == true).join(', ');
      if (location.isNotEmpty) {
        details.add(_buildDetailRow('Location', location));
      }
    }

    if (companyInfo['phone']?.isNotEmpty == true) {
      details.add(_buildDetailRow('Phone', companyInfo['phone']));
    }

    if (companyInfo['email']?.isNotEmpty == true) {
      details.add(_buildDetailRow('Email', companyInfo['email']));
    }

    if (companyInfo['website']?.isNotEmpty == true) {
      details.add(_buildDetailRow('Website', companyInfo['website']));
    }

    if (companyInfo['taxId']?.isNotEmpty == true) {
      details.add(_buildDetailRow('Tax ID', companyInfo['taxId']));
    }

    if (companyInfo['registrationNumber']?.isNotEmpty == true) {
      details.add(
          _buildDetailRow('Registration', companyInfo['registrationNumber']));
    }

    if (details.isEmpty) {
      return const Text(
        'No company details available. Please update company information in settings.',
        style: TextStyle(
          color: Colors.grey,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Company Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...details,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoWidget(String logoUrl) {
    return FutureBuilder<Uint8List?>(
      future: FirebaseStorageService.loadLogoForPlatform(logoUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        if (snapshot.hasError) {
          return Container(
            color: Colors.grey.shade100,
            child: Icon(
              Icons.business,
              size: 30,
              color: Colors.grey.shade400,
            ),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          return Image.memory(
            snapshot.data!,
            fit: BoxFit.contain,
          );
        }
        return Container(
          color: Colors.grey.shade100,
          child: Icon(
            Icons.business,
            size: 30,
            color: Colors.grey.shade400,
          ),
        );
      },
    );
  }
}
