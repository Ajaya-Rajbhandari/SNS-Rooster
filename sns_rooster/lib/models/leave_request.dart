class LeaveRequest {
  final String id;
  final String employeeName;
  final DateTime startDate;
  final DateTime endDate;
  final String leaveType;
  final String reason;
  String status;

  LeaveRequest({
    required this.id,
    required this.employeeName,
    required this.startDate,
    required this.endDate,
    required this.leaveType,
    required this.reason,
    this.status = 'Pending',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeName': employeeName,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'leaveType': leaveType,
      'reason': reason,
      'status': status,
    };
  }

  static LeaveRequest fromJson(Map<String, dynamic> json) {
    return LeaveRequest(
      id: json['id'],
      employeeName: json['employeeName'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      leaveType: json['leaveType'],
      reason: json['reason'],
      status: json['status'],
    );
  }
}
