import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guitar_bridge/core/constants.dart';
import 'package:guitar_bridge/engine/training_audio_port.dart';
import 'package:guitar_bridge/engine/training_engine.dart';
import 'package:guitar_bridge/models/scale.dart';
import 'package:guitar_bridge/models/training_question.dart';
import 'package:guitar_bridge/models/tuning.dart';
import 'package:guitar_bridge/ui/widgets/fretboard_widget.dart';

class BoardAudio implements TrainingAudioPort {
  bool gated = false;
  final List<Completer<bool>> cues = [];
  @override
  bool get isReady => true;
  @override
  Future<bool> playNote(int midi) async {
    if (!gated) return true;
    final gate = Completer<bool>();
    cues.add(gate);
    return gate.future;
  }

  @override
  Future<void> stopAll() async {}
}

Widget board(
  TrainingEngine engine,
  ValueChanged<FretPosition> onTap, {
  bool names = true,
  bool degrees = false,
}) => MaterialApp(
  home: Scaffold(
    body: SizedBox(
      width: 390,
      child: FretboardWidget(
        trainingEngine: engine,
        tuning: Tuning.standard,
        scaleType: ScaleType.major,
        selectedKey: 'C',
        showNoteNames: names,
        showDegrees: degrees,
        onFretTapped: onTap,
      ),
    ),
  ),
);

void main() {
  testWidgets(
    'scrolling and label toggles preserve physical fret/MIDI mapping',
    (tester) async {
      final engine = TrainingEngine();
      addTearDown(engine.dispose);
      final answers = <FretPosition>[];
      await tester.pumpWidget(board(engine, answers.add));
      await tester.tap(find.byKey(const ValueKey('fret:0:0')));
      expect(answers.single.midi, 64);
      await tester.pumpWidget(
        board(engine, answers.add, names: false, degrees: true),
      );
      final highFret = find.byKey(const ValueKey('fret:1:12'));
      await tester.ensureVisible(highFret);
      await tester.pumpAndSettle();
      await tester.tap(highFret);
      expect(
        answers.last,
        FretPosition.fromTuning(
          tuning: Tuning.standard,
          stringIndex: 1,
          fret: 12,
        ),
      );
      expect(answers.last.midi, 71);
    },
  );

  testWidgets('both question cues disable audition, then answer taps work', (
    tester,
  ) async {
    final audio = BoardAudio()..gated = true;
    final engine = TrainingEngine(delay: (_) async {})
      ..configure(engine: audio, tuning: Tuning.standard);
    var tapped = 0;
    await tester.pumpWidget(board(engine, (_) => tapped++));
    final start = engine.start();
    await tester.pump();
    final cell = find.byKey(const ValueKey('fret:0:0'));
    await tester.tap(cell);
    expect(tapped, 0);
    audio.cues[0].complete(true);
    await tester.pump();
    expect(audio.cues, hasLength(2));
    await tester.tap(cell);
    expect(tapped, 0);
    audio.cues[1].complete(true);
    await tester.pump();
    await start;
    expect(engine.state, TrainingState.waitingAnswer);
    await tester.tap(cell);
    expect(tapped, 1);
    await tester.pumpWidget(const SizedBox());
    engine.dispose();
  });

  testWidgets('a real equivalent position on another string is accepted', (
    tester,
  ) async {
    final result = Completer<void>();
    final engine =
        TrainingEngine(
            delay: (duration) => duration.inMilliseconds == 1200
                ? result.future
                : Future<void>.value(),
          )
          ..configure(engine: BoardAudio(), tuning: Tuning.standard)
          ..difficulty = const DifficultyConfig(
            fretRange: (0, 12),
            stringRange: (0, 1),
            allowedIntervals: [7],
            showHint: false,
          );
    await engine.start();
    final target = engine.targetPosition!;
    final alternate = Tuning.standard
        .findNotePositions(target.midi)
        .firstWhere(
          (position) => position != (target.stringIndex, target.fret),
        );
    Future<void>? submission;
    await tester.pumpWidget(
      board(engine, (position) {
        submission = engine.submitAnswer(position);
      }),
    );
    final cell = find.byKey(ValueKey('fret:${alternate.$1}:${alternate.$2}'));
    await tester.ensureVisible(cell);
    await tester.pumpAndSettle();
    await tester.tap(cell);
    expect(engine.lastAnswerCorrect, true);
    expect(engine.userAnswerPosition!.midi, target.midi);
    expect(engine.userAnswerPosition!.stringIndex, alternate.$1);
    engine.reset();
    result.complete();
    await submission;
    await tester.pumpWidget(const SizedBox());
    engine.dispose();
  });
}
