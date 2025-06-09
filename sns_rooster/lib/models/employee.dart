/// Employee model for dashboard and profile data
class Employee {
  final String id;
  final String name;
  final String role;
  final String avatar;

  Employee({
    required this.id,
    required this.name,
    required this.role,
    required this.avatar,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['_id'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      avatar: json['avatar'] as String,
    );
  }
}
