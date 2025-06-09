enum LeaveType {
  annual,
  sick,
  casual,
  maternity,
  paternity,
  unpaid,
}

enum LeaveRequestStatus {
  pending,
  approved,
  rejected,
}

class LeaveRequest {
  final String id;
  final String employeeId;
  final String employeeName;
  final LeaveType leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final int duration;
  final String reason;
  final LeaveRequestStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  LeaveRequest({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.duration,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    return LeaveRequest(
      id: json['id'],
      employeeId: json['employeeId'],
      employeeName: json['employeeName'],
      leaveType: LeaveType.values.firstWhere(
        (e) => e.toString() == 'LeaveType.${json['leaveType']}',
        orElse: () => LeaveType.casual,
      ),
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      duration: json['duration'],
      reason: json['reason'],
      status: LeaveRequestStatus.values.firstWhere(
        (e) => e.toString() == 'LeaveRequestStatus.${json['status']}',
        orElse: () => LeaveRequestStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'leaveType': leaveType.toString().split('.').last,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'duration': duration,
      'reason': reason,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  LeaveRequest copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    LeaveType? leaveType,
    DateTime? startDate,
    DateTime? endDate,
    int? duration,
    String? reason,
    LeaveRequestStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LeaveRequest(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      leaveType: leaveType ?? this.leaveType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      duration: duration ?? this.duration,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
