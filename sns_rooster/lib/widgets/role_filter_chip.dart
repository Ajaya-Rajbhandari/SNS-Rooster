import 'package:flutter/material.dart';

class RoleFilterChip extends StatelessWidget {
  final String? selectedRole;
  final Function(String?) onRoleChanged;
  final bool showAllOption;

  const RoleFilterChip({
    super.key,
    this.selectedRole,
    required this.onRoleChanged,
    this.showAllOption = true,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.0,
      children: [
        if (showAllOption)
          FilterChip(
            label: const Text('All Users'),
            selected: selectedRole == null,
            onSelected: (_) => onRoleChanged(null),
          ),
        FilterChip(
          label: const Text('Employees Only'),
          selected: selectedRole == 'employee',
          onSelected: (_) => onRoleChanged('employee'),
        ),
        FilterChip(
          label: const Text('Admins Only'),
          selected: selectedRole == 'admin',
          onSelected: (_) => onRoleChanged('admin'),
        ),
      ],
    );
  }
}
