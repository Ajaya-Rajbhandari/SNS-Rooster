class LeaveRequest {
  final String id;
  final String employeeName;
  final String leaveType;
  final String startDate;
  final String endDate;
  String reason;
  String status;

  LeaveRequest({
    required this.id,
    required this.employeeName,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.reason,
    this.status = 'Pending',
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    return LeaveRequest(
      id: json['_id'] as String,
      employeeName: json['employeeName'] as String,
      leaveType: json['leaveType'] as String,
      startDate: json['startDate'] as String,
      endDate: json['endDate'] as String,
      reason: json['reason'] as String,
      status: json['status'] as String? ?? 'Pending',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'employeeName': employeeName,
        'leaveType': leaveType,
        'startDate': startDate,
        'endDate': endDate,
        'reason': reason,
        'status': status,
      };
}
