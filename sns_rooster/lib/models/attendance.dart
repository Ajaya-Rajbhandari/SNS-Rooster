import 'package:flutter/material.dart';

enum AttendanceStatus { present, absent, leave, late, halfDay }

class Attendance {
  final DateTime date;
  final AttendanceStatus status;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final Duration? breakDuration;
  final String? notes;

  Attendance({
    required this.date,
    required this.status,
    this.checkInTime,
    this.checkOutTime,
    this.breakDuration,
    this.notes,
  });

  Duration get totalWorkDuration {
    if (checkInTime == null || checkOutTime == null) return Duration.zero;
    final total = checkOutTime!.difference(checkInTime!);
    return breakDuration != null ? total - breakDuration! : total;
  }

  String get formattedDate =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String get formattedCheckIn =>
      checkInTime?.toString().split(' ')[1].substring(0, 5) ?? 'N/A';
  String get formattedCheckOut =>
      checkOutTime?.toString().split(' ')[1].substring(0, 5) ?? 'N/A';

  String get formattedBreakDuration {
    if (breakDuration == null) return 'N/A';
    final hours = breakDuration!.inHours;
    final minutes = breakDuration!.inMinutes % 60;
    return '$hours h ${minutes > 0 ? '$minutes m' : ''}';
  }

  String get formattedWorkDuration {
    final duration = totalWorkDuration;
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '$hours h ${minutes > 0 ? '$minutes m' : ''}';
  }

  Color get statusColor {
    switch (status) {
      case AttendanceStatus.present:
        return Colors.green;
      case AttendanceStatus.absent:
        return Colors.red;
      case AttendanceStatus.leave:
        return Colors.orange;
      case AttendanceStatus.late:
        return Colors.amber;
      case AttendanceStatus.halfDay:
        return Colors.blue;
    }
  }

  IconData get statusIcon {
    switch (status) {
      case AttendanceStatus.present:
        return Icons.check_circle_outline;
      case AttendanceStatus.absent:
        return Icons.cancel_outlined;
      case AttendanceStatus.leave:
        return Icons.beach_access;
      case AttendanceStatus.late:
        return Icons.access_time;
      case AttendanceStatus.halfDay:
        return Icons.hourglass_empty;
    }
  }

  String get statusText {
    switch (status) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.leave:
        return 'Leave';
      case AttendanceStatus.late:
        return 'Late';
      case AttendanceStatus.halfDay:
        return 'Half Day';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'date': formattedDate,
      'status': status.toString().split('.').last,
      'checkInTime': checkInTime?.toIso8601String(),
      'checkOutTime': checkOutTime?.toIso8601String(),
      'breakDuration': breakDuration?.inMinutes,
      'notes': notes,
    };
  }

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      date: DateTime.parse(json['date']),
      status: AttendanceStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
      ),
      checkInTime: json['checkInTime'] != null
          ? DateTime.parse(json['checkInTime'])
          : null,
      checkOutTime: json['checkOutTime'] != null
          ? DateTime.parse(json['checkOutTime'])
          : null,
      breakDuration: json['breakDuration'] != null
          ? Duration(minutes: json['breakDuration'])
          : null,
      notes: json['notes'],
    );
  }
}
