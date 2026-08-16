import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/guitar_math.dart';
import '../../core/theme.dart';
import '../../engine/training_engine.dart';
import '../../models/note.dart';
import '../../models/scale.dart';
import '../../models/training_question.dart';
import '../../models/tuning.dart';

/// A clean equal-width note matrix rather than a physical guitar drawing.
///
/// Every cell keeps the same width at every fret, so note names stay legible
/// and touch targets stay predictable on desktop, web and mobile.
class FretboardWidget extends StatefulWidget {
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
  State<FretboardWidget> createState() => _FretboardWidgetState();
}

class _FretboardWidgetState extends State<FretboardWidget> {
  late final ScrollController _scrollController;
  int _firstVisibleFret = 0;

  TrainingEngine get trainingEngine => widget.trainingEngine;
  Tuning get tuning => widget.tuning;
  ScaleType get scaleType => widget.scaleType;
  String get selectedKey => widget.selectedKey;
  bool get showDegrees => widget.showDegrees;
  bool get showNoteNames => widget.showNoteNames;
  bool get showFretNumbers => widget.showFretNumbers;
  ValueChanged<FretPosition> get onFretTapped => widget.onFretTapped;
  int get startFret => widget.startFret;
  int get visibleFrets => widget.visibleFrets;

  static const double _cellWidth = 58;
  static const double _rowHeight = 52;
  static const double _stringRailWidth = 68;
  static const double _headerHeight = 38;
  static const Set<int> _markerFrets = {3, 5, 7, 9, 12, 15, 17, 19, 21};

  @override
  void initState() {
    super.initState();
    _firstVisibleFret = startFret;
    _scrollController = ScrollController()..addListener(_updateVisibleRange);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_updateVisibleRange)
      ..dispose();
    super.dispose();
  }

  void _updateVisibleRange() {
    final first = startFret + (_scrollController.offset / _cellWidth).floor();
    if (first != _firstVisibleFret && mounted) {
      setState(() => _firstVisibleFret = first);
    }
  }

  Future<void> _scrollByFrets(int fretDelta) async {
    if (!_scrollController.hasClients) return;
    final target = (_scrollController.offset + fretDelta * _cellWidth).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    await _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final keySig = KeySignature(
      NoteName.values.firstWhere(
        (note) => note.sharpName == selectedKey || note.flatName == selectedKey,
        orElse: () => NoteName.c,
      ),
      scaleType,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final boardViewportWidth = math.max(
          _cellWidth,
          constraints.maxWidth - _stringRailWidth - 1,
        );
        final onScreenFrets = math.max(
          1,
          (boardViewportWidth / _cellWidth).floor(),
        );
        final lastVisibleFret = math.min(
          startFret + visibleFrets - 1,
          _firstVisibleFret + onScreenFrets - 1,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildNavigationBar(
              context,
              firstFret: _firstVisibleFret,
              lastFret: lastVisibleFret,
            ),
            const SizedBox(height: 8),
            ListenableBuilder(
              listenable: trainingEngine,
              builder: (context, _) {
                return DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppTheme.fretboardWood,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.outlineColor),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: SizedBox(
                      height: _headerHeight + tuning.stringCount * _rowHeight,
                      child: Row(
                        children: [
                          _buildStringRail(),
                          Container(width: 1, color: AppTheme.outlineColor),
                          Expanded(
                            child: ScrollConfiguration(
                              behavior: ScrollConfiguration.of(context)
                                  .copyWith(
                                    dragDevices: const {
                                      PointerDeviceKind.touch,
                                      PointerDeviceKind.mouse,
                                      PointerDeviceKind.stylus,
                                      PointerDeviceKind.trackpad,
                                    },
                                  ),
                              child: Scrollbar(
                                controller: _scrollController,
                                thumbVisibility: true,
                                interactive: true,
                                thickness: 5,
                                radius: const Radius.circular(99),
                                child: SingleChildScrollView(
                                  controller: _scrollController,
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
                                          _buildStringRow(
                                            context,
                                            stringIndex,
                                            keySig,
                                          ),
                                      ],
                                    ),
                                  ),
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
            ),
          ],
        );
      },
    );
  }

  Widget _buildNavigationBar(
    BuildContext context, {
    required int firstFret,
    required int lastFret,
  }) {
    final atStart = firstFret <= startFret;
    final atEnd = _scrollController.hasClients
        ? _scrollController.offset >=
              _scrollController.position.maxScrollExtent - 1
        : visibleFrets <= 1;
    return Container(
      height: 42,
      padding: const EdgeInsets.only(left: 12, right: 4),
      decoration: BoxDecoration(
        color: AppTheme.subtleSurfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outlineColor),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.pan_tool_alt_rounded,
            size: 16,
            color: AppTheme.secondaryColor,
          ),
          const SizedBox(width: 7),
          Text(
            '$firstFret–$lastFret 品',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 8),
          if (MediaQuery.sizeOf(context).width >= 430)
            const Expanded(
              child: Text(
                '拖动指板、滚动条，或使用箭头切换把位',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
              ),
            )
          else
            const Spacer(),
          IconButton(
            onPressed: atStart ? null : () => _scrollByFrets(-4),
            tooltip: '向低把位移动',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          IconButton(
            onPressed: atEnd ? null : () => _scrollByFrets(4),
            tooltip: '向高把位移动',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
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
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${stringIndex + 1}',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    GuitarMath.noteNameAt(
                      tuning.noteAt(stringIndex, 0),
                    ).sharpName,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
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
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (_markerFrets.contains(fret)) ...[
                            const SizedBox(width: 4),
                            Container(
                              width: fret == 12 ? 7 : 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                color: AppTheme.accentColor,
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
    final label = _noteLabel(position.midi, keySig, inKey);
    final stateColor = _stateColor(
      isRoot: isRoot,
      isAnswer: isAnswer,
      isRevealedTarget: isRevealedTarget,
    );
    final cellBackground = isRoot
        ? AppTheme.primaryColor.withAlpha(20)
        : isAnswer
        ? stateColor.withAlpha(20)
        : isRevealedTarget
        ? AppTheme.accentColor.withAlpha(24)
        : inKey
        ? AppTheme.surfaceColor.withAlpha(112)
        : Colors.transparent;

    return Semantics(
      button: true,
      label:
          '${stringIndex + 1}弦 $fret品，${GuitarMath.noteNameAt(position.midi).sharpName}',
      child: SizedBox(
        width: _cellWidth,
        height: _rowHeight,
        child: Material(
          color: cellBackground,
          child: InkWell(
            onTap: () => onFretTapped(position),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  child: Container(height: 1, color: AppTheme.stringColor),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: fret == 0
                              ? AppTheme.secondaryColor.withAlpha(100)
                              : AppTheme.outlineColor,
                          width: fret == 0 ? 2 : 1,
                        ),
                        bottom: const BorderSide(color: AppTheme.outlineColor),
                      ),
                    ),
                  ),
                ),
                if (label != null)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: isRoot || isAnswer || isRevealedTarget ? 38 : 32,
                    height: isRoot || isAnswer || isRevealedTarget ? 30 : 26,
                    decoration: BoxDecoration(
                      color: _nodeColor(
                        inKey: inKey,
                        isRoot: isRoot,
                        isAnswer: isAnswer,
                        isRevealedTarget: isRevealedTarget,
                      ),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: isRoot || isAnswer || isRevealedTarget
                            ? stateColor
                            : AppTheme.outlineColor.withAlpha(150),
                        width: isRoot || isAnswer || isRevealedTarget ? 1.5 : 1,
                      ),
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
    );
  }

  Color _stateColor({
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
    return AppTheme.secondaryColor;
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
    return inKey
        ? AppTheme.surfaceColor
        : AppTheme.raisedSurfaceColor.withAlpha(120);
  }

  Color _nodeTextColor({
    required bool isRoot,
    required bool isAnswer,
    required bool isRevealedTarget,
  }) {
    if (isRoot || isAnswer || isRevealedTarget) return Colors.white;
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
