import 'package:flutter/material.dart';

import '../../core/guitar_math.dart';
import '../../core/theme.dart';
import '../../engine/training_engine.dart';
import '../../models/note.dart';
import '../../models/scale.dart';
import '../../models/training_question.dart';
import '../../models/tuning.dart';

/// Equal-width, platform-neutral fretboard interaction matrix.
///
/// This is intentionally not a physical guitar simulation. Equal columns keep
/// every note readable and every target comfortably tappable on every device.
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

  static const double _cellWidth = 56;
  static const double _rowHeight = 54;
  static const double _stringRailWidth = 48;
  static const double _headerHeight = 38;
  static const Set<int> _markerFrets = {3, 5, 7, 9, 12, 15, 17, 19, 21};

  @override
  Widget build(BuildContext context) {
    final keySig = KeySignature(
      NoteName.values.firstWhere(
        (note) => note.sharpName == selectedKey || note.flatName == selectedKey,
        orElse: () => NoteName.c,
      ),
      scaleType,
    );

    return ListenableBuilder(
      listenable: trainingEngine,
      builder: (context, _) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: AppTheme.subtleSurfaceColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.outlineColor),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(17),
            child: SizedBox(
              height: _headerHeight + tuning.stringCount * _rowHeight,
              child: Row(
                children: [
                  _buildStringRail(),
                  const VerticalDivider(width: 1, thickness: 1),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: visibleFrets * _cellWidth,
                        child: Column(
                          children: [
                            _buildFretHeader(),
                            for (
                              var stringIndex = 0;
                              stringIndex < tuning.stringCount;
                              stringIndex++
                            )
                              _buildStringRow(context, stringIndex, keySig),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStringRail() {
    return SizedBox(
      width: _stringRailWidth,
      child: Column(
        children: [
          const SizedBox(
            height: _headerHeight,
            child: Center(
              child: Text(
                '弦',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          for (
            var stringIndex = 0;
            stringIndex < tuning.stringCount;
            stringIndex++
          )
            SizedBox(
              height: _rowHeight,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${stringIndex + 1}',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      GuitarMath.noteNameAt(
                        tuning.noteAt(stringIndex, 0),
                      ).sharpName,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFretHeader() {
    return SizedBox(
      height: _headerHeight,
      child: Row(
        children: [
          for (var fret = startFret; fret < startFret + visibleFrets; fret++)
            SizedBox(
              width: _cellWidth,
              child: Center(
                child: showFretNumbers
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$fret',
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (_markerFrets.contains(fret)) ...[
                            const SizedBox(width: 4),
                            Container(
                              width: fret == 12 ? 8 : 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                color: AppTheme.secondaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      )
                    : null,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStringRow(
    BuildContext context,
    int stringIndex,
    KeySignature keySig,
  ) {
    return SizedBox(
      height: _rowHeight,
      child: Row(
        children: [
          for (var fret = startFret; fret < startFret + visibleFrets; fret++)
            _buildFretCell(context, stringIndex, fret, keySig),
        ],
      ),
    );
  }

  Widget _buildFretCell(
    BuildContext context,
    int stringIndex,
    int fret,
    KeySignature keySig,
  ) {
    final position = FretPosition.fromTuning(
      tuning: tuning,
      stringIndex: stringIndex,
      fret: fret,
    );
    final inKey = GuitarMath.isInKey(position.midi, keySig);
    final isRoot =
        (trainingEngine.state == TrainingState.playingRoot ||
            trainingEngine.state == TrainingState.waitingAnswer) &&
        trainingEngine.rootPosition == position;
    final isAnswer = trainingEngine.userAnswerPosition == position;
    final isRevealedTarget =
        trainingEngine.showCorrectPosition &&
        trainingEngine.targetMidi == position.midi;
    final nodeColor = _nodeColor(
      inKey: inKey,
      isRoot: isRoot,
      isAnswer: isAnswer,
      isRevealedTarget: isRevealedTarget,
    );
    final borderColor = isRoot
        ? AppTheme.primaryColor
        : isRevealedTarget
        ? AppTheme.accentColor
        : AppTheme.outlineColor;
    final label = _noteLabel(position.midi, keySig, inKey);

    return Semantics(
      button: true,
      label:
          '${stringIndex + 1}弦 $fret品，${GuitarMath.noteNameAt(position.midi).sharpName}',
      child: SizedBox(
        width: _cellWidth,
        height: _rowHeight,
        child: Material(
          color: isRoot
              ? AppTheme.primaryColor.withAlpha(10)
              : Colors.transparent,
          child: InkWell(
            onTap: () => onFretTapped(position),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: borderColor,
                    width: isRoot ? 1.5 : 1,
                  ),
                  bottom: const BorderSide(color: AppTheme.outlineColor),
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Positioned.fill(
                    child: Align(
                      alignment: Alignment.center,
                      child: Divider(
                        color: AppTheme.stringColor,
                        thickness: 1,
                        height: 1,
                      ),
                    ),
                  ),
                  if (label != null)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: isRoot || isAnswer || isRevealedTarget ? 34 : 30,
                      height: isRoot || isAnswer || isRevealedTarget ? 34 : 30,
                      decoration: BoxDecoration(
                        color: nodeColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isRoot || isRevealedTarget
                              ? borderColor
                              : AppTheme.outlineColor,
                          width: isRoot || isRevealedTarget ? 2 : 1,
                        ),
                        boxShadow: isRoot || isRevealedTarget
                            ? [
                                BoxShadow(
                                  color: borderColor.withAlpha(42),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          label,
                          style: TextStyle(
                            color: _nodeTextColor(
                              isRoot: isRoot,
                              isAnswer: isAnswer,
                              isRevealedTarget: isRevealedTarget,
                            ),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _nodeColor({
    required bool inKey,
    required bool isRoot,
    required bool isAnswer,
    required bool isRevealedTarget,
  }) {
    if (isAnswer) {
      return trainingEngine.lastAnswerCorrect
          ? AppTheme.correctColor
          : AppTheme.wrongColor;
    }
    if (isRoot) return AppTheme.primaryColor;
    if (isRevealedTarget) return AppTheme.accentColor;
    return inKey ? AppTheme.raisedSurfaceColor : AppTheme.subtleSurfaceColor;
  }

  Color _nodeTextColor({
    required bool isRoot,
    required bool isAnswer,
    required bool isRevealedTarget,
  }) {
    if (isRoot || isAnswer || isRevealedTarget) {
      return AppTheme.backgroundColor;
    }
    return AppTheme.textSecondary;
  }

  String? _noteLabel(int midi, KeySignature keySig, bool inKey) {
    if (!inKey && !showNoteNames) return null;
    final degree = keySig.degreeOf(midi);
    if (showDegrees && degree != null) {
      return ScaleDegree.values[degree - 1].roman;
    }
    if (showNoteNames) return GuitarMath.noteNameAt(midi).sharpName;
    return null;
  }
}
