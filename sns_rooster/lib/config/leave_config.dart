class LeaveConfig {
  static Map<String, int> totalLeaveDays = {
    'Annual': 30,
    'Sick': 10,
    'Casual': 5,
  };

  static Map<String, int> usedLeaveDays = {'Annual': 6, 'Sick': 5, 'Casual': 1};

  static List<String> get leaveTypes => [
        'Annual Leave',
        'Sick Leave',
        'Casual Leave',
        'Maternity Leave',
        'Paternity Leave'
      ];
}
