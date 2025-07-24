class Company {
  final String id;
  final String name;
  final String domain;
  final String subdomain;
  final String adminEmail;
  final String? contactPhone;
  final String? address;
  final String subscriptionPlan;
  final Map<String, dynamic> features;
  final Map<String, dynamic> limits;
  final Map<String, dynamic> usage;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Company({
    required this.id,
    required this.name,
    required this.domain,
    required this.subdomain,
    required this.adminEmail,
    this.contactPhone,
    this.address,
    required this.subscriptionPlan,
    required this.features,
    required this.limits,
    required this.usage,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['_id'] ?? json['id'],
      name: json['name'] ?? '',
      domain: json['domain'] ?? '',
      subdomain: json['subdomain'] ?? '',
      adminEmail: json['adminEmail'] ?? '',
      contactPhone: json['contactPhone'],
      address: json['address'],
      subscriptionPlan: json['subscriptionPlan'] ?? 'basic',
      features: json['features'] ?? {},
      limits: json['limits'] ?? {},
      usage: json['usage'] ?? {},
      status: json['status'] ?? 'active',
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt:
          DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'domain': domain,
      'subdomain': subdomain,
      'adminEmail': adminEmail,
      'contactPhone': contactPhone,
      'address': address,
      'subscriptionPlan': subscriptionPlan,
      'features': features,
      'limits': limits,
      'usage': usage,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Helper methods for feature flags
  bool hasFeature(String feature) {
    return features[feature] == true;
  }

  bool isFeatureEnabled(String feature) {
    return hasFeature(feature);
  }

  // Helper methods for usage limits
  int getLimit(String limitKey) {
    return limits[limitKey] ?? 0;
  }

  int getUsage(String usageKey) {
    return usage[usageKey] ?? 0;
  }

  bool isWithinLimit(String limitKey) {
    final limit = getLimit(limitKey);
    final currentUsage = getUsage(limitKey);
    return limit == 0 || currentUsage < limit; // 0 means unlimited
  }

  // Helper methods for subscription plans
  bool isBasicPlan() => subscriptionPlan == 'basic';
  bool isProPlan() => subscriptionPlan == 'pro';
  bool isEnterprisePlan() => subscriptionPlan == 'enterprise';

  // Helper method to check if company is active
  bool get isActive => status == 'active';

  @override
  String toString() {
    return 'Company(id: $id, name: $name, domain: $domain, subdomain: $subdomain, subscriptionPlan: $subscriptionPlan, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Company && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
