import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import 'auth_provider.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/attendance.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class AdminAttendanceProvider extends ChangeNotifier {
  final AuthProvider authProvider;
  AdminAttendanceProvider(this.authProvider);

  List<Attendance> attendanceRecords = [];
  bool isLoading = false;
  String? error;
  int? total;
  int? page;

  Future<void> fetchAttendance({
    String? start,
    String? end,
    String? userId,
    int? page,
    int? limit,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final params = <String, String>{};
      if (start != null) params['startDate'] = start;
      if (end != null) params['endDate'] = end;
      if (userId != null) params['userId'] = userId;
      if (page != null) params['page'] = page.toString();
      if (limit != null) params['limit'] = limit.toString();
      final uri = Uri.parse('${ApiConfig.baseUrl}/admin/attendance')
          .replace(queryParameters: params);
      final token = authProvider.token;
      final response = await http.get(uri,
          headers: token != null ? {'Authorization': 'Bearer $token'} : {});
      if (response.statusCode == 200) {
        print('DEBUG: AdminAttendanceProvider API response: ${response.body}');
        final data = json.decode(response.body);
        attendanceRecords = (data['attendance'] as List<dynamic>? ?? [])
            .map((e) => Attendance.fromJson(e as Map<String, dynamic>))
            .toList();
        total = data['total'] as int?;
        page = data['page'] as int?;
      } else {
        error = 'Failed to fetch attendance: ${response.statusCode}';
      }
    } catch (e) {
      error = 'Error: $e';
    }
    isLoading = false;
    notifyListeners();
  }

  Future<bool> editAttendance(
      String attendanceId, Map<String, dynamic> update) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/attendance/$attendanceId');
      final token = authProvider.token;
      final response = await http.put(uri, body: json.encode(update), headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      });
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<String?> exportAttendance(
      {String? start,
      String? end,
      String? userId,
      String? employeeName}) async {
    try {
      // Optionally, you could filter attendanceRecords here by userId if needed
      // Prepare CSV data
      final List<List<dynamic>> csvData = [
        [
          'Employee',
          'Date',
          'Check In',
          'Check Out',
          'Total Hours',
          'Break Duration',
          'Break Status',
          'Status',
        ],
        ...attendanceRecords.map((rec) {
          final user = rec.user;
          final employeeName =
              user != null ? (user['name'] ?? user['firstName'] ?? '-') : '-';
          final date = rec.date?.toString() ?? '-';
          final checkIn = rec.checkInTime?.toString() ?? '-';
          final checkOut = rec.checkOutTime?.toString() ?? '-';
          // Calculate total hours
          String totalHours = '-';
          if (rec.checkInTime != null && rec.checkOutTime != null) {
            final inDt = DateTime.tryParse(rec.checkInTime.toString());
            final outDt = DateTime.tryParse(rec.checkOutTime.toString());
            int breakMs = rec.totalBreakDuration ?? 0;
            if (inDt != null && outDt != null) {
              int total = outDt.difference(inDt).inMilliseconds - breakMs;
              if (total < 0) total = 0;
              final h = total ~/ (1000 * 60 * 60);
              final m = ((total % (1000 * 60 * 60)) / (1000 * 60)).round();
              totalHours = '${h}h ${m}m';
            }
          }
          // Calculate break duration
          String breakDuration = '0h 0m';
          String breakStatus = 'No Break';
          final breaks = rec.breaks as List?;
          if (breaks != null && breaks.isNotEmpty) {
            int totalMs = 0;
            final ongoing = breaks.any((b) => b['end'] == null);
            if (ongoing) {
              breakStatus = 'On Break';
            } else {
              breakStatus = 'Break Ended';
            }
            for (final b in breaks) {
              if (b['start'] != null && b['end'] != null) {
                final start = DateTime.tryParse(b['start'].toString());
                final end = DateTime.tryParse(b['end'].toString());
                if (start != null && end != null) {
                  totalMs += end.difference(start).inMilliseconds;
                }
              }
            }
            if (totalMs < 0) totalMs = 0;
            final d = Duration(milliseconds: totalMs);
            final h = d.inHours;
            final m = d.inMinutes % 60;
            breakDuration = '${h}h ${m}m';
          }
          // Compute status
          String status = '-';
          if (rec.checkInTime != null && rec.checkOutTime != null) {
            status = 'Present';
          } else if (rec.checkInTime != null) {
            final breaks = rec.breaks as List? ?? [];
            final onBreak = breaks.any((b) => b['end'] == null);
            status = onBreak ? 'On Break' : 'Clocked In';
          } else {
            status = 'Absent';
          }
          return [
            employeeName,
            date,
            checkIn,
            checkOut,
            totalHours,
            breakDuration,
            breakStatus,
            status,
          ];
        })
      ];
      final csvString = const ListToCsvConverter().convert(csvData);
      // Get directory
      Directory? dir;
      if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Download');
      } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        dir = await getDownloadsDirectory();
      }
      dir ??= await getApplicationDocumentsDirectory();
      // --- Filename logic ---
      String employeePart = 'all-employees';
      if (employeeName != null &&
          employeeName.trim().isNotEmpty &&
          employeeName != '-') {
        employeePart = employeeName
            .trim()
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]+'), '-');
      }
      String datePart = '';
      if (start != null && end != null) {
        try {
          final startDt = DateTime.parse(start);
          final endDt = DateTime.parse(end);
          final startStr = DateFormat('MMMdd').format(startDt); // e.g., Jun28
          final endStr = DateFormat('MMMdd').format(endDt); // e.g., Jul05
          datePart = '-$startStr-$endStr';
        } catch (_) {}
      }
      final filePath = '${dir.path}/$employeePart-attendance${datePart}.csv';
      print(
          'DEBUG EXPORT: employeePart=$employeePart, datePart=$datePart, filePath=$filePath');
      final file = File(filePath);
      await file.writeAsString(csvString);
      return filePath;
    } catch (e) {
      error = 'Failed to export CSV: $e';
      return null;
    }
  }

  Future<String?> exportAttendancePdf(
      {String? start,
      String? end,
      String? userId,
      String? employeeName}) async {
    try {
      final pdf = pw.Document();
      final headers = [
        'Employee',
        'Date',
        'Check In',
        'Check Out',
        'Total Hours',
        'Break Duration',
        'Break Status',
        'Status'
      ];
      final data = attendanceRecords.map((rec) {
        final user = rec.user;
        final employeeName =
            user != null ? (user['name'] ?? user['firstName'] ?? '-') : '-';
        final date = rec.date?.toString() ?? '-';
        final checkIn = rec.checkInTime?.toString() ?? '-';
        final checkOut = rec.checkOutTime?.toString() ?? '-';
        String totalHours = '-';
        if (rec.checkInTime != null && rec.checkOutTime != null) {
          final inDt = DateTime.tryParse(rec.checkInTime.toString());
          final outDt = DateTime.tryParse(rec.checkOutTime.toString());
          int breakMs = rec.totalBreakDuration ?? 0;
          if (inDt != null && outDt != null) {
            int total = outDt.difference(inDt).inMilliseconds - breakMs;
            if (total < 0) total = 0;
            final h = total ~/ (1000 * 60 * 60);
            final m = ((total % (1000 * 60 * 60)) / (1000 * 60)).round();
            totalHours = '${h}h ${m}m';
          }
        }
        String breakDuration = '0h 0m';
        String breakStatus = 'No Break';
        final breaks = rec.breaks as List?;
        if (breaks != null && breaks.isNotEmpty) {
          int totalMs = 0;
          final ongoing = breaks.any((b) => b['end'] == null);
          if (ongoing) {
            breakStatus = 'On Break';
          } else {
            breakStatus = 'Break Ended';
          }
          for (final b in breaks) {
            if (b['start'] != null && b['end'] != null) {
              final start = DateTime.tryParse(b['start'].toString());
              final end = DateTime.tryParse(b['end'].toString());
              if (start != null && end != null) {
                totalMs += end.difference(start).inMilliseconds;
              }
            }
          }
          if (totalMs < 0) totalMs = 0;
          final d = Duration(milliseconds: totalMs);
          final h = d.inHours;
          final m = d.inMinutes % 60;
          breakDuration = '${h}h ${m}m';
        }
        String status = '-';
        if (rec.checkInTime != null && rec.checkOutTime != null) {
          status = 'Present';
        } else if (rec.checkInTime != null) {
          final breaks = rec.breaks as List? ?? [];
          final onBreak = breaks.any((b) => b['end'] == null);
          status = onBreak ? 'On Break' : 'Clocked In';
        } else {
          status = 'Absent';
        }
        return [
          employeeName,
          date,
          checkIn,
          checkOut,
          totalHours,
          breakDuration,
          breakStatus,
          status,
        ];
      }).toList();
      pdf.addPage(
        pw.Page(
          build: (context) => pw.Table.fromTextArray(
            headers: headers,
            data: data,
            cellStyle: pw.TextStyle(fontSize: 10),
            headerStyle:
                pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
            headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
            border: null,
            cellAlignment: pw.Alignment.centerLeft,
          ),
        ),
      );
      Directory? dir;
      if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Download');
      } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        dir = await getDownloadsDirectory();
      }
      dir ??= await getApplicationDocumentsDirectory();
      String employeePart = 'all-employees';
      if (employeeName != null &&
          employeeName.trim().isNotEmpty &&
          employeeName != '-') {
        employeePart = employeeName
            .trim()
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]+'), '-');
      }
      String datePart = '';
      if (start != null && end != null) {
        try {
          final startDt = DateTime.parse(start);
          final endDt = DateTime.parse(end);
          final startStr = DateFormat('MMMdd').format(startDt);
          final endStr = DateFormat('MMMdd').format(endDt);
          datePart = '-$startStr-$endStr';
        } catch (_) {}
      }
      final filePath = '${dir.path}/$employeePart-attendance${datePart}.pdf';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());
      return filePath;
    } catch (e) {
      error = 'Failed to export PDF: $e';
      return null;
    }
  }

  // Legacy method for Admin Timesheet screen
  Future<void> fetchAttendanceLegacy({
    String? start,
    String? end,
    String? userId,
    int? page,
    int? limit,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final params = <String, String>{};
      if (start != null) params['start'] = start;
      if (end != null) params['end'] = end;
      if (userId != null) params['userId'] = userId;
      if (page != null) params['page'] = page.toString();
      if (limit != null) params['limit'] = limit.toString();
      final uri = Uri.parse('${ApiConfig.baseUrl}/attendance')
          .replace(queryParameters: params);
      final token = authProvider.token;
      final response = await http.get(uri,
          headers: token != null ? {'Authorization': 'Bearer $token'} : {});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        attendanceRecords = (data['attendance'] as List<dynamic>? ?? [])
            .map((e) => Attendance.fromJson(e as Map<String, dynamic>))
            .toList();
        total = data['total'] as int?;
        page = data['page'] as int?;
      } else {
        error = 'Failed to fetch attendance: \\${response.statusCode}';
      }
    } catch (e) {
      error = 'Error: \\${e}';
    }
    isLoading = false;
    notifyListeners();
  }
}
