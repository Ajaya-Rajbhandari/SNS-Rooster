import 'package:flutter/material.dart';

class HolidayProvider with ChangeNotifier {
  List<Map<String, dynamic>> _holidays = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get holidays => _holidays;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchHolidays() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Simulate a network call
      await Future.delayed(Duration(seconds: 2));
      _holidays = [
        {'date': '2023-12-25', 'name': 'Christmas'},
        {'date': '2024-01-01', 'name': 'New Year\'s Day'},
      ];
      // Sort holidays by date
      _holidays.sort((a, b) => a['date'].compareTo(b['date']));
    } catch (e) {
      _error = e.toString();
      _holidays = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearHolidays() {
    _holidays = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
