import 'package:flutter/foundation.dart';
import '../models/practice_record.dart';
import 'storage_service.dart';

/// 连续练习管理器（对应原 Swift StreakManager.swift）
class StreakManager extends ChangeNotifier {
  final StorageService _storage;
  List<PracticeStreak> _streaks = [];
  List<PracticeRecord> _records = [];

  StreakManager(this._storage);

  int get currentStreak {
    if (_streaks.isEmpty) return 0;
    _streaks.sort((a, b) => b.date.compareTo(a.date));

    int streak = 1;
    final today = DateTime.now();
    var checkDate = DateTime(today.year, today.month, today.day);
    final firstDate = DateTime(
      _streaks.first.date.year,
      _streaks.first.date.month,
      _streaks.first.date.day,
    );

    if (!checkDate.isAtSameMomentAs(firstDate)) return 0;

    for (int i = 1; i < _streaks.length; i++) {
      final prevDate = DateTime(
        _streaks[i - 1].date.year,
        _streaks[i - 1].date.month,
        _streaks[i - 1].date.day,
      );
      final currDate = DateTime(
        _streaks[i].date.year,
        _streaks[i].date.month,
        _streaks[i].date.day,
      );
      if (prevDate.difference(currDate).inDays == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  int get totalPracticeDays {
    final days = _streaks.map((s) =>
        DateTime(s.date.year, s.date.month, s.date.day)).toSet();
    return days.length;
  }

  int get bestStreak {
    if (_streaks.isEmpty) return 0;
    _streaks.sort((a, b) => a.date.compareTo(b.date));

    int best = 0;
    int current = 1;
    for (int i = 1; i < _streaks.length; i++) {
      final prevDate = DateTime(
        _streaks[i - 1].date.year,
        _streaks[i - 1].date.month,
        _streaks[i - 1].date.day,
      );
      final currDate = DateTime(
        _streaks[i].date.year,
        _streaks[i].date.month,
        _streaks[i].date.day,
      );
      if (prevDate.difference(currDate).inDays == 1) {
        current++;
      } else {
        best = best > current ? best : current;
        current = 1;
      }
    }
    return best > current ? best : current;
  }

  Future<void> loadData() async {
    _streaks = await _storage.getStreaks();
    _records = await _storage.getRecords();
    notifyListeners();
  }

  Future<void> recordSession(PracticeRecord record) async {
    await _storage.saveRecord(record);
    await _storage.addStreak(PracticeStreak(date: DateTime.now()));
    _records.add(record);
    notifyListeners();
  }

  Future<void> clearAll() async {
    await _storage.clearRecords();
    _streaks = [];
    _records = [];
    notifyListeners();
  }
}
