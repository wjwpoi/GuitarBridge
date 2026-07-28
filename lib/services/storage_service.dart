import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/practice_record.dart';

/// 本地持久化服务（对应原 Swift CloudStore / SwiftData）
class StorageService {
  static const _recordsKey = 'practice_records';
  static const _streaksKey = 'practice_streaks';
  static const _prefsKey = 'user_preferences';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  // === 练习记录 ===

  Future<List<PracticeRecord>> getRecords() async {
    final json = _prefs.getString(_recordsKey);
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    return list
        .map((e) => PracticeRecord.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveRecord(PracticeRecord record) async {
    final records = await getRecords();
    records.add(record);
    await _prefs.setString(
      _recordsKey,
      jsonEncode(records.map((r) => r.toMap()).toList()),
    );
  }

  Future<void> clearRecords() async {
    await _prefs.remove(_recordsKey);
  }

  Future<void> clearStreaks() async {
    await _prefs.remove(_streaksKey);
  }

  // === 连续练习 ===

  Future<List<PracticeStreak>> getStreaks() async {
    final json = _prefs.getString(_streaksKey);
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    return list
        .map((e) => PracticeStreak.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> addStreak(PracticeStreak streak) async {
    final streaks = await getStreaks();
    final date = _localDay(streak.date);
    final hasDate = streaks.any((existing) => _localDay(existing.date) == date);
    if (!hasDate) {
      streaks.add(streak);
    }
    await _prefs.setString(
      _streaksKey,
      jsonEncode(streaks.map((s) => s.toMap()).toList()),
    );
  }

  DateTime _localDay(DateTime value) {
    final local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  // === 用户设置 ===

  Future<UserPreferences> getPreferences() async {
    final json = _prefs.getString(_prefsKey);
    if (json == null) return UserPreferences();
    return UserPreferences.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  Future<void> savePreferences(UserPreferences prefs) async {
    await _prefs.setString(_prefsKey, jsonEncode(prefs.toJson()));
  }
}
