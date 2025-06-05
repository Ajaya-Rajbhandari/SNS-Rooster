class LeaveRequest {
  final DateTime fromDate;
  final DateTime toDate;
  final String leaveType;
  final String reason;
  final String status;

  LeaveRequest({
    required this.fromDate,
    required this.toDate,
    required this.leaveType,
    required this.reason,
    this.status = 'Pending',
  });

  Map<String, dynamic> toJson() {
    return {
      'fromDate': fromDate.toIso8601String(),
      'toDate': toDate.toIso8601String(),
      'leaveType': leaveType,
      'reason': reason,
      'status': status,
    };
  }

  static LeaveRequest fromJson(Map<String, dynamic> json) {
    return LeaveRequest(
      fromDate: DateTime.parse(json['fromDate']),
      toDate: DateTime.parse(json['toDate']),
      leaveType: json['leaveType'],
      reason: json['reason'],
      status: json['status'],
    );
  }
}
