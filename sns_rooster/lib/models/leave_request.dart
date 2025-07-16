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
  final String department;
  final String role; // 'employee' or 'admin'
  final String? user; // User ID for admin leaves
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
    required this.department,
    required this.role,
    this.user,
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
    final startDate = DateTime.parse(json['startDate']);
    final endDate = DateTime.parse(json['endDate']);
    final duration = endDate.difference(startDate).inDays + 1;

    String leaveTypeStr =
        (json['leaveType'] as String).toLowerCase().replaceAll(' ', '');
    LeaveType leaveType = LeaveType.values.firstWhere(
      (e) => e.toString().toLowerCase().endsWith(leaveTypeStr),
      orElse: () => LeaveType.casual,
    );

    return LeaveRequest(
      id: json['_id'] ?? '',
      employeeId: json['employee'] ?? '',
      employeeName: json['employeeName'] ?? '',
      department: json['department'] ?? '',
      role: json['role'] ?? 'employee',
      user: json['user'],
      leaveType: leaveType,
      startDate: startDate,
      endDate: endDate,
      duration: duration,
      reason: json['reason'] ?? '',
      status: LeaveRequestStatus.values.firstWhere(
        (e) => e
            .toString()
            .toLowerCase()
            .endsWith((json['status'] as String).toLowerCase()),
        orElse: () => LeaveRequestStatus.pending,
      ),
      createdAt: DateTime.parse(json['appliedAt']),
      updatedAt: null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'department': department,
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
    String? department,
    String? role,
    String? user,
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
      department: department ?? this.department,
      role: role ?? this.role,
      user: user ?? this.user,
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
