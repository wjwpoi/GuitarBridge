import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:guitar_bridge/models/practice_record.dart';
import 'package:guitar_bridge/services/storage_service.dart';
import 'package:guitar_bridge/services/streak_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('adding a streak preserves previous practice days', () async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    SharedPreferences.setMockInitialValues({
      'practice_streaks': jsonEncode([PracticeStreak(date: yesterday).toMap()]),
    });
    final storage = StorageService(await SharedPreferences.getInstance());

    await storage.addStreak(PracticeStreak(date: DateTime.now()));

    final streaks = await storage.getStreaks();
    expect(streaks, hasLength(2));
  });

  test('adding a streak twice on the same local day is idempotent', () async {
    final now = DateTime.now();
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService(await SharedPreferences.getInstance());

    await storage.addStreak(PracticeStreak(date: now));
    await storage.addStreak(
      PracticeStreak(date: now.add(const Duration(hours: 1))),
    );

    expect(await storage.getStreaks(), hasLength(1));
  });

  test(
    'UTC and local timestamps on the same local day are deduplicated',
    () async {
      final now = DateTime.now();
      SharedPreferences.setMockInitialValues({});
      final storage = StorageService(await SharedPreferences.getInstance());

      await storage.addStreak(PracticeStreak(date: now));
      await storage.addStreak(PracticeStreak(date: now.toUtc()));

      expect(await storage.getStreaks(), hasLength(1));
    },
  );

  test('manager exposes records and clears all persisted data', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService(await SharedPreferences.getInstance());
    final manager = StreakManager(storage);
    final record = PracticeRecord(
      date: DateTime.now(),
      totalAttempts: 10,
      correctAnswers: 8,
      durationSeconds: 30,
      keySignature: 'C',
      scaleType: '自然大调',
      bestStreak: 4,
    );

    await manager.recordSession(record);
    expect(manager.records, hasLength(1));
    expect(manager.currentStreak, 1);

    await manager.clearAll();
    expect(manager.records, isEmpty);
    expect(await storage.getRecords(), isEmpty);
    expect(await storage.getStreaks(), isEmpty);
  });

  test('preferences round-trip new audio and session fields', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService(await SharedPreferences.getInstance());
    final preferences = UserPreferences(
      questionsPerSession: 30,
      audioVolume: 0.4,
      toneMode: 'distortion',
    );

    await storage.savePreferences(preferences);
    final loaded = await storage.getPreferences();

    expect(loaded.questionsPerSession, 30);
    expect(loaded.audioVolume, 0.4);
    expect(loaded.toneMode, 'distortion');
  });

  test('legacy preferences receive defaults for newly added fields', () {
    final loaded = UserPreferences.fromJson({
      'selectedKey': 'G',
      'hasCompletedOnboarding': true,
    });

    expect(loaded.selectedKey, 'G');
    expect(loaded.questionsPerSession, 10);
    expect(loaded.audioVolume, 0.8);
    expect(loaded.toneMode, 'clean');
  });

  test('manager calculates current and best streak in date order', () async {
    final today = DateTime.now();
    SharedPreferences.setMockInitialValues({
      'practice_streaks': jsonEncode([
        PracticeStreak(date: today.subtract(const Duration(days: 3))).toMap(),
        PracticeStreak(date: today.subtract(const Duration(days: 1))).toMap(),
        PracticeStreak(date: today).toMap(),
      ]),
    });
    final storage = StorageService(await SharedPreferences.getInstance());
    final manager = StreakManager(storage);

    await manager.loadData();

    expect(manager.currentStreak, 2);
    expect(manager.bestStreak, 2);
    expect(manager.totalPracticeDays, 3);
  });

  test('corrupted record JSON returns empty list', () async {
    SharedPreferences.setMockInitialValues({'practice_records': '{bad json'});
    final storage = StorageService(await SharedPreferences.getInstance());
    expect(await storage.getRecords(), isEmpty);
  });

  test('corrupted preferences JSON returns defaults', () async {
    SharedPreferences.setMockInitialValues({'user_preferences': '{bad json'});
    final storage = StorageService(await SharedPreferences.getInstance());
    final prefs = await storage.getPreferences();
    expect(prefs.audioVolume, 0.8);
    expect(prefs.questionsPerSession, 10);
  });
}
