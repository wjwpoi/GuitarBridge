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
/// Cells share one width that stretches to fit the whole neck when there is
/// room (desktop) and falls back to horizontal scrolling with a 44 px minimum
/// touch target on narrow screens. When a new question starts the board
/// scrolls so the root note is visible.
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

  /// Fret range the current questions are drawn from. Frets outside it are
  /// dimmed during a session (answers there are still accepted).
  final (int, int)? focusFretRange;

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
    this.focusFretRange,
  });

  static const double minCellWidth = 44;
  static const double maxCellWidth = 64;

  @override
  State<FretboardWidget> createState() => _FretboardWidgetState();
}

class _FretboardWidgetState extends State<FretboardWidget> {
  late final ScrollController _scrollController;
  int _firstVisibleFret = 0;
  double _cellWidth = FretboardWidget.minCellWidth;
  int _onScreenFrets = 1;
  TrainingQuestion? _lastQuestion;
  TrainingState? _lastState;

  TrainingEngine get engine => widget.trainingEngine;
  Tuning get tuning => widget.tuning;
  int get startFret => widget.startFret;
  int get visibleFrets => widget.visibleFrets;

  static const double _rowHeight = 46;
  static const double _headerHeight = 30;
  static const Set<int> _markerFrets = {3, 5, 7, 9, 12, 15, 17, 19, 21};

  @override
  void initState() {
    super.initState();
    _firstVisibleFret = startFret;
    _scrollController = ScrollController()..addListener(_updateVisibleRange);
    engine.addListener(_onEngineChanged);
  }

  @override
  void didUpdateWidget(covariant FretboardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.trainingEngine, engine)) {
      oldWidget.trainingEngine.removeListener(_onEngineChanged);
      engine.addListener(_onEngineChanged);
    }
  }

  @override
  void dispose() {
    engine.removeListener(_onEngineChanged);
    _scrollController
      ..removeListener(_updateVisibleRange)
      ..dispose();
    super.dispose();
  }

  void _onEngineChanged() {
    final question = engine.activeQuestion;
    final state = engine.state;
    if (question != null && !identical(question, _lastQuestion)) {
      _ensureFretVisible(question.root.fret);
    } else if (state == TrainingState.showingResult &&
        _lastState != TrainingState.showingResult &&
        engine.showCorrectPosition &&
        question != null) {
      // Bring a placement of the target into view if none is visible.
      final placements = tuning
          .findNotePositions(question.target.midi, maxFret: _lastFret)
          .map((p) => p.$2)
          .toList();
      final anyVisible = placements.any(_isFretVisible);
      if (!anyVisible && placements.isNotEmpty) {
        _ensureFretVisible(placements.reduce(math.min));
      }
    }
    _lastQuestion = question;
    _lastState = state;
  }

  int get _lastFret => startFret + visibleFrets - 1;

  bool _isFretVisible(int fret) =>
      fret >= _firstVisibleFret && fret < _firstVisibleFret + _onScreenFrets;

  void _ensureFretVisible(int fret) {
    if (_isFretVisible(fret)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final target = ((fret - startFret - 1) * _cellWidth).clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _updateVisibleRange() {
    final first =
        startFret + (_scrollController.offset / _cellWidth + 0.01).floor();
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
        (note) =>
            note.sharpName == widget.selectedKey ||
            note.flatName == widget.selectedKey,
        orElse: () => NoteName.c,
      ),
      widget.scaleType,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final railWidth = constraints.maxWidth < 520 ? 38.0 : 50.0;
        final viewport = math.max(
          FretboardWidget.minCellWidth,
          constraints.maxWidth - railWidth - 1,
        );
        _cellWidth = (viewport / visibleFrets).clamp(
          FretboardWidget.minCellWidth,
          FretboardWidget.maxCellWidth,
        );
        final fitsAll = _cellWidth * visibleFrets <= viewport + 0.5;
        _onScreenFrets = math.max(1, (viewport / _cellWidth + 0.01).floor());
        final lastVisibleFret = math.min(
          _lastFret,
          _firstVisibleFret + _onScreenFrets - 1,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!fitsAll) ...[
              _buildNavigationBar(
                context,
                firstFret: _firstVisibleFret,
                lastFret: lastVisibleFret,
              ),
              const SizedBox(height: 8),
            ],
            ListenableBuilder(
              listenable: engine,
              builder: (context, _) {
                final board = SizedBox(
                  width: visibleFrets * _cellWidth,
                  child: Column(
                    children: [
                      _buildFretHeader(),
                      for (
                        var stringIndex = 0;
                        stringIndex < tuning.stringCount;
                        stringIndex++
                      )
                        _buildStringRow(stringIndex, keySig),
                    ],
                  ),
                );
                return DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppTheme.fretboardWood,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.outlineColor),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: SizedBox(
                      height: _headerHeight + tuning.stringCount * _rowHeight,
                      child: Row(
                        children: [
                          _buildStringRail(railWidth),
                          Container(width: 1, color: AppTheme.outlineColor),
                          Expanded(
                            child: fitsAll
                                ? Align(
                                    alignment: Alignment.centerLeft,
                                    child: board,
                                  )
                                : ScrollConfiguration(
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
                                      thickness: 4,
                                      radius: const Radius.circular(99),
                                      child: SingleChildScrollView(
                                        controller: _scrollController,
                                        scrollDirection: Axis.horizontal,
                                        child: board,
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
    return Row(
      children: [
        Text(
          '$firstFret–$lastFret 品',
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            '左右拖动查看更多品位',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
          ),
        ),
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
    );
  }

  Widget _buildStringRail(double width) {
    return SizedBox(
      width: width,
      child: Column(
        children: [
          const SizedBox(height: _headerHeight),
          for (
            var stringIndex = 0;
            stringIndex < tuning.stringCount;
            stringIndex++
          )
            SizedBox(
              height: _rowHeight,
              child: Center(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${stringIndex + 1}',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextSpan(
                        text:
                            ' ${GuitarMath.noteNameAt(tuning.noteAt(stringIndex, 0)).sharpName}',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _inFocus(int fret) {
    final range = widget.focusFretRange;
    if (range == null || !engine.isSessionActive) return true;
    return fret >= range.$1 && fret <= range.$2;
  }

  Widget _buildFretHeader() {
    return SizedBox(
      height: _headerHeight,
      child: Row(
        children: [
          for (var fret = startFret; fret <= _lastFret; fret++)
            SizedBox(
              width: _cellWidth,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.showFretNumbers)
                      Text(
                        '$fret',
                        style: TextStyle(
                          color: _inFocus(fret)
                              ? AppTheme.textSecondary
                              : AppTheme.textMuted.withAlpha(140),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    if (_markerFrets.contains(fret)) ...[
                      if (widget.showFretNumbers) const SizedBox(width: 3),
                      for (var dot = 0; dot < (fret == 12 ? 2 : 1); dot++)
                        Container(
                          width: 5,
                          height: 5,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: const BoxDecoration(
                            color: AppTheme.fretMarkerColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStringRow(int stringIndex, KeySignature keySig) {
    return SizedBox(
      height: _rowHeight,
      child: Row(
        children: [
          for (var fret = startFret; fret <= _lastFret; fret++)
            _buildFretCell(stringIndex, fret, keySig),
        ],
      ),
    );
  }

  Widget _buildFretCell(int stringIndex, int fret, KeySignature keySig) {
    final position = FretPosition.fromTuning(
      tuning: tuning,
      stringIndex: stringIndex,
      fret: fret,
    );
    final state = engine.state;
    final inKey = GuitarMath.isInKey(position.midi, keySig);
    final inFocus = _inFocus(fret);
    final questionVisible =
        state == TrainingState.playingRoot ||
        state == TrainingState.waitingAnswer ||
        state == TrainingState.showingResult;

    final role = _roleFor(position, questionVisible);
    final label = _noteLabel(position.midi, keySig, inKey);
    final highlighted = role != _CellRole.none;
    final roleColor = _roleColor(role);

    final semanticsState = switch (role) {
      _CellRole.root => '，基准音',
      _CellRole.correct => '，正确',
      _CellRole.wrong => '，已尝试',
      _CellRole.target => '，目标音',
      _CellRole.none => '',
    };

    return Semantics(
      button: true,
      label:
          '${stringIndex + 1}弦 $fret品，${GuitarMath.noteLabel(position.midi)}$semanticsState',
      child: SizedBox(
        width: _cellWidth,
        height: _rowHeight,
        child: Material(
          color: !inFocus
              ? AppTheme.backgroundColor.withAlpha(150)
              : inKey
              ? AppTheme.surfaceColor.withAlpha(90)
              : Colors.transparent,
          child: InkWell(
            onTap: () => widget.onFretTapped(position),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 1 + (stringIndex * 0.25),
                    color: AppTheme.stringColor.withAlpha(inFocus ? 200 : 110),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: fret == 0
                              ? AppTheme.textSecondary.withAlpha(140)
                              : AppTheme.outlineColor,
                          width: fret == 0 ? 3 : 1,
                        ),
                      ),
                    ),
                  ),
                ),
                if (label != null || highlighted || inKey)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: highlighted ? 36 : (inKey ? 30 : 22),
                    height: highlighted ? 30 : (inKey ? 24 : 18),
                    decoration: BoxDecoration(
                      color: highlighted
                          ? roleColor
                          : inKey
                          ? AppTheme.surfaceColor
                          : AppTheme.raisedSurfaceColor.withAlpha(150),
                      borderRadius: BorderRadius.circular(highlighted ? 10 : 8),
                      border: Border.all(
                        color: highlighted
                            ? roleColor
                            : AppTheme.outlineColor.withAlpha(inKey ? 200 : 90),
                      ),
                      boxShadow: highlighted
                          ? [
                              BoxShadow(
                                color: roleColor.withAlpha(70),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: role == _CellRole.wrong && label == null
                          ? const Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: Colors.white,
                            )
                          : Text(
                              label ?? '',
                              style: TextStyle(
                                color: highlighted
                                    ? Colors.white
                                    : inKey
                                    ? AppTheme.textSecondary
                                    : AppTheme.textMuted,
                                fontSize: inKey || highlighted ? 10.5 : 9,
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

  _CellRole _roleFor(FretPosition position, bool questionVisible) {
    if (!questionVisible) return _CellRole.none;
    final state = engine.state;
    final resolved = state == TrainingState.showingResult;
    if (resolved &&
        engine.showCorrectPosition &&
        engine.targetMidi == position.midi) {
      return engine.lastAnswerCorrect && engine.userAnswerPosition == position
          ? _CellRole.correct
          : _CellRole.target;
    }
    if (engine.rootPosition == position) return _CellRole.root;
    if (engine.wrongPositions.contains(position)) return _CellRole.wrong;
    return _CellRole.none;
  }

  Color _roleColor(_CellRole role) => switch (role) {
    _CellRole.root => AppTheme.primaryColor,
    _CellRole.correct => AppTheme.correctColor,
    _CellRole.wrong => AppTheme.wrongColor,
    _CellRole.target => AppTheme.correctColor,
    _CellRole.none => AppTheme.secondaryColor,
  };

  String? _noteLabel(int midi, KeySignature keySig, bool inKey) {
    final degree = keySig.degreeLabel(midi);
    if (widget.showDegrees && degree != null) return degree;
    if (widget.showNoteNames) return GuitarMath.noteNameAt(midi).sharpName;
    return null;
  }
}

enum _CellRole { none, root, correct, wrong, target }
