/// AttendanceService: Handles attendance logic and (future) API integration
class AttendanceService {
  // Simulate clock in/out and break logic for now
  bool isClockedIn = false;
  bool isOnBreak = false;
  DateTime? lastClockIn;

  void clockIn() {
    isClockedIn = true;
    lastClockIn = DateTime.now();
    isOnBreak = false;
  }

  void clockOut() {
    isClockedIn = false;
    isOnBreak = false;
  }

  void startBreak() {
    if (isClockedIn) isOnBreak = true;
  }

  void endBreak() {
    if (isClockedIn) isOnBreak = false;
  }

  static Future<List<Map<String, String>>> getAttendance() async {
    // Mock data for demonstration purposes
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    return [
      {'date': '2025-06-01', 'status': 'Present'},
      {'date': '2025-06-02', 'status': 'Absent'},
      {'date': '2025-06-03', 'status': 'Present'},
      {'date': '2025-06-04', 'status': 'Leave'},
      {'date': '2025-06-05', 'status': 'Present'},
      {'date': '2025-06-06', 'status': 'Leave'},
      {'date': '2025-06-07', 'status': 'Present'},
      {'date': '2025-06-08', 'status': 'Absent'},
    ];
  }

  // For future: integrate with backend API
}
