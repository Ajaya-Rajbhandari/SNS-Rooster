class PayrollCycleUtils {
  /// Compute current cycle period (start & end dates) based on cycle settings
  /// Supported frequencies: Monthly, Semi-Monthly, Bi-Weekly, Weekly
  static Map<String, DateTime> currentPeriod(Map<String, dynamic> cycle,
      {DateTime? reference}) {
    reference ??= DateTime.now();
    final freq = (cycle['frequency'] ?? 'Monthly') as String;

    switch (freq) {
      case 'Semi-Monthly':
        return _semiMonthlyPeriod(cycle, reference);
      case 'Bi-Weekly':
        return _biWeeklyPeriod(cycle, reference);
      case 'Weekly':
        return _weeklyPeriod(cycle, reference);
      default:
        return _monthlyPeriod(cycle, reference);
    }
  }

  /// Compute next pay date according to cycle rules
  static DateTime nextPayDate(Map<String, dynamic> cycle,
      {DateTime? reference}) {
    reference ??= DateTime.now();
    final freq = (cycle['frequency'] ?? 'Monthly') as String;
    final offset = (cycle['payOffset'] ?? 0) as int;

    switch (freq) {
      case 'Semi-Monthly':
        final payDay = (cycle['payDay'] ?? 30) as int; // second pay day
        final firstPayDay = (cycle['payDay1'] ?? 15) as int;
        DateTime tentative1 =
            DateTime(reference.year, reference.month, firstPayDay);
        DateTime tentative2 = DateTime(reference.year, reference.month, payDay);
        if (reference.isBefore(tentative1)) {
          return tentative1.add(Duration(days: offset));
        } else if (reference.isBefore(tentative2)) {
          return tentative2.add(Duration(days: offset));
        } else {
          tentative1 =
              DateTime(reference.year, reference.month + 1, firstPayDay);
          return tentative1.add(Duration(days: offset));
        }
      case 'Bi-Weekly':
        final startRef = DateTime(
            reference.year, reference.month, (cycle['cutoffDay'] ?? 1));
        int diff = reference.difference(startRef).inDays;
        int daysToNext = 14 - (diff % 14);
        return reference.add(Duration(days: daysToNext + offset));
      case 'Weekly':
        int weekday =
            (cycle['payWeekday'] ?? DateTime.friday) as int; // 1=Mon..7=Sun
        int diff = (weekday - reference.weekday + 7) % 7;
        if (diff == 0) diff = 7; // next week
        return reference.add(Duration(days: diff + offset));
      default:
        final payDay = (cycle['payDay'] ?? 30) as int;
        DateTime tentative = DateTime(reference.year, reference.month, payDay);
        if (!reference.isBefore(tentative)) {
          tentative = DateTime(reference.year, reference.month + 1, payDay);
        }
        return tentative.add(Duration(days: offset));
    }
  }

  // ----- helpers -----
  static Map<String, DateTime> _monthlyPeriod(
      Map<String, dynamic> cycle, DateTime now) {
    final cutoff = (cycle['cutoffDay'] ?? 25) as int;
    DateTime start, end;
    if (now.day > cutoff) {
      start = DateTime(now.year, now.month, cutoff + 1);
      end = DateTime(now.year, now.month + 1, cutoff);
    } else {
      final prev = DateTime(now.year, now.month - 1, 1);
      start = DateTime(prev.year, prev.month, cutoff + 1);
      end = DateTime(prev.year, prev.month + 1, cutoff);
    }
    return {'start': start, 'end': end};
  }

  static Map<String, DateTime> _semiMonthlyPeriod(
      Map<String, dynamic> cycle, DateTime now) {
    // Assume first cycle: 1-15, second: 16-end
    const mid = 15;
    DateTime start, end;
    if (now.day <= mid) {
      // we're in second half of previous month?
      start = DateTime(now.year, now.month - 1, mid + 1);
      end = DateTime(
          now.year, now.month - 1, _daysInMonth(now.year, now.month - 1));
    } else {
      start = DateTime(now.year, now.month, 1);
      end = DateTime(now.year, now.month, mid);
    }
    return {'start': start, 'end': end};
  }

  static Map<String, DateTime> _biWeeklyPeriod(
      Map<String, dynamic> cycle, DateTime now) {
    final startRef = DateTime(now.year, now.month, (cycle['cutoffDay'] ?? 1));
    int diff = now.difference(startRef).inDays;
    int cycles = (diff / 14).floor();
    DateTime periodStart = startRef.add(Duration(days: cycles * 14));
    DateTime periodEnd = periodStart.add(const Duration(days: 13));
    return {'start': periodStart, 'end': periodEnd};
  }

  static Map<String, DateTime> _weeklyPeriod(
      Map<String, dynamic> cycle, DateTime now) {
    final weekdayStart = (cycle['weekStart'] ?? DateTime.monday) as int;
    int diff = (now.weekday - weekdayStart + 7) % 7;
    DateTime periodStart = now.subtract(Duration(days: diff));
    DateTime periodEnd = periodStart.add(const Duration(days: 6));
    return {'start': periodStart, 'end': periodEnd};
  }
}

int _daysInMonth(int year, int month) {
  if (month == 12) {
    return DateTime(year + 1, 1, 0).day;
  }
  return DateTime(year, month + 1, 0).day;
}
