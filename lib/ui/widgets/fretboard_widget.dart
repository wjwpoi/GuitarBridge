import 'package:flutter/material.dart';
import '../../models/note.dart';
import '../../models/scale.dart';
import '../../models/tuning.dart';
import '../../core/constants.dart';
import '../../core/guitar_math.dart';
import '../../core/theme.dart';
import '../../engine/training_engine.dart';

/// 吉他指板组件（对应原 Swift FretboardView.swift）
/// 可滚动、可点击的完整指板视图
class FretboardWidget extends StatelessWidget {
  final TrainingEngine trainingEngine;
  final Tuning tuning;
  final ScaleType scaleType;
  final String selectedKey;
  final bool showDegrees;
  final bool showNoteNames;
  final bool showFretNumbers;
  final void Function(int midiNote) onFretTapped;
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
    this.visibleFrets = 12,
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
      builder: (context, _) {
        return SizedBox(
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
              rootMidi: trainingEngine.rootMidi,
              targetMidi: trainingEngine.targetMidi,
              userAnswerMidi: trainingEngine.userAnswerMidi,
              lastAnswerCorrect: trainingEngine.lastAnswerCorrect,
            ),
            child: _buildTouchTargets(keySig),
          ),
        );
      },
    );
  }

  double _calculateHeight() {
    // 弦间距 36px * 6弦 + padding
    return 36.0 * tuning.stringCount + 40.0;
  }

  Widget _buildTouchTargets(KeySignature keySig) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final stringSpacing = (height - 20) / (tuning.stringCount - 1);

        return Stack(
          children: [
            for (int s = 0; s < tuning.stringCount; s++)
              for (int f = startFret; f < startFret + visibleFrets; f++)
                _buildFretButton(s, f, width, stringSpacing, keySig),
          ],
        );
      },
    );
  }

  Widget _buildFretButton(int stringIdx, int fret, double totalWidth,
      double stringSpacing, KeySignature keySig) {
    final midiNote = tuning.noteAt(stringIdx, fret);
    final positions =
        GuitarMath.findNoteOnFretboard(midiNote, tuning, maxFret: 22);

    // 只响应第一个位置，避免重复
    if (positions.isNotEmpty && positions.first != (stringIdx, fret)) {
      return const SizedBox.shrink();
    }

    final fretWidth = totalWidth / visibleFrets;
    final x = (fret - startFret) * fretWidth + fretWidth / 2;
    final y = 10 + stringIdx * stringSpacing;

    return Positioned(
      left: x - 16,
      top: y - 16,
      child: GestureDetector(
        onTap: () => onFretTapped(midiNote),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _buttonColor(midiNote, keySig),
            border: Border.all(
              color: _borderColor(midiNote),
              width: 1.5,
            ),
          ),
          child: Center(
            child: _buildButtonLabel(midiNote, keySig),
          ),
        ),
      ),
    );
  }

  Color _buttonColor(int midiNote, KeySignature keySig) {
    // 用户刚回答的位置
    if (trainingEngine.userAnswerMidi != null &&
        midiNote % 12 == trainingEngine.userAnswerMidi! % 12) {
      return trainingEngine.lastAnswerCorrect
          ? AppTheme.correctColor.withAlpha(180)
          : AppTheme.wrongColor.withAlpha(180);
    }
    // 调内音高亮，调外暗色
    return GuitarMath.isInKey(midiNote, keySig)
        ? Colors.blueGrey.withAlpha(100)
        : Colors.grey.withAlpha(40);
  }

  Color _borderColor(int midiNote) {
    // 目标音边框高亮
    if (trainingEngine.isWaitingAnswer &&
        trainingEngine.targetMidi != null &&
        midiNote % 12 == trainingEngine.targetMidi! % 12) {
      return AppTheme.accentColor;
    }
    return Colors.transparent;
  }

  Widget? _buildButtonLabel(int midiNote, KeySignature keySig) {
    final inKey = GuitarMath.isInKey(midiNote, keySig);
    if (!inKey && !showNoteNames) return null;

    final noteName = GuitarMath.noteNameAt(midiNote);
    final degree = keySig.degreeOf(midiNote);

    String label;
    if (showDegrees && degree != null) {
      label = ScaleDegree.values[degree - 1].roman;
    } else if (showNoteNames) {
      label = noteName.sharpName;
    } else {
      return null;
    }

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

/// 指板绘制器 - 使用 CustomPainter 实现物理品格间距
class _FretboardPainter extends CustomPainter {
  final Tuning tuning;
  final KeySignature keySignature;
  final bool showDegrees;
  final bool showNoteNames;
  final bool showFretNumbers;
  final int startFret;
  final int visibleFrets;
  final int? rootMidi;
  final int? targetMidi;
  final int? userAnswerMidi;
  final bool lastAnswerCorrect;

  _FretboardPainter({
    required this.tuning,
    required this.keySignature,
    required this.showDegrees,
    required this.showNoteNames,
    required this.showFretNumbers,
    required this.startFret,
    required this.visibleFrets,
    this.rootMidi,
    this.targetMidi,
    this.userAnswerMidi,
    this.lastAnswerCorrect = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawFretboard(canvas, size);
    _drawStrings(canvas, size);
    _drawFretMarkers(canvas, size);
  }

  void _drawFretboard(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF5D4037);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(4),
      ),
      paint,
    );
  }

  void _drawStrings(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1.5;

    final stringSpacing = (size.height - 20) / (tuning.stringCount - 1);

    for (int s = 0; s < tuning.stringCount; s++) {
      final y = 10 + s * stringSpacing;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawFretMarkers(Canvas canvas, Size size) {
    final fretPaint = Paint()
      ..color = AppTheme.fretMarkerColor
      ..strokeWidth = 1.0;

    for (int f = startFret; f <= startFret + visibleFrets; f++) {
      final ratio = GuitarMath.fretRatio(f);
      final x = size.width * ratio;

      // 品丝
      canvas.drawLine(
        Offset(x, 10),
        Offset(x, size.height - 10),
        fretPaint,
      );

      // 品数标记
      if (showFretNumbers && f % 2 == 0) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: '$f',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 8,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(x - 4, size.height - 16));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FretboardPainter oldDelegate) {
    return rootMidi != oldDelegate.rootMidi ||
        targetMidi != oldDelegate.targetMidi ||
        userAnswerMidi != oldDelegate.userAnswerMidi ||
        lastAnswerCorrect != oldDelegate.lastAnswerCorrect;
  }
}
