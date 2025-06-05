/// Provider for employee dashboard state (for future use with Provider/Riverpod)
import 'package:flutter/material.dart';
import '../models/employee.dart';

class EmployeeProvider extends ChangeNotifier {
  Employee employee = Employee(
    id: '1',
    name: 'John Doe',
    role: 'Software Engineer',
    avatar: 'assets/images/profile_placeholder.png',
  );

  // Add attendance, leave, and other state here as needed
}
