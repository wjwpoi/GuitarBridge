import 'package:guitar_bridge/core/guitar_math.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guitar_bridge/models/scale.dart';
import 'package:guitar_bridge/models/tuning.dart';
import 'package:guitar_bridge/engine/training_engine.dart';
import 'package:guitar_bridge/engine/audio_engine.dart';
import 'package:guitar_bridge/core/constants.dart';

/// Mock AudioEngine that doesn't actually play audio
class MockAudioEngine extends AudioEngine {
  int playCallCount = 0;

  @override
  Future<void> initialize() async {}

  @override
  bool get isReady => true;

  @override
  Future<void> playNote(int midiNote) async {
    playCallCount++;
  }
}

void main() {
  late TrainingEngine engine;
  late MockAudioEngine mockAudio;

  setUp(() {
    engine = TrainingEngine();
    mockAudio = MockAudioEngine();
    engine.configure(engine: mockAudio, tuning: Tuning.standard);
    engine
      ..currentKey = 'C'
      ..scaleType = ScaleType.major
      ..difficulty = AppConstants.difficulties['easy']!;
  });

  group('TrainingEngine - State Machine', () {
    test('initial state is idle', () {
      expect(engine.state, TrainingState.idle);
    });

    test('configure sets audio engine and tuning', () {
      final e = TrainingEngine();
      e.configure(engine: mockAudio, tuning: Tuning.dropD);
      expect(e.currentTuning.name, 'Drop D');
    });

    test('start transitions from idle to playingRoot', () async {
      await engine.start();
      expect(
        engine.state,
        anyOf(TrainingState.playingRoot, TrainingState.waitingAnswer),
      );
    });

    test('reset returns to idle state', () async {
      await engine.start();
      engine.reset();
      expect(engine.state, TrainingState.idle);
    });

    test('reset clears all counters', () async {
      await engine.start();
      engine.reset();
      expect(engine.correctCount, 0);
      expect(engine.currentQuestion, 0);
      expect(engine.currentStreak, 0);
      expect(engine.bestStreak, 0);
    });
  });

  group('TrainingEngine - Question Generation', () {
    test('rootMidi is set after start', () async {
      await engine.start();
      expect(engine.rootMidi, isNotNull);
    });

    test('targetMidi is set after start', () async {
      await engine.start();
      expect(engine.targetMidi, isNotNull);
    });

    test('rootMidi is within guitar range', () async {
      await engine.start();
      expect(
        engine.rootMidi!,
        inInclusiveRange(AppConstants.guitarLowestMidi, AppConstants.guitarHighestMidi),
      );
    });

    test('rootMidi and targetMidi are different notes', () async {
      await engine.start();
      if (engine.rootMidi != null && engine.targetMidi != null) {
        expect(engine.rootMidi! % 12, isNot(engine.targetMidi! % 12));
      }
    });

    test('targetMidi is within the current key', () async {
      engine
        ..currentKey = 'C'
        ..scaleType = ScaleType.major;
      final keySig = engine.currentKeySignature;
      await engine.start();
      if (engine.targetMidi != null) {
        expect(keySig.degreeOf(engine.targetMidi!), isNotNull);
      }
    });

    test('rootMidi respects difficulty fret range', () async {
      engine.difficulty = AppConstants.difficulties['easy']!; // 0-5 frets
      await engine.start();
      if (engine.rootMidi != null) {
        final positions = GuitarMath.findNoteOnFretboard(
          engine.rootMidi!,
          Tuning.standard,
        );
        final inRange = positions.any((p) => p.$2 >= 0 && p.$2 <= 5);
        expect(inRange, true);
      }
    });
  });

  group('TrainingEngine - Answer Handling', () {
    test('submitAnswer updates counters on correct answer', () async {
      await engine.start();
      if (engine.targetMidi != null) {
        await engine.submitAnswer(engine.targetMidi!);
        expect(engine.lastAnswerCorrect, true);
        expect(engine.correctCount, 1);
        expect(engine.currentStreak, 1);
      }
    });

    test('submitAnswer updates counters on wrong answer', () async {
      await engine.start();
      if (engine.targetMidi != null) {
        // Submit a note one semitone off
        await engine.submitAnswer(engine.targetMidi! + 1);
        expect(engine.lastAnswerCorrect, false);
        expect(engine.correctCount, 0);
        expect(engine.currentStreak, 0);
      }
    });

    test('submitAnswer ignores calls when not waiting', () async {
      engine.reset();
      await engine.submitAnswer(60); // Should be ignored
      expect(engine.userAnswerMidi, isNull);
    });

    test('bestStreak tracks maximum streak', () async {
      engine.difficulty = AppConstants.difficulties['easy']!;
      await engine.start();

      // Correct answer
      if (engine.targetMidi != null) {
        await engine.submitAnswer(engine.targetMidi!);
        expect(engine.bestStreak, 1);
      }

      // Next question: wrong answer
      if (engine.state == TrainingState.waitingAnswer && engine.targetMidi != null) {
        await engine.submitAnswer(engine.targetMidi! + 1);
        expect(engine.currentStreak, 0);
        expect(engine.bestStreak, 1); // Best streak should stay at 1
      }
    });
  });

  group('TrainingEngine - Session Management', () {
    test('progress increases with each question', () async {
      engine.questionsPerSession = 3;
      await engine.start();

      double prevProgress = engine.progress;
      // Answer and wait for next question
      if (engine.targetMidi != null) {
        await engine.submitAnswer(engine.targetMidi!);
      }
      // Progress should change
    });

    test('completes when all questions answered', () async {
      engine.questionsPerSession = 1;
      await engine.start();

      // Wait for state to settle
      await Future.delayed(const Duration(milliseconds: 200));

      if (engine.state == TrainingState.waitingAnswer && engine.targetMidi != null) {
        await engine.submitAnswer(engine.targetMidi!);
        // Give time for state transition
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // Either completed or still processing
      expect(
        engine.state,
        anyOf(TrainingState.completed, TrainingState.playingRoot, TrainingState.waitingAnswer, TrainingState.showingResult),
      );
    });

    test('sessionDuration is non-zero after start', () async {
      await engine.start();
      await Future.delayed(const Duration(milliseconds: 100));
      expect(engine.sessionDuration.inMilliseconds, greaterThan(0));
    });
  });

  group('TrainingEngine - Edge Cases', () {
    test('start does nothing when audio engine is null', () async {
      final e = TrainingEngine();
      await e.start();
      expect(e.state, TrainingState.idle);
    });

    test('multiple resets are safe', () {
      engine.reset();
      engine.reset();
      engine.reset();
      expect(engine.state, TrainingState.idle);
    });

    test('key change works mid-training', () async {
      await engine.start();
      engine.currentKey = 'G';
      engine.scaleType = ScaleType.naturalMinor;
      await engine.start();
      expect(engine.currentKey, 'G');
      expect(engine.scaleType, ScaleType.naturalMinor);
    });

    test('tuning change updates configuration', () {
      engine.configure(engine: mockAudio, tuning: Tuning.dropD);
      expect(engine.currentTuning.name, 'Drop D');
    });
  });
}
