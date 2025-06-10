import 'package:flutter/material.dart';
import '../services/mock_service.dart';

class HolidayProvider with ChangeNotifier {
  final MockHolidayService _mockService = MockHolidayService();
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
      _holidays = await _mockService.getHolidays();
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
