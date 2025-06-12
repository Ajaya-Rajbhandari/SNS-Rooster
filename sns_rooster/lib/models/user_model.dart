class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? role; // Role can be nullable or have a default

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'], // Accommodate different ID field names
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      role: json['role'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'role': role,
    };
  }

  // Helper to display full name or email if names are not available
  String get displayName {
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '$firstName $lastName';
    }
    return email;
  }
}