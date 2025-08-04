import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/fcm_service.dart';

class RealTimeBreakTimer extends StatefulWidget {
  final DateTime breakStartTime;
  final String breakTypeName;
  final int? maxDurationMinutes; // Break duration limit in minutes
  final int totalBreaksToday;

  const RealTimeBreakTimer({
    super.key,
    required this.breakStartTime,
    required this.breakTypeName,
    this.maxDurationMinutes,
    required this.totalBreaksToday,
  });

  @override
  State<RealTimeBreakTimer> createState() => _RealTimeBreakTimerState();
}

class _RealTimeBreakTimerState extends State<RealTimeBreakTimer> {
  late Timer _timer;
  late DateTime _currentTime;
  late Duration _elapsedTime;
  Duration? _remainingTime;

  @override
  void initState() {
    super.initState();
    _updateTimes();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTimes();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateTimes() {
    setState(() {
      _currentTime = DateTime.now();
      _elapsedTime = _currentTime.difference(widget.breakStartTime);

      if (widget.maxDurationMinutes != null) {
        final maxDuration = Duration(minutes: widget.maxDurationMinutes!);
        _remainingTime = maxDuration - _elapsedTime;
        // If remaining time is negative, set to zero
        if (_remainingTime!.isNegative) {
          _remainingTime = Duration.zero;
        }
      }
    });

    // Update persistent notification every 10 seconds for more responsive updates
    if (_elapsedTime.inSeconds % 10 == 0) {
      _updatePersistentNotification();
    }
  }

  void _updatePersistentNotification() {
    FCMService().updatePersistentBreakNotification(
      breakType: widget.breakTypeName,
      startTime: widget.breakStartTime,
      maxDurationMinutes: widget.maxDurationMinutes,
      totalBreaksToday: widget.totalBreaksToday,
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    }
  }

  String _formatTime(DateTime time) {
    return DateFormat('hh:mm:ss a').format(time);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOvertime = widget.maxDurationMinutes != null &&
        _elapsedTime.inMinutes >= widget.maxDurationMinutes!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isOvertime
            ? Colors.red.withValues(alpha: 0.1)
            : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isOvertime
              ? Colors.red.withValues(alpha: 0.3)
              : Colors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                isOvertime ? Icons.warning : Icons.timer,
                size: 16,
                color: isOvertime ? Colors.red[700] : Colors.orange[700],
              ),
              const SizedBox(width: 6),
              Text(
                isOvertime ? 'Break Overtime!' : 'Break Timer',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isOvertime ? Colors.red[700] : Colors.orange[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Current Time
          _buildTimeRow(
            Icons.access_time,
            'Current Time',
            _formatTime(_currentTime),
            Colors.blue[600]!,
          ),
          const SizedBox(height: 4),

          // Break Start Time
          _buildTimeRow(
            Icons.play_arrow,
            'Started',
            _formatTime(widget.breakStartTime),
            Colors.green[600]!,
          ),
          const SizedBox(height: 4),

          // Break Type
          _buildTimeRow(
            Icons.label,
            'Type',
            widget.breakTypeName,
            Colors.purple[600]!,
          ),
          const SizedBox(height: 4),

          // Elapsed Time
          _buildTimeRow(
            Icons.timer,
            'Elapsed',
            _formatDuration(_elapsedTime),
            isOvertime ? Colors.red[600]! : Colors.orange[600]!,
          ),

          // Progress Bar (if max duration is set)
          if (widget.maxDurationMinutes != null) ...[
            const SizedBox(height: 6),
            _buildProgressBar(),
            const SizedBox(height: 4),
          ],

          // Remaining Time (if applicable)
          if (widget.maxDurationMinutes != null) ...[
            const SizedBox(height: 4),
            _buildTimeRow(
              _remainingTime!.inSeconds > 0
                  ? Icons.hourglass_bottom
                  : Icons.schedule_send,
              'Remaining',
              _remainingTime!.inSeconds > 0
                  ? _formatDuration(_remainingTime!)
                  : 'Overtime: ${_formatDuration(_elapsedTime - Duration(minutes: widget.maxDurationMinutes!))}',
              _remainingTime!.inSeconds > 0
                  ? Colors.green[600]!
                  : Colors.red[600]!,
            ),
          ],

          const SizedBox(height: 4),

          // Breaks Today Count
          _buildTimeRow(
            Icons.numbers,
            'Breaks Today',
            '${widget.totalBreaksToday}',
            Colors.grey[600]!,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        SizedBox(
          width: 80,
          child: Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    if (widget.maxDurationMinutes == null) return const SizedBox.shrink();

    final maxDuration = Duration(minutes: widget.maxDurationMinutes!);
    final progress = _elapsedTime.inSeconds / maxDuration.inSeconds;
    final clampedProgress = progress.clamp(0.0, 1.0);
    final isOvertime = progress > 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            Text(
              '${(clampedProgress * 100).toInt()}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isOvertime ? Colors.red[600] : Colors.green[600],
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: clampedProgress,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            isOvertime ? Colors.red : Colors.green,
          ),
          minHeight: 6,
        ),
      ],
    );
  }
}
