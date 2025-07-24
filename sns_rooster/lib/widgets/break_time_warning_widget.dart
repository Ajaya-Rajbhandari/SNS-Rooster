import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/auth_provider.dart';
import '../services/attendance_service.dart';
import '../config/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BreakTimeWarningWidget extends StatefulWidget {
  const BreakTimeWarningWidget({super.key});

  @override
  State<BreakTimeWarningWidget> createState() => _BreakTimeWarningWidgetState();
}

class _BreakTimeWarningWidgetState extends State<BreakTimeWarningWidget> {
  bool _isOnBreak = false;
  String? _breakType;
  int? _currentDuration;
  int? _maxDuration;
  int? _remainingMinutes;
  bool _isExceeded = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _checkBreakStatus();
    // Check break status every 30 seconds
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkBreakStatus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkBreakStatus() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?['_id'];
      if (userId == null) return;

      final attendanceService = AttendanceService(authProvider);
      final attendanceData =
          await attendanceService.getAttendanceStatusWithData(userId);

      if (attendanceData['attendance'] != null) {
        final attendance = attendanceData['attendance'];
        final breaks = attendance['breaks'] as List<dynamic>? ?? [];

        if (breaks.isNotEmpty) {
          final lastBreak = breaks.last;
          if (lastBreak['end'] == null) {
            // User is on break
            final breakStart = DateTime.parse(lastBreak['start']);
            final now = DateTime.now();
            final currentDuration = now.difference(breakStart).inMinutes;

            // Get break type info
            final breakTypeId = lastBreak['type'];
            if (breakTypeId != null) {
              final breakTypeInfo = await _getBreakTypeInfo(breakTypeId);
              if (breakTypeInfo != null) {
                final maxDuration = breakTypeInfo['maxDuration'] as int? ?? 60;
                final warningThreshold = (maxDuration * 0.8).round();
                final remainingMinutes = maxDuration - currentDuration;
                final isExceeded = currentDuration >= maxDuration;

                setState(() {
                  _isOnBreak = true;
                  _breakType = breakTypeInfo['displayName'];
                  _currentDuration = currentDuration;
                  _maxDuration = maxDuration;
                  _remainingMinutes = remainingMinutes;
                  _isExceeded = isExceeded;
                });

                return;
              }
            }
          }
        }
      }

      setState(() {
        _isOnBreak = false;
        _breakType = null;
        _currentDuration = null;
        _maxDuration = null;
        _remainingMinutes = null;
        _isExceeded = false;
      });
    } catch (e) {
      // Silently handle errors
    }
  }

  Future<Map<String, dynamic>?> _getBreakTypeInfo(String breakTypeId) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/admin/break-types'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final breakTypes = data['breakTypes'] as List;
        return breakTypes.firstWhere(
          (type) => type['_id'] == breakTypeId,
          orElse: () => null,
        );
      }
    } catch (e) {
      // Silently handle errors
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isOnBreak) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine warning level and colors
    Color backgroundColor;
    Color textColor;
    IconData icon;
    String message;

    if (_isExceeded) {
      // Exceeded limit
      backgroundColor = Colors.red.shade100;
      textColor = Colors.red.shade800;
      icon = Icons.warning;
      message =
          'Break time exceeded! You are ${_currentDuration! - _maxDuration!} minutes over the limit.';
    } else if (_remainingMinutes! <= 5) {
      // Critical warning (5 minutes or less remaining)
      backgroundColor = Colors.orange.shade100;
      textColor = Colors.orange.shade800;
      icon = Icons.timer;
      message = 'Break ending soon! Only $_remainingMinutes minutes remaining.';
    } else if (_remainingMinutes! <= 10) {
      // Warning (10 minutes or less remaining)
      backgroundColor = Colors.yellow.shade100;
      textColor = Colors.yellow.shade800;
      icon = Icons.access_time;
      message = 'Break time warning: $_remainingMinutes minutes remaining.';
    } else {
      // Normal break time
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_breakType Break',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                  ),
                ),
                if (_currentDuration != null && _maxDuration != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: LinearProgressIndicator(
                      value: _currentDuration! / _maxDuration!,
                      backgroundColor: textColor.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(textColor),
                    ),
                  ),
              ],
            ),
          ),
          if (_isExceeded)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'EXCEEDED',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
