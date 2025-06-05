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

  // For future: integrate with backend API
}
