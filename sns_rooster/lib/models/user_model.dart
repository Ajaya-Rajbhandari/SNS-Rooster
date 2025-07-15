class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? role;
  final String? avatar;
  final String? department;
  final String? position;
  final String? phone;
  final String? address;
  final bool? isActive;
  final bool? isProfileComplete;
  final String? lastLogin;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.role,
    this.avatar,
    this.department,
    this.position,
    this.phone,
    this.address,
    this.isActive,
    this.isProfileComplete,
    this.lastLogin,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'],
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      role: json['role'],
      avatar: json['avatar'],
      department: json['department'],
      position: json['position'],
      phone: json['phone'],
      address: json['address'],
      isActive: json['isActive'],
      isProfileComplete: json['isProfileComplete'],
      lastLogin: json['lastLogin'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'role': role,
      'avatar': avatar,
      'department': department,
      'position': position,
      'phone': phone,
      'address': address,
      'isActive': isActive,
      'isProfileComplete': isProfileComplete,
      'lastLogin': lastLogin,
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
