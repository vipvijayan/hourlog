import 'package:flutter/foundation.dart';
import '../models/time_record.dart';
import '../database/database_helper.dart';

class TimeProvider extends ChangeNotifier {
  List<TimeRecord> _records = [];
  TimeRecord? _activeRecord;
  bool _isLoading = false;
  String? _error;

  List<TimeRecord> get records => _records;
  TimeRecord? get activeRecord => _activeRecord;
  bool get isCheckedIn => _activeRecord != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    try {
      await DatabaseHelper.instance.seedSampleData();
      _activeRecord = await DatabaseHelper.instance.getActiveRecord();
      _records = await DatabaseHelper.instance.getAllRecords();
      _error = null;
    } catch (e) {
      if (kIsWeb) {
        _records = _sampleRecords();
        _activeRecord = _records.firstWhere(
          (record) => record.isActive,
          orElse: () => _records.isNotEmpty ? _records.first : _records.first,
        );
        _error = null;
      } else {
        _error = 'Failed to load data. Please restart the app.';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<TimeRecord> _sampleRecords() {
    final now = DateTime.now();
    final currentWeekMonday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));

    return [
      TimeRecord(
        checkIn: DateTime(
          currentWeekMonday.year,
          currentWeekMonday.month,
          currentWeekMonday.day,
          9,
          0,
        ).millisecondsSinceEpoch,
        checkOut: DateTime(
          currentWeekMonday.year,
          currentWeekMonday.month,
          currentWeekMonday.day,
          17,
          30,
        ).millisecondsSinceEpoch,
      ),
      TimeRecord(
        checkIn: DateTime(
          currentWeekMonday.year,
          currentWeekMonday.month,
          currentWeekMonday.day + 1,
          9,
          15,
        ).millisecondsSinceEpoch,
        checkOut: DateTime(
          currentWeekMonday.year,
          currentWeekMonday.month,
          currentWeekMonday.day + 1,
          17,
          0,
        ).millisecondsSinceEpoch,
      ),
      TimeRecord(
        checkIn: DateTime(
          currentWeekMonday.year,
          currentWeekMonday.month,
          currentWeekMonday.day + 2,
          8,
          45,
        ).millisecondsSinceEpoch,
        checkOut: DateTime(
          currentWeekMonday.year,
          currentWeekMonday.month,
          currentWeekMonday.day + 2,
          16,
          50,
        ).millisecondsSinceEpoch,
      ),
      TimeRecord(
        checkIn: DateTime(
          now.year,
          now.month,
          now.day,
          10,
          0,
        ).millisecondsSinceEpoch,
        checkOut: null,
      ),
    ];
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<bool> checkIn() async {
    if (isCheckedIn) {
      _error = 'You are already checked in.';
      notifyListeners();
      return false;
    }
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final record = TimeRecord(checkIn: now);
      final id = await DatabaseHelper.instance.insertRecord(record);
      _activeRecord = record.copyWith(id: id);
      _records = await DatabaseHelper.instance.getAllRecords();
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to check in. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> checkOut() async {
    if (!isCheckedIn || _activeRecord == null) {
      _error = 'You are not checked in.';
      notifyListeners();
      return false;
    }
    try {
      final updated = _activeRecord!.copyWith(
        checkOut: DateTime.now().millisecondsSinceEpoch,
      );
      await DatabaseHelper.instance.updateRecord(updated);
      _activeRecord = null;
      _records = await DatabaseHelper.instance.getAllRecords();
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to check out. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<void> deleteRecord(int id) async {
    try {
      await DatabaseHelper.instance.deleteRecord(id);
      _records = await DatabaseHelper.instance.getAllRecords();
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete record.';
      notifyListeners();
    }
  }

  Future<bool> updateRecord(TimeRecord record) async {
    try {
      await DatabaseHelper.instance.updateRecord(record);
      if (_activeRecord?.id == record.id) {
        _activeRecord = record.isActive ? record : null;
      }
      _records = await DatabaseHelper.instance.getAllRecords();
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update record.';
      notifyListeners();
      return false;
    }
  }

  // --- Duration calculations ---

  Duration getTotalForDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return _records
        .where(
          (r) =>
              r.checkOut != null &&
              r.checkInTime.isAfter(
                start.subtract(const Duration(milliseconds: 1)),
              ) &&
              r.checkInTime.isBefore(end),
        )
        .fold(Duration.zero, (total, r) => total + r.duration!);
  }

  Duration getTotalForCurrentWeek() {
    final now = DateTime.now();
    // ISO week: Monday = 1
    final weekStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));
    return _records
        .where(
          (r) =>
              r.checkOut != null &&
              r.checkInTime.isAfter(
                weekStart.subtract(const Duration(milliseconds: 1)),
              ) &&
              r.checkInTime.isBefore(weekEnd),
        )
        .fold(Duration.zero, (total, r) => total + r.duration!);
  }

  Duration getTotalForCurrentMonth() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1);
    return _records
        .where(
          (r) =>
              r.checkOut != null &&
              r.checkInTime.isAfter(
                monthStart.subtract(const Duration(milliseconds: 1)),
              ) &&
              r.checkInTime.isBefore(monthEnd),
        )
        .fold(Duration.zero, (total, r) => total + r.duration!);
  }

  Duration getAveragePerMonth() {
    final completed = _records.where((r) => r.checkOut != null).toList();
    if (completed.isEmpty) return Duration.zero;
    final Map<String, int> monthTotals = {};
    for (final r in completed) {
      final key = '${r.checkInTime.year}-${r.checkInTime.month}';
      monthTotals[key] = (monthTotals[key] ?? 0) + r.duration!.inMicroseconds;
    }
    final total = monthTotals.values.fold<int>(0, (a, b) => a + b);
    final avgMicro = total ~/ monthTotals.length;
    return Duration(microseconds: avgMicro);
  }

  Duration getAveragePerYear() {
    final completed = _records.where((r) => r.checkOut != null).toList();
    if (completed.isEmpty) return Duration.zero;
    final Map<int, int> yearTotals = {};
    for (final r in completed) {
      final key = r.checkInTime.year;
      yearTotals[key] = (yearTotals[key] ?? 0) + r.duration!.inMicroseconds;
    }
    final total = yearTotals.values.fold<int>(0, (a, b) => a + b);
    final avgMicro = total ~/ yearTotals.length;
    return Duration(microseconds: avgMicro);
  }

  /// Group records by calendar date (most recent first)
  Map<DateTime, List<TimeRecord>> get recordsByDay {
    final Map<DateTime, List<TimeRecord>> grouped = {};
    for (final record in _records) {
      final day = DateTime(
        record.checkInTime.year,
        record.checkInTime.month,
        record.checkInTime.day,
      );
      grouped.putIfAbsent(day, () => []).add(record);
    }
    return grouped;
  }
}
