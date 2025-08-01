class LeaveConfig {
  // Standard leave types with consistent naming
  static const List<String> leaveTypes = [
    'Annual Leave',
    'Sick Leave',
    'Casual Leave',
    'Maternity Leave',
    'Paternity Leave',
    'Unpaid Leave',
  ];

  // Leave type colors for UI consistency
  static const Map<String, int> leaveTypeColors = {
    'Annual Leave': 0xFF2196F3, // Blue
    'Sick Leave': 0xFFF44336, // Red
    'Casual Leave': 0xFFFF9800, // Orange
    'Maternity Leave': 0xFFE91E63, // Pink
    'Paternity Leave': 0xFF9C27B0, // Purple
    'Unpaid Leave': 0xFF9E9E9E, // Grey
  };

  // Default leave entitlements (fallback values)
  static const Map<String, int> defaultLeaveEntitlements = {
    'Annual Leave': 12,
    'Sick Leave': 10,
    'Casual Leave': 5,
    'Maternity Leave': 90,
    'Paternity Leave': 10,
    'Unpaid Leave': 0,
  };

  // Leave type descriptions
  static const Map<String, String> leaveTypeDescriptions = {
    'Annual Leave': 'Regular vacation leave for personal time off',
    'Sick Leave': 'Leave for medical appointments and illness',
    'Casual Leave': 'Short-term leave for personal matters',
    'Maternity Leave': 'Leave for expecting mothers',
    'Paternity Leave': 'Leave for new fathers',
    'Unpaid Leave': 'Leave without pay for special circumstances',
  };

  // Get color for leave type
  static int getLeaveTypeColor(String leaveType) {
    return leaveTypeColors[leaveType] ?? 0xFF9E9E9E; // Default grey
  }

  // Get default entitlement for leave type
  static int getDefaultEntitlement(String leaveType) {
    return defaultLeaveEntitlements[leaveType] ?? 0;
  }

  // Get description for leave type
  static String getLeaveTypeDescription(String leaveType) {
    return leaveTypeDescriptions[leaveType] ?? 'Leave for personal time off';
  }

  // Check if leave type is valid
  static bool isValidLeaveType(String leaveType) {
    return leaveTypes.contains(leaveType);
  }
}
