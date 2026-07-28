import 'package:flutter/material.dart';

import '../../core/guitar_math.dart';
import '../../core/theme.dart';
import '../../engine/training_engine.dart';
import '../../models/note.dart';
import '../../models/scale.dart';
import '../../models/training_question.dart';
import '../../models/tuning.dart';

/// Complete, tappable 0-22 fretboard.
class FretboardWidget extends StatelessWidget {
  final TrainingEngine trainingEngine;
  final Tuning tuning;
  final ScaleType scaleType;
  final String selectedKey;
  final bool showDegrees;
  final bool showNoteNames;
  final bool showFretNumbers;
  final ValueChanged<FretPosition> onFretTapped;
  final int startFret;
  final int visibleFrets;

  const FretboardWidget({
    super.key,
    required this.trainingEngine,
    required this.tuning,
    required this.scaleType,
    required this.selectedKey,
    this.showDegrees = false,
    this.showNoteNames = true,
    this.showFretNumbers = true,
    required this.onFretTapped,
    this.startFret = 0,
    this.visibleFrets = 23,
  });

  @override
  Widget build(BuildContext context) {
    final keySig = KeySignature(
      NoteName.values.firstWhere(
        (n) => n.sharpName == selectedKey || n.flatName == selectedKey,
        orElse: () => NoteName.c,
      ),
      scaleType,
    );

    return ListenableBuilder(
      listenable: trainingEngine,
      builder: (context, _) => LayoutBuilder(
        builder: (context, constraints) {
          final boardWidth = constraints.maxWidth > visibleFrets * 56.0
              ? constraints.maxWidth
              : visibleFrets * 56.0;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: boardWidth,
              height: _calculateHeight(),
              child: CustomPaint(
                painter: _FretboardPainter(
                  tuning: tuning,
                  keySignature: keySig,
                  showDegrees: showDegrees,
                  showNoteNames: showNoteNames,
                  showFretNumbers: showFretNumbers,
                  startFret: startFret,
                  visibleFrets: visibleFrets,
                  rootPosition: trainingEngine.rootPosition,
                  targetPosition: trainingEngine.targetPosition,
                  userAnswerPosition: trainingEngine.userAnswerPosition,
                  state: trainingEngine.state,
                  lastAnswerCorrect: trainingEngine.lastAnswerCorrect,
                ),
                child: _buildTouchTargets(keySig),
              ),
            ),
          );
        },
      ),
    );
  }

  double _calculateHeight() => 36.0 * tuning.stringCount + 40.0;

  Widget _buildTouchTargets(KeySignature keySig) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stringSpacing =
            (constraints.maxHeight - 20) / (tuning.stringCount - 1);
        return Stack(
          children: [
            for (
              var stringIndex = 0;
              stringIndex < tuning.stringCount;
              stringIndex++
            )
              for (
                var fret = startFret;
                fret < startFret + visibleFrets;
                fret++
              )
                _buildFretButton(
                  stringIndex,
                  fret,
                  constraints.maxWidth,
                  stringSpacing,
                  keySig,
                ),
          ],
        );
      },
    );
  }

  Widget _buildFretButton(
    int stringIndex,
    int fret,
    double width,
    double stringSpacing,
    KeySignature keySig,
  ) {
    final position = FretPosition.fromTuning(
      tuning: tuning,
      stringIndex: stringIndex,
      fret: fret,
    );
    final x = _fretCenterX(fret, width);
    final y = 10 + stringIndex * stringSpacing;
    return Positioned(
      left: x - 16,
      top: y - 16,
      child: GestureDetector(
        onTap: () => onFretTapped(position),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _buttonColor(position, keySig),
            border: Border.all(color: _borderColor(position), width: 1.5),
          ),
          child: Center(child: _buildButtonLabel(position.midi, keySig)),
        ),
      ),
    );
  }

  double _fretBoundaryX(int fret, double width) {
    final start = GuitarMath.fretRatio(startFret);
    final end = GuitarMath.fretRatio(startFret + visibleFrets);
    final ratio = (GuitarMath.fretRatio(fret) - start) / (end - start);
    return ratio.clamp(0.0, 1.0).toDouble() * width;
  }

  double _fretCenterX(int fret, double width) {
    return (_fretBoundaryX(fret, width) + _fretBoundaryX(fret + 1, width)) / 2;
  }

  Color _buttonColor(FretPosition position, KeySignature keySig) {
    if (trainingEngine.userAnswerPosition == position) {
      return trainingEngine.lastAnswerCorrect
          ? AppTheme.correctColor.withAlpha(180)
          : AppTheme.wrongColor.withAlpha(180);
    }
    return GuitarMath.isInKey(position.midi, keySig)
        ? Colors.blueGrey.withAlpha(100)
        : Colors.grey.withAlpha(40);
  }

  Color _borderColor(FretPosition position) {
    // The target is intentionally never shown while the user is answering.
    if (trainingEngine.state == TrainingState.playingRoot &&
        trainingEngine.rootPosition == position) {
      return AppTheme.accentColor;
    }
    return Colors.transparent;
  }

  Widget? _buildButtonLabel(int midi, KeySignature keySig) {
    final inKey = GuitarMath.isInKey(midi, keySig);
    if (!inKey && !showNoteNames) return null;
    final degree = keySig.degreeOf(midi);
    final label = showDegrees && degree != null
        ? ScaleDegree.values[degree - 1].roman
        : showNoteNames
        ? GuitarMath.noteNameAt(midi).sharpName
        : null;
    if (label == null) return null;
    return Text(
      label,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: inKey ? Colors.white : Colors.white54,
      ),
    );
  }
}

class _FretboardPainter extends CustomPainter {
  final Tuning tuning;
  final KeySignature keySignature;
  final bool showDegrees;
  final bool showNoteNames;
  final bool showFretNumbers;
  final int startFret;
  final int visibleFrets;
  final FretPosition? rootPosition;
  final FretPosition? targetPosition;
  final FretPosition? userAnswerPosition;
  final TrainingState state;
  final bool lastAnswerCorrect;

  _FretboardPainter({
    required this.tuning,
    required this.keySignature,
    required this.showDegrees,
    required this.showNoteNames,
    required this.showFretNumbers,
    required this.startFret,
    required this.visibleFrets,
    this.rootPosition,
    this.targetPosition,
    this.userAnswerPosition,
    required this.state,
    this.lastAnswerCorrect = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final boardPaint = Paint()..color = const Color(0xFF5D4037);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(4),
      ),
      boardPaint,
    );

    final stringPaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1.5;
    final stringSpacing = (size.height - 20) / (tuning.stringCount - 1);
    for (var stringIndex = 0; stringIndex < tuning.stringCount; stringIndex++) {
      final y = 10 + stringIndex * stringSpacing;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), stringPaint);
    }

    final fretPaint = Paint()
      ..color = AppTheme.fretMarkerColor
      ..strokeWidth = 1.0;
    final start = GuitarMath.fretRatio(startFret);
    final end = GuitarMath.fretRatio(startFret + visibleFrets);
    for (var fret = startFret; fret <= startFret + visibleFrets; fret++) {
      final ratio = (GuitarMath.fretRatio(fret) - start) / (end - start);
      final x = size.width * ratio.clamp(0.0, 1.0).toDouble();
      canvas.drawLine(Offset(x, 10), Offset(x, size.height - 10), fretPaint);
      if (showFretNumbers && fret % 2 == 0) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: '$fret',
            style: const TextStyle(color: Colors.white54, fontSize: 8),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(canvas, Offset(x - 4, size.height - 16));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FretboardPainter oldDelegate) {
    return tuning != oldDelegate.tuning ||
        keySignature != oldDelegate.keySignature ||
        showDegrees != oldDelegate.showDegrees ||
        showNoteNames != oldDelegate.showNoteNames ||
        showFretNumbers != oldDelegate.showFretNumbers ||
        startFret != oldDelegate.startFret ||
        visibleFrets != oldDelegate.visibleFrets ||
        rootPosition != oldDelegate.rootPosition ||
        targetPosition != oldDelegate.targetPosition ||
        userAnswerPosition != oldDelegate.userAnswerPosition ||
        state != oldDelegate.state ||
        lastAnswerCorrect != oldDelegate.lastAnswerCorrect;
  }
}
