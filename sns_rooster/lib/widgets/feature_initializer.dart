import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/feature_provider.dart';

/// Widget that automatically initializes features when the app starts
class FeatureInitializer extends StatefulWidget {
  final Widget child;

  const FeatureInitializer({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<FeatureInitializer> createState() => _FeatureInitializerState();
}

class _FeatureInitializerState extends State<FeatureInitializer> {
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFeatures();
    });
  }

  void _initializeFeatures() {
    if (!_hasInitialized) {
      _hasInitialized = true;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (authProvider.isAuthenticated &&
          authProvider.featureProvider != null) {
        authProvider.featureProvider!.loadFeatures();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
