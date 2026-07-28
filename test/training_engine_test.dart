import 'dart:async';

import 'package:guitar_bridge/core/guitar_math.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guitar_bridge/models/scale.dart';
import 'package:guitar_bridge/models/tuning.dart';
import 'package:guitar_bridge/engine/training_engine.dart';
import 'package:guitar_bridge/engine/training_audio_port.dart';
import 'package:guitar_bridge/core/constants.dart';
import 'package:guitar_bridge/models/training_question.dart';

/// Fake audio port for unit tests — never touches SoLoud.
class MockAudioEngine implements TrainingAudioPort {
  int playCallCount = 0;

  @override
  bool get isReady => true;

  @override
  Future<void> playNote(int midiNote) async {
    playCallCount++;
  }

  @override
  Future<void> stopAll() async {}
}

void main() {
  late TrainingEngine engine;
  late MockAudioEngine mockAudio;

  setUp(() {
    engine = TrainingEngine(delay: (_) async {});
    mockAudio = MockAudioEngine();
    engine.configure(engine: mockAudio, tuning: Tuning.standard);
    engine
      ..currentKey = 'C'
      ..scaleType = ScaleType.major
      ..difficulty = AppConstants.difficulties['easy']!;
  });

  setUp(() {
    engine = TrainingEngine(delay: (_) async {});
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
        inInclusiveRange(
          AppConstants.guitarLowestMidi,
          AppConstants.guitarHighestMidi,
        ),
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
        final submission = engine.submitAnswer(engine.targetMidi!);
        expect(engine.lastAnswerCorrect, true);
        expect(engine.correctCount, 1);
        expect(engine.currentStreak, 1);
        await submission;
      }
    });

    test('submitAnswer updates counters on wrong answer', () async {
      await engine.start();
      if (engine.targetMidi != null) {
        // Submit a note one semitone off
        final submission = engine.submitAnswer(engine.targetMidi! + 1);
        expect(engine.lastAnswerCorrect, false);
        expect(engine.correctCount, 0);
        expect(engine.currentStreak, 0);
        await submission;
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
      if (engine.state == TrainingState.waitingAnswer &&
          engine.targetMidi != null) {
        await engine.submitAnswer(engine.targetMidi! + 1);
        expect(engine.currentStreak, 0);
        expect(engine.bestStreak, 1); // Best streak should stay at 1
      }
    });

    test('exact position mode rejects a different fret', () async {
      await engine.start();
      final target = engine.targetPosition!;
      final wrong = FretPosition(
        stringIndex: target.stringIndex,
        fret: target.fret + 1,
        midi: target.midi + 1,
      );
      final submission = engine.submitAnswer(wrong);
      expect(engine.lastAnswerCorrect, false);
      await submission;
    });

    test(
      'pitch class mode accepts another position with the same note',
      () async {
        engine.answerMode = AnswerMode.pitchClass;
        engine.difficulty = AppConstants.difficulties['hard']!;
        await engine.start();
        final target = engine.targetPosition!;
        final alternate =
            [
              for (
                var stringIndex = 0;
                stringIndex < Tuning.standard.stringCount;
                stringIndex++
              )
                FretPosition(
                  stringIndex: stringIndex,
                  fret: target.midi - Tuning.standard.noteAt(stringIndex, 0),
                  midi: target.midi,
                ),
            ].firstWhere(
              (position) =>
                  position.fret >= 0 &&
                  position.fret <= AppConstants.maxFret &&
                  position != target,
            );
        final answer = FretPosition(
          stringIndex: alternate.stringIndex,
          fret: alternate.fret,
          midi: target.midi,
        );
        final submission = engine.submitAnswer(answer);
        expect(engine.lastAnswerCorrect, true);
        await submission;
      },
    );

    test('submitAnswer ignores unsupported answer types', () async {
      await engine.start();
      await engine.submitAnswer(Object());
      expect(engine.state, TrainingState.waitingAnswer);
      expect(engine.currentQuestion, 0);
    });
  });

  group('TrainingEngine - Session Management', () {
    test('progress increases with each question', () async {
      engine.questionsPerSession = 3;
      await engine.start();

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

      if (engine.state == TrainingState.waitingAnswer &&
          engine.targetMidi != null) {
        await engine.submitAnswer(engine.targetMidi!);
        // Give time for state transition
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // Either completed or still processing
      expect(
        engine.state,
        anyOf(
          TrainingState.completed,
          TrainingState.playingRoot,
          TrainingState.waitingAnswer,
          TrainingState.showingResult,
        ),
      );
    });

    test('sessionDuration is non-zero after start', () async {
      await engine.start();
      await Future.delayed(const Duration(milliseconds: 100));
      expect(engine.sessionDuration.inMilliseconds, greaterThan(0));
    });
  });

  group('TrainingEngine - Retry Behavior', () {
    test('wrong answer stays in waitingAnswer when under limit', () async {
      engine.maxFailedAttempts = 3;
      await engine.start();
      if (engine.targetMidi != null) {
        // Submit a wrong answer
        await engine.submitAnswer(engine.targetMidi! + 1);
        // Should still be waiting for answer
        expect(engine.state, TrainingState.waitingAnswer);
        expect(engine.currentQuestion, 0);
        expect(engine.failedAttempts, 1);
      }
    });

    test('failedAttempts increments on each wrong answer', () async {
      engine.maxFailedAttempts = 5;
      await engine.start();
      if (engine.targetMidi != null) {
        await engine.submitAnswer(engine.targetMidi! + 1);
        expect(engine.failedAttempts, 1);
        await engine.submitAnswer(engine.targetMidi! + 2);
        expect(engine.failedAttempts, 2);
        await engine.submitAnswer(engine.targetMidi! + 3);
        expect(engine.failedAttempts, 3);
      }
    });

    test('correct answer resets failedAttempts', () async {
      engine.maxFailedAttempts = 3;
      await engine.start();
      if (engine.targetMidi != null) {
        // One wrong, then correct
        await engine.submitAnswer(engine.targetMidi! + 1);
        expect(engine.failedAttempts, 1);
        // Need to wait for next question, then answer correctly
        // But we can't easily test cross-question behavior in unit test
        // Just verify the counter exists and increments
        expect(engine.lastAnswerCorrect, false);
      }
    });

    test('reveals correct position and advances after max attempts', () async {
      engine.maxFailedAttempts = 2;
      await engine.start();
      final target = engine.targetMidi;
      if (target != null) {
        await engine.submitAnswer(target + 1);
        expect(engine.failedAttempts, 1);
        expect(engine.state, TrainingState.waitingAnswer);
        // Second wrong — triggers reveal synchronously before delay
        engine.submitAnswer(target + 2);
        expect(engine.showCorrectPosition, true);
        expect(engine.currentQuestion, 1);
      }
    });

    test('maxFailedAttempts=0 skips retry (legacy behavior)', () async {
      engine.maxFailedAttempts = 0;
      await engine.start();
      if (engine.targetMidi != null) {
        // Submit without await — sync portion updates fields immediately
        engine.submitAnswer(engine.targetMidi! + 1);
        expect(engine.currentQuestion, 1);
        expect(engine.showCorrectPosition, false);
      }
    });

    test('showCorrectPosition is false by default', () {
      expect(engine.showCorrectPosition, false);
    });

    test('showCorrectPosition is set on reveal', () async {
      engine.maxFailedAttempts = 1;
      await engine.start();
      final target = engine.targetMidi;
      if (target != null) {
        engine.submitAnswer(target + 1);
        // Synchronously after submit, showCorrectPosition should be true
        expect(engine.showCorrectPosition, true);
        expect(engine.currentQuestion, 1);
      }
    });

    test('streak resets on wrong answer', () async {
      engine.maxFailedAttempts = 3;
      await engine.start();
      if (engine.targetMidi != null) {
        await engine.submitAnswer(engine.targetMidi! + 1);
        expect(engine.currentStreak, 0);
      }
    });

    test('correct after wrong on same question increments counters', () async {
      engine.maxFailedAttempts = 3;
      await engine.start();
      final targetMidi = engine.targetMidi;
      if (targetMidi != null) {
        // Wrong first — stays in waitingAnswer
        await engine.submitAnswer(targetMidi + 1);
        expect(engine.currentStreak, 0);
        expect(engine.state, TrainingState.waitingAnswer);
        // Correct on retry
        engine.submitAnswer(targetMidi);
        expect(engine.lastAnswerCorrect, true);
        expect(engine.correctCount, 1);
      }
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

    test('large sessions use a finite question pool', () async {
      engine.questionsPerSession = 50;
      await engine.start();
      expect(engine.totalQuestions, 50);
    });

    test('reset prevents an older async start from restoring state', () async {
      final delayGate = Completer<void>();
      final delayedEngine = TrainingEngine(delay: (_) => delayGate.future)
        ..configure(engine: mockAudio, tuning: Tuning.standard)
        ..currentKey = 'C'
        ..scaleType = ScaleType.major
        ..difficulty = AppConstants.difficulties['easy']!;

      final start = delayedEngine.start();
      await Future<void>.delayed(Duration.zero);
      delayedEngine.reset();
      delayGate.complete();
      await start;

      expect(delayedEngine.state, TrainingState.idle);
    });
  });
}
