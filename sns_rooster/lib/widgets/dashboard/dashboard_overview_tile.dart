import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/attendance_provider.dart';
import 'dart:ui';

class DashboardOverviewTile extends StatelessWidget {
  final void Function(String label)? onStatTileTap;
  const DashboardOverviewTile({super.key, this.onStatTileTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final attendanceProvider = Provider.of<AttendanceProvider>(context);
    final attendanceHistory = attendanceProvider.attendanceRecords;

    // Filter attendance history for the last 7 days
    final DateTime now = DateTime.now();
    final DateTime sevenDaysAgo = now.subtract(const Duration(days: 7));
    final List<Map<String, dynamic>> recentAttendance = attendanceHistory
        .where((record) {
          final checkInDate = DateTime.parse(record['checkIn']);
          return checkInDate.isAfter(sevenDaysAgo) &&
              checkInDate.isBefore(now.add(const Duration(days: 1)));
        })
        .toList()
        .reversed
        .toList(); // Show most recent first

    // Calculate weekly total hours and daily averages
    Duration totalWeeklyWorkDuration = Duration.zero;
    Map<String, Duration> dailyWorkDurations = {};

    for (var record in recentAttendance) {
      if (record['checkIn'] != null && record['checkOut'] != null) {
        final checkIn = DateTime.parse(record['checkIn']);
        final checkOut = DateTime.parse(record['checkOut']);
        final workDuration = checkOut.difference(checkIn);

        final totalBreakDurationMs = record['totalBreakDuration'] ?? 0;
        final actualWorkDuration =
            workDuration - Duration(milliseconds: totalBreakDurationMs);

        totalWeeklyWorkDuration += actualWorkDuration;

        final dateKey = DateFormat('yyyy-MM-dd').format(checkIn);
        dailyWorkDurations.update(
          dateKey,
          (value) => value + actualWorkDuration,
          ifAbsent: () => actualWorkDuration,
        );
      }
    }

    final double avgDailyWorkHours = recentAttendance.isNotEmpty
        ? totalWeeklyWorkDuration.inMinutes / recentAttendance.length / 60
        : 0.0;

    // Calculate break statistics for today
    final todayAttendance = attendanceProvider.currentAttendance;
    int totalBreaksToday = 0;
    Duration totalBreakDurationToday = Duration.zero;
    if (todayAttendance != null && todayAttendance['breaks'] != null) {
      totalBreaksToday = todayAttendance['breaks'].length;
      for (var b in todayAttendance['breaks']) {
        if (b['startTime'] != null && b['endTime'] != null) {
          totalBreakDurationToday += DateTime.parse(b['endTime'])
              .difference(DateTime.parse(b['startTime']));
        }
      }
    }

    // Quick Stats (mock for now, calculations can be added later based on logic)
    final int attendanceStreak = _calculateAttendanceStreak(attendanceHistory);
    final String punctualityScore =
        _calculatePunctualityScore(attendanceHistory);

    return Card(
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300, width: 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Attendance & Work Overview",
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Weekly Attendance Overview
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.symmetric(
                  vertical: 8.0), // Add vertical margin
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Weekly Attendance",
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 7,
                        itemBuilder: (context, index) {
                          final day = now.subtract(Duration(days: 6 - index));
                          final recordForDay = recentAttendance.firstWhere(
                            (record) =>
                                DateFormat('yyyy-MM-dd').format(
                                    DateTime.parse(record['checkIn'])) ==
                                DateFormat('yyyy-MM-dd').format(day),
                            orElse: () => {},
                          );

                          bool isPresent = recordForDay.isNotEmpty &&
                              recordForDay['checkIn'] != null;
                          bool isOnLeave = recordForDay.isNotEmpty &&
                              recordForDay['status'] == 'Leave';
                          bool isAbsent = recordForDay.isEmpty ||
                              recordForDay['status'] == 'Absent';

                          Color dayBackgroundColor = theme.colorScheme.surface;
                          String statusText = 'N/A';
                          Color statusColor =
                              Colors.grey.shade700; // Default status text color

                          if (isPresent) {
                            dayBackgroundColor = theme.colorScheme.primary
                                .withOpacity(0.15); // Use subtle primary
                            statusText = 'Present';
                            statusColor =
                                theme.colorScheme.primary; // Keep text vibrant
                          } else if (isOnLeave) {
                            dayBackgroundColor = theme.colorScheme.tertiary
                                .withOpacity(0.15); // Use subtle tertiary
                            statusText = 'Leave';
                            statusColor =
                                theme.colorScheme.tertiary; // Keep text vibrant
                          } else if (isAbsent) {
                            dayBackgroundColor = Colors
                                .red.shade100; // Use a very light red directly
                            statusText = 'Absent';
                            statusColor = Colors.red
                                .shade700; // Use a darker red for text for contrast
                          }

                          String checkInTime = 'N/A';
                          String checkOutTime = 'N/A';
                          Duration workHours = Duration.zero;

                          if (recordForDay.isNotEmpty &&
                              recordForDay['checkIn'] != null) {
                            final ci = DateTime.parse(recordForDay['checkIn']);
                            checkInTime = DateFormat('hh:mm a').format(ci);
                            if (recordForDay['checkOut'] != null) {
                              final co =
                                  DateTime.parse(recordForDay['checkOut']);
                              checkOutTime = DateFormat('hh:mm a').format(co);
                              final totalBreakMs =
                                  recordForDay['totalBreakDuration'] ?? 0;
                              workHours = co.difference(ci) -
                                  Duration(milliseconds: totalBreakMs);
                            }
                          }

                          Widget glassCard = ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: 120,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 6.0),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isPresent
                                      ? theme.colorScheme.primary
                                      : isOnLeave
                                          ? theme.colorScheme.tertiary
                                          : Colors.red.shade400,
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    DateFormat('EEE').format(day),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: isPresent
                                            ? theme.colorScheme.primary
                                            : isOnLeave
                                                ? theme.colorScheme.tertiary
                                                : Colors.red.shade700),
                                  ),
                                  Text(
                                    DateFormat('MMM d').format(day),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                        color: isPresent
                                            ? theme.colorScheme.primary
                                            : isOnLeave
                                                ? theme.colorScheme.tertiary
                                                : Colors.red.shade700),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    statusText,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: isPresent
                                          ? theme.colorScheme.primary
                                          : isOnLeave
                                              ? theme.colorScheme.tertiary
                                              : Colors.red.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (isPresent && workHours.inMinutes > 0)
                                    Text(
                                      '${workHours.inHours}h ${workHours.inMinutes.remainder(60)}m',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                              color: theme.colorScheme.primary),
                                    ),
                                  if (isPresent &&
                                      workHours.inMinutes <= 0 &&
                                      recordForDay['checkIn'] != null)
                                    Text(
                                      'Check-in: $checkInTime',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                              color: theme.colorScheme.primary),
                                    ),
                                ],
                              ),
                            ),
                          );
                          return glassCard;
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Break Statistics
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.symmetric(
                  vertical: 8.0), // Add vertical margin
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Break Statistics (Today)",
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          child: _buildStatColumn(
                            context,
                            Icons.free_breakfast,
                            theme.colorScheme.tertiary, // Use theme color
                            'Total Breaks',
                            totalBreaksToday.toString(),
                          ),
                        ),
                        Expanded(
                          child: _buildStatColumn(
                            context,
                            Icons.timer_off,
                            theme.colorScheme.secondary, // Use theme color
                            'Total Break Time',
                            _formatDuration(totalBreakDurationToday),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Work Hours Summary
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.symmetric(
                  vertical: 8.0), // Add vertical margin
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Work Hours Summary (Past 7 Days)",
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          child: _buildStatColumn(
                            context,
                            Icons.watch_later_outlined,
                            theme.colorScheme.primary, // Use theme color
                            'Total Work Hours',
                            _formatDuration(totalWeeklyWorkDuration),
                          ),
                        ),
                        Expanded(
                          child: _buildStatColumn(
                            context,
                            Icons.trending_up,
                            theme.colorScheme.primary, // Use theme color
                            'Avg. Daily Hours',
                            avgDailyWorkHours == 0.0
                                ? 'N/A'
                                : '${avgDailyWorkHours.toStringAsFixed(1)}h',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Quick Stats
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.symmetric(
                  vertical: 8.0), // Add vertical margin
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Quick Stats",
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          child: _buildStatColumn(
                            context,
                            Icons.star,
                            theme.colorScheme.secondary, // Use theme color
                            'Attendance Streak',
                            attendanceStreak == 0
                                ? 'N/A'
                                : '$attendanceStreak days',
                          ),
                        ),
                        Expanded(
                          child: _buildStatColumn(
                            context,
                            Icons.speed,
                            theme.colorScheme.primary, // Use theme color
                            'Punctuality',
                            punctualityScore,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(BuildContext context, IconData icon, Color color,
      String label, String value) {
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: () => onStatTileTap?.call(label),
        child: AnimatedScale(
          scale: 1.0,
          duration: const Duration(milliseconds: 200),
          child: Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 24, color: color),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    value,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 20,
                    ),
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    return '$h h $m m';
  }

  int _calculateAttendanceStreak(List<Map<String, dynamic>> attendanceHistory) {
    if (attendanceHistory.isEmpty) return 0;

    int streak = 0;
    DateTime? lastPresentDay;

    // Sort history by date descending to easily calculate streak
    final sortedHistory = List<Map<String, dynamic>>.from(attendanceHistory)
      ..sort((a, b) {
        final dateA = DateTime.parse(a['checkIn']);
        final dateB = DateTime.parse(b['checkIn']);
        return dateB.compareTo(dateA);
      });

    for (var record in sortedHistory) {
      if (record['checkIn'] != null && record['checkOut'] != null) {
        final checkInDay = DateTime.parse(record['checkIn']);
        final normalizedCheckInDay =
            DateTime(checkInDay.year, checkInDay.month, checkInDay.day);

        if (lastPresentDay == null ||
            normalizedCheckInDay
                .add(const Duration(days: 1))
                .isAtSameMomentAs(lastPresentDay)) {
          streak++;
          lastPresentDay = normalizedCheckInDay;
        } else if (normalizedCheckInDay.isAtSameMomentAs(lastPresentDay)) {
          // Same day, continue
        } else {
          // Gap in attendance
          break;
        }
      } else {
        // If there's an unchecked-out record, it might still count towards a streak if it's today
        final checkInDay = DateTime.parse(record['checkIn']);
        final normalizedCheckInDay =
            DateTime(checkInDay.year, checkInDay.month, checkInDay.day);
        final today = DateTime(
            DateTime.now().year, DateTime.now().month, DateTime.now().day);

        if (normalizedCheckInDay.isAtSameMomentAs(today) &&
            record['checkOut'] == null) {
          if (lastPresentDay == null ||
              normalizedCheckInDay
                  .add(const Duration(days: 1))
                  .isAtSameMomentAs(lastPresentDay)) {
            streak++;
            lastPresentDay = normalizedCheckInDay;
          }
        } else {
          break;
        }
      }
    }
    return streak;
  }

  String _calculatePunctualityScore(
      List<Map<String, dynamic>> attendanceHistory) {
    if (attendanceHistory.isEmpty) return 'N/A';

    int punctualDays = 0;
    int totalDays = 0;
    const int targetCheckInHour = 9; // Example: target check-in at 9 AM

    for (var record in attendanceHistory) {
      if (record['checkIn'] != null) {
        final checkInTime = DateTime.parse(record['checkIn']);
        if (checkInTime.hour < targetCheckInHour ||
            (checkInTime.hour == targetCheckInHour &&
                checkInTime.minute == 0)) {
          punctualDays++;
        }
        totalDays++;
      }
    }

    if (totalDays == 0) return 'N/A';
    final score = (punctualDays / totalDays) * 100;
    return '${score.toStringAsFixed(0)}%';
  }
}
