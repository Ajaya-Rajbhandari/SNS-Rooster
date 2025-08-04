import 'package:flutter/material.dart';

class PerformanceReview {
  final String id;
  final String employeeId;
  final String employeeName;
  final String reviewerId;
  final String reviewerName;
  final String reviewPeriod;
  final DateTime startDate;
  final DateTime endDate;
  final String status; // 'draft', 'in_progress', 'completed', 'overdue'
  final Map<String, dynamic> scores; // Category scores
  final String? comments;
  final String? employeeComments;
  final List<String> goals;
  final List<String> achievements;
  final List<String> areasOfImprovement;
  final double? overallRating;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime dueDate;

  PerformanceReview({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.reviewerId,
    required this.reviewerName,
    required this.reviewPeriod,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.scores,
    this.comments,
    this.employeeComments,
    required this.goals,
    required this.achievements,
    required this.areasOfImprovement,
    this.overallRating,
    required this.createdAt,
    this.completedAt,
    required this.dueDate,
  });

  factory PerformanceReview.fromJson(Map<String, dynamic> json) {
    // Handle populated employeeId (could be object or string)
    String employeeId;
    String employeeName;
    if (json['employeeId'] is Map<String, dynamic>) {
      employeeId = json['employeeId']['_id'] ?? '';
      // Extract employee name from populated object if available
      final firstName = json['employeeId']['firstName'] ?? '';
      final lastName = json['employeeId']['lastName'] ?? '';
      employeeName = '$firstName $lastName'.trim();
    } else {
      employeeId = json['employeeId'] ?? '';
      employeeName = json['employeeName'] ?? '';
    }

    // Handle populated reviewerId (could be object or string)
    String reviewerId;
    String reviewerName;
    if (json['reviewerId'] is Map<String, dynamic>) {
      reviewerId = json['reviewerId']['_id'] ?? '';
      // Extract reviewer name from populated object if available
      final firstName = json['reviewerId']['firstName'] ?? '';
      final lastName = json['reviewerId']['lastName'] ?? '';
      reviewerName = '$firstName $lastName'.trim();
    } else {
      reviewerId = json['reviewerId'] ?? '';
      reviewerName = json['reviewerName'] ?? '';
    }

    final status = json['status'] ?? 'draft';

    return PerformanceReview(
      id: json['_id'] ?? json['id'] ?? '',
      employeeId: employeeId,
      employeeName: employeeName,
      reviewerId: reviewerId,
      reviewerName: reviewerName,
      reviewPeriod: json['reviewPeriod'] ?? '',
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      status: status,
      scores: Map<String, dynamic>.from(json['scores'] ?? {}),
      comments: json['comments'],
      employeeComments: json['employeeComments'],
      goals: List<String>.from(json['goals'] ?? []),
      achievements: List<String>.from(json['achievements'] ?? []),
      areasOfImprovement: List<String>.from(json['areasOfImprovement'] ?? []),
      overallRating: json['overallRating']?.toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      dueDate: DateTime.parse(json['dueDate']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'reviewerId': reviewerId,
      'reviewerName': reviewerName,
      'reviewPeriod': reviewPeriod,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'status': status,
      'scores': scores,
      'comments': comments,
      'employeeComments': employeeComments,
      'goals': goals,
      'achievements': achievements,
      'areasOfImprovement': areasOfImprovement,
      'overallRating': overallRating,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
    };
  }

  String get statusDisplayName {
    switch (status) {
      case 'draft':
        return 'Draft';
      case 'in_progress':
        return 'In Progress';
      case 'submitted_for_employee_review':
        return 'Pending Employee Review';
      case 'employee_review_complete':
        return 'Employee Review Complete';
      case 'completed':
        return 'Completed';
      case 'overdue':
        return 'Overdue';
      default:
        return 'Unknown';
    }
  }

  Color get statusColor {
    switch (status) {
      case 'draft':
        return Colors.grey;
      case 'in_progress':
        return Colors.orange;
      case 'submitted_for_employee_review':
        return Colors.orange;
      case 'employee_review_complete':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'overdue':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
