import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'company_info_widget.dart';

class CompanyUsageWidget extends StatelessWidget {
  const CompanyUsageWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.user;
        final companyId = user?['companyId'];

        if (companyId == null) {
          return const SizedBox.shrink();
        }

        return CompanyInfoWidget(companyId: companyId);
      },
    );
  }
}
