class Employee {
  final String id;
  final String userId;
  final String firstName;
  final String lastName;
  final String email;
  final String employeeId;
  final DateTime hireDate;
  final String? position;
  final String? department;

  Employee({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.employeeId,
    required this.hireDate,
    this.position,
    this.department,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['_id'] as String,
      userId: json['userId'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      email: json['email'] as String,
      employeeId: json['employeeId'] as String,
      hireDate: DateTime.parse(json['hireDate'] as String),
      position: json['position'] as String?,
      department: json['department'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'employeeId': employeeId,
      'hireDate': hireDate.toIso8601String(),
      'position': position,
      'department': department,
    };
  }

  String get name => '$firstName $lastName';

  @override
  String toString() {
    return 'Employee(id: $id, firstName: $firstName, lastName: $lastName, email: $email, employeeId: $employeeId, hireDate: $hireDate, position: $position, department: $department)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Employee &&
        other.id == id &&
        other.firstName == firstName &&
        other.lastName == lastName &&
        other.email == email &&
        other.employeeId == employeeId &&
        other.hireDate == hireDate &&
        other.position == position &&
        other.department == department;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        firstName.hashCode ^
        lastName.hashCode ^
        email.hashCode ^
        employeeId.hashCode ^
        hireDate.hashCode ^
        position.hashCode ^
        department.hashCode;
  }

  Employee copyWith({
    String? id,
    String? userId,
    String? firstName,
    String? lastName,
    String? email,
    String? employeeId,
    DateTime? hireDate,
    String? position,
    String? department,
  }) {
    return Employee(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      employeeId: employeeId ?? this.employeeId,
      hireDate: hireDate ?? this.hireDate,
      position: position ?? this.position,
      department: department ?? this.department,
    );
  }
}
