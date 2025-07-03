import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:io';
import '../../providers/auth_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../services/attendance_service.dart';
import '../../config/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminAttendanceScreen extends StatefulWidget {
  const AdminAttendanceScreen({Key? key}) : super(key: key);

  @override
  State<AdminAttendanceScreen> createState() => _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends State<AdminAttendanceScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  String _currentStatus = 'Not Clocked In';
  DateTime? _clockInTime;
  DateTime? _clockOutTime;
  Duration _totalWorkTime = Duration.zero;
  Timer? _timer;
  DateTime _currentTime = DateTime.now();
  bool _isOnBreak = false;
  DateTime? _breakStartTime;
  Duration _breakDuration = Duration.zero;
  Map<String, dynamic>? _weeklyStats;
  late AnimationController _clockController;
  late Animation<double> _clockAnimation;
  List<Map<String, dynamic>> _breakTypes = [];
  Map<String, dynamic>? _currentBreakType;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _loadCurrentStatus();
    _loadWeeklyStats();
    _clockController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _clockAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _clockController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _clockController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
        if (_clockInTime != null && _clockOutTime == null) {
          _calculateWorkTime();
        }
        if (_isOnBreak && _breakStartTime != null) {
          _breakDuration = _currentTime.difference(_breakStartTime!);
        }
      });
    });
  }

  Future<void> _loadCurrentStatus() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?['_id'];
      if (userId != null) {
        final attendanceProvider =
            Provider.of<AttendanceProvider>(context, listen: false);
        await attendanceProvider.fetchTodayStatus(userId);
        final status = attendanceProvider.todayStatus;
        final currentAttendance = attendanceProvider.currentAttendance;
        setState(() {
          _currentStatus = _getStatusText(status);
          if (currentAttendance != null) {
            _clockInTime = currentAttendance['checkInTime'] != null
                ? DateTime.parse(currentAttendance['checkInTime'])
                : null;
            _clockOutTime = currentAttendance['checkOutTime'] != null
                ? DateTime.parse(currentAttendance['checkOutTime'])
                : null;
            _calculateWorkTime();
            final breaks = currentAttendance['breaks'] as List<dynamic>?;
            if (breaks != null && breaks.isNotEmpty) {
              final lastBreak = breaks.last;
              if (lastBreak['end'] == null) {
                _isOnBreak = true;
                _breakStartTime = DateTime.parse(lastBreak['start']);
                _breakDuration = _currentTime.difference(_breakStartTime!);
              }
            }
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading status: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadWeeklyStats() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?['_id'];
      if (userId != null) {
        final attendanceProvider =
            Provider.of<AttendanceProvider>(context, listen: false);
        final now = DateTime.now();
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        await attendanceProvider.fetchAttendanceSummary(
          userId,
          startDate: startOfWeek,
          endDate: endOfWeek,
        );
        setState(() {
          _weeklyStats = attendanceProvider.attendanceSummary;
        });
      }
    } catch (e) {}
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'not_clocked_in':
        return 'Not Clocked In';
      case 'clocked_in':
        return 'Clocked In';
      case 'on_break':
        return 'On Break';
      case 'clocked_out':
        return 'Clocked Out';
      default:
        return 'Not Clocked In';
    }
  }

  void _calculateWorkTime() {
    if (_clockInTime != null) {
      final endTime = _clockOutTime ?? _currentTime;
      _totalWorkTime = endTime.difference(_clockInTime!);
    }
  }

  Future<void> _clockIn() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?['_id'];
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('User not logged in. Please log in again.')),
        );
        return;
      }
      final attendanceService = AttendanceService(authProvider);
      await attendanceService.checkIn(userId);
      await _loadCurrentStatus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clocked in successfully!')),
      );
    } catch (e) {
      String errorMessage = 'An error occurred while clocking in.';
      if (e.toString().contains('Already checked in for today')) {
        errorMessage = 'You have already clocked in for today.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _clockOut() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?['_id'];
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('User not logged in. Please log in again.')),
        );
        return;
      }
      final attendanceService = AttendanceService(authProvider);
      await attendanceService.checkOut(userId);
      await _loadCurrentStatus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clocked out successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to clock out: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchBreakTypes() async {
    try {
      final attendanceProvider =
          Provider.of<AttendanceProvider>(context, listen: false);
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/attendance/break-types'),
        headers: {
          'Authorization':
              'Bearer ${Provider.of<AuthProvider>(context, listen: false).token}',
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> types = List.from(jsonDecode(response.body));
        setState(() {
          _breakTypes = types.cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      // Optionally show error
    }
  }

  Future<void> _startBreak() async {
    await _fetchBreakTypes();
    if (_breakTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No break types available.')),
      );
      return;
    }
    final selected = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select Break Type'),
        children: _breakTypes.map((type) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(context, type),
            child: Row(
              children: [
                Icon(_getMaterialIcon(type['icon']),
                    color: _parseColor(type['color']), size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(type['displayName'] ?? type['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (type['description'] != null &&
                          type['description'].toString().isNotEmpty)
                        Text(type['description'],
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
    if (selected == null) return;
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?['_id'];
      if (userId == null) return;
      final attendanceProvider =
          Provider.of<AttendanceProvider>(context, listen: false);
      await attendanceProvider.startBreakWithType(userId, selected);
      setState(() {
        _currentBreakType = selected;
      });
      await _loadCurrentStatus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Break started: ${selected['displayName'] ?? selected['name']}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start break: $e')),
      );
    }
  }

  Future<void> _endBreak() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?['_id'];
      if (userId == null) return;
      final attendanceProvider =
          Provider.of<AttendanceProvider>(context, listen: false);
      await attendanceProvider.endBreak(userId);
      setState(() {
        _currentBreakType = null;
      });
      await _loadCurrentStatus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Break ended!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to end break: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    final avatarUrl = user?['avatar'] as String?;
    final name = user?['firstName'] ?? 'Admin';
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2196F3), Color(0xFF90CAF9)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Admin Attendance'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _isLoading
                  ? null
                  : () {
                      _loadCurrentStatus();
                      _loadWeeklyStats();
                    },
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile Avatar & Greeting
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white,
                          backgroundImage:
                              (avatarUrl != null && avatarUrl.isNotEmpty)
                                  ? _getAvatarProvider(avatarUrl)
                                  : null,
                          child: (avatarUrl == null || avatarUrl.isEmpty)
                              ? const Icon(Icons.person,
                                  size: 32, color: Colors.blue)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, $name!',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Welcome back',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.85),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    // Quick Actions (moved to top)
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            const Text(
                              'Quick Actions',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed:
                                        _currentStatus == 'Not Clocked In'
                                            ? _clockIn
                                            : null,
                                    icon: const Icon(Icons.login),
                                    label: const Text('Clock In'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      textStyle: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      elevation: 4,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _currentStatus == 'Clocked In'
                                        ? _clockOut
                                        : null,
                                    icon: const Icon(Icons.logout),
                                    label: const Text('Clock Out'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      textStyle: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      elevation: 4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_currentStatus == 'Clocked In' &&
                                !_isOnBreak) ...[
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _startBreak,
                                  icon: const Icon(Icons.coffee),
                                  label: const Text('Start Break'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    textStyle: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    elevation: 4,
                                  ),
                                ),
                              ),
                            ],
                            if (_isOnBreak) ...[
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _endBreak,
                                  icon: const Icon(Icons.stop),
                                  label: const Text('End Break'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.purple,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    textStyle: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    elevation: 4,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Live Clock
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            const Text(
                              'Current Time',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ScaleTransition(
                              scale: _clockAnimation,
                              child: Text(
                                DateFormat('HH:mm:ss').format(_currentTime),
                                style: const TextStyle(
                                  fontSize: 38,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1976D2),
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                            Text(
                              DateFormat('EEEE, MMMM d, yyyy')
                                  .format(_currentTime),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Status Card
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            const Text(
                              'Current Status',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: _getStatusColor().withOpacity(0.15),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(_getStatusIcon(),
                                      color: _getStatusColor(), size: 22),
                                  const SizedBox(width: 8),
                                  Text(
                                    _currentStatus,
                                    style: TextStyle(
                                      color: _getStatusColor(),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Today's Time
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            const Text(
                              "Today's Time",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 15),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildTimeDisplay('Clock In', _clockInTime,
                                    icon: Icons.login, color: Colors.green),
                                _buildTimeDisplay('Clock Out', _clockOutTime,
                                    icon: Icons.logout, color: Colors.red),
                              ],
                            ),
                            const SizedBox(height: 15),
                            _buildTimeDisplay('Total Work Time', null,
                                customText: _formatDuration(_totalWorkTime),
                                icon: Icons.access_time,
                                color: Colors.blue),
                            if (_isOnBreak) ...[
                              const SizedBox(height: 15),
                              _buildBreakInfo(),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Weekly Summary Card
                    if (_weeklyStats != null) ...[
                      Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              const Text(
                                'This Week Summary',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 15),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatCard(
                                      'Days Present',
                                      _weeklyStats!['daysPresent']
                                              ?.toString() ??
                                          '0',
                                      Icons.check_circle,
                                      Colors.green),
                                  _buildStatCard(
                                      'Total Hours',
                                      _formatDurationFromMinutes(
                                          _weeklyStats!['totalHours'] ?? 0),
                                      Icons.access_time,
                                      Colors.blue),
                                ],
                              ),
                              const SizedBox(height: 15),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatCard(
                                      'Avg. Hours/Day',
                                      _formatDurationFromMinutes(
                                          _weeklyStats!['averageHoursPerDay'] ??
                                              0),
                                      Icons.trending_up,
                                      Colors.orange),
                                  _buildStatCard(
                                      'Break Time',
                                      _formatDurationFromMinutes(
                                          _weeklyStats!['totalBreakTime'] ?? 0),
                                      Icons.coffee,
                                      Colors.purple),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTimeDisplay(String label, DateTime? time,
      {String? customText, IconData? icon, Color? color}) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) Icon(icon, color: color ?? Colors.blue, size: 20),
            if (icon != null) const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: (color ?? Colors.blue).withOpacity(0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          customText ??
              (time != null ? DateFormat('HH:mm').format(time) : '--:--'),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor() {
    switch (_currentStatus) {
      case 'Not Clocked In':
        return Colors.grey;
      case 'Clocked In':
        return Colors.green;
      case 'On Break':
        return Colors.orange;
      case 'Clocked Out':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (_currentStatus) {
      case 'Not Clocked In':
        return Icons.access_time;
      case 'Clocked In':
        return Icons.login;
      case 'On Break':
        return Icons.coffee;
      case 'Clocked Out':
        return Icons.logout;
      default:
        return Icons.access_time;
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  String _formatDurationFromMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '${hours}h ${remainingMinutes}m';
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider? _getAvatarProvider(String url) {
    if (url.startsWith('http')) {
      return NetworkImage(url);
    } else if (url.startsWith('/uploads')) {
      // Prepend the backend base URL (remove trailing /api if present)
      String base = ApiConfig.baseUrl;
      if (base.endsWith('/api')) base = base.substring(0, base.length - 4);
      return NetworkImage(base + url);
    } else if (url.startsWith('file://')) {
      return FileImage(File(url.replaceFirst('file://', '')));
    }
    return null;
  }

  Widget _buildBreakInfo() {
    final type = _currentBreakType ?? (_currentAttendanceBreakType() ?? {});
    return Row(
      children: [
        Icon(_getMaterialIcon(type['icon']),
            color: _parseColor(type['color']), size: 28),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(type['displayName'] ?? type['name'] ?? 'Break',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Duration: ${_formatDuration(_breakDuration)}',
                style: const TextStyle(fontSize: 13)),
          ],
        ),
      ],
    );
  }

  Map<String, dynamic>? _currentAttendanceBreakType() {
    final breaks = _currentAttendance()?['breaks'] as List<dynamic>?;
    if (breaks != null && breaks.isNotEmpty) {
      final lastBreak = breaks.last;
      if (lastBreak['end'] == null) {
        return lastBreak['breakType'] as Map<String, dynamic>?;
      }
    }
    return null;
  }

  Map<String, dynamic>? _currentAttendance() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?['_id'];
    final attendanceProvider =
        Provider.of<AttendanceProvider>(context, listen: false);
    return attendanceProvider.currentAttendance;
  }

  IconData _getMaterialIcon(String? iconName) {
    // Map backend icon names to Material icons
    switch (iconName) {
      case 'free_breakfast':
        return Icons.free_breakfast;
      case 'lunch_dining':
        return Icons.lunch_dining;
      case 'coffee':
        return Icons.coffee;
      case 'local_cafe':
        return Icons.local_cafe;
      case 'restaurant':
        return Icons.restaurant;
      case 'self_improvement':
        return Icons.self_improvement;
      default:
        return Icons.free_breakfast;
    }
  }

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.grey;
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xff')));
    } catch (_) {
      return Colors.grey;
    }
  }
}
