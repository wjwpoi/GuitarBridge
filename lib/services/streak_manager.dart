import 'package:flutter/foundation.dart';

import '../models/practice_record.dart';
import 'storage_service.dart';

class StreakManager extends ChangeNotifier {
  StreakManager(this._storage);

  final StorageService _storage;
  List<PracticeStreak> _streaks = [];
  List<PracticeRecord> _records = [];

  List<PracticeRecord> get records => List.unmodifiable(_records);

  int get currentStreak {
    final days = _uniqueDates(descending: true);
    if (days.isEmpty) return 0;
    final today = _day(DateTime.now());
    if (days.first != today) return 0;
    var result = 1;
    for (var i = 1; i < days.length; i++) {
      if (days[i - 1].difference(days[i]).inDays != 1) break;
      result++;
    }
    return result;
  }

  int get totalPracticeDays => _uniqueDates().length;

  int get bestStreak {
    final days = _uniqueDates();
    if (days.isEmpty) return 0;
    var best = 1;
    var current = 1;
    for (var i = 1; i < days.length; i++) {
      if (days[i].difference(days[i - 1]).inDays == 1) {
        current++;
        best = best > current ? best : current;
      } else {
        current = 1;
      }
    }
    return best;
  }

  Future<void> loadData() async {
    _streaks = await _storage.getStreaks();
    _records = await _storage.getRecords();
    notifyListeners();
  }

  Future<void> recordSession(PracticeRecord record) async {
    await _storage.saveRecord(record);
    final streak = PracticeStreak(date: DateTime.now());
    await _storage.addStreak(streak);
    _records = [..._records, record];
    if (!_streaks.any((existing) => _day(existing.date) == _day(streak.date))) {
      _streaks = [..._streaks, streak];
    }
    notifyListeners();
  }

  Future<void> clearAll() async {
    await Future.wait([
      _storage.clearRecords(),
      _storage.clearStreaks(),
    ]);
    _streaks = [];
    _records = [];
    notifyListeners();
  }

  List<DateTime> _uniqueDates({bool descending = false}) {
    final dates = <DateTime>{
      for (final streak in _streaks) _day(streak.date),
    }.toList();
    dates.sort((a, b) => descending ? b.compareTo(a) : a.compareTo(b));
    return dates;
  }

  DateTime _day(DateTime value) => DateTime(value.year, value.month, value.day);
}
