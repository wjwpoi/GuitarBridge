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
import 'common.dart';

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

  /// False hides every scale-note marker and draws only the fret inlays of a
  /// real guitar (3, 5, 7, 9, 12…), so positions must be found by orientation.
  /// The root, attempted frets and the revealed answer stay highlighted.
  final bool showScaleNotes;
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
    this.showScaleNotes = true,
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
  int get _lastFret => startFret + visibleFrets - 1;

  static const double _rowHeight = 46;
  static const double _headerHeight = 28;
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
      if (placements.isNotEmpty && !placements.any(_isFretVisible)) {
        _ensureFretVisible(placements.reduce(math.min));
      }
    }
    _lastQuestion = question;
    _lastState = state;
  }

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
    final c = context.gb;
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
        final railWidth = constraints.maxWidth < 520 ? 34.0 : 44.0;
        final viewport = math.max(
          FretboardWidget.minCellWidth,
          constraints.maxWidth - railWidth,
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
              const SizedBox(height: 4),
            ],
            ListenableBuilder(
              listenable: engine,
              builder: (context, _) {
                final board = SizedBox(
                  width: visibleFrets * _cellWidth,
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          _buildFretHeader(c),
                          for (
                            var stringIndex = 0;
                            stringIndex < tuning.stringCount;
                            stringIndex++
                          )
                            _buildStringRow(c, stringIndex, keySig),
                        ],
                      ),
                      if (!widget.showScaleNotes) ..._buildInlays(c),
                    ],
                  ),
                );
                return DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.sunken,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height:
                          _headerHeight + tuning.stringCount * _rowHeight + 6,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStringRail(c, railWidth),
                          Expanded(
                            child: fitsAll
                                ? Align(
                                    alignment: Alignment.topLeft,
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
                                      thickness: 3,
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
        Text('$firstFret–$lastFret 品', style: context.text.titleSmall),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '左右拖动查看更多',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodySmall,
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

  Widget _buildStringRail(GbColors c, double width) {
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
                child: Text(
                  GuitarMath.noteNameAt(
                    tuning.noteAt(stringIndex, 0),
                  ).sharpName,
                  style: TextStyle(
                    color: c.textMuted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
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

  Widget _buildFretHeader(GbColors c) {
    return SizedBox(
      height: _headerHeight,
      child: Row(
        children: [
          for (var fret = startFret; fret <= _lastFret; fret++)
            SizedBox(
              width: _cellWidth,
              child: Center(
                child: widget.showFretNumbers
                    ? Text(
                        '$fret',
                        style: TextStyle(
                          color: _markerFrets.contains(fret)
                              ? c.textSecondary
                              : c.textMuted.withAlpha(
                                  _inFocus(fret) ? 255 : 120,
                                ),
                          fontSize: 10.5,
                          fontWeight: _markerFrets.contains(fret)
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      )
                    : _markerFrets.contains(fret) && widget.showScaleNotes
                    ? Dot(color: c.strongLine, size: 4)
                    : null,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStringRow(GbColors c, int stringIndex, KeySignature keySig) {
    return SizedBox(
      height: _rowHeight,
      child: Row(
        children: [
          for (var fret = startFret; fret <= _lastFret; fret++)
            _buildFretCell(c, stringIndex, fret, keySig),
        ],
      ),
    );
  }

  Widget _buildFretCell(
    GbColors c,
    int stringIndex,
    int fret,
    KeySignature keySig,
  ) {
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
    final highlighted = role != _CellRole.none;
    // In the inlay-only mode nothing names a note until the answer is shown,
    // then the revealed positions are labelled so the result can be learned.
    final label = widget.showScaleNotes
        ? _noteLabel(position.midi, keySig)
        : role == _CellRole.correct || role == _CellRole.target
        ? GuitarMath.noteNameAt(position.midi).sharpName
        : null;

    final (Color fill, Color border, Color textColor) = switch (role) {
      _CellRole.root => (c.ink, c.ink, c.onInk),
      _CellRole.correct ||
      _CellRole.target => (c.correct, c.correct, c.surface),
      _CellRole.wrong => (c.wrongSoft, c.wrong, c.wrong),
      _CellRole.none =>
        inKey
            ? (c.surface, c.hairline, c.textPrimary)
            : (Colors.transparent, Colors.transparent, c.textMuted),
    };

    final semanticsState = switch (role) {
      _CellRole.root => '，基准音',
      _CellRole.correct => '，正确',
      _CellRole.wrong => '，已尝试',
      _CellRole.target => '，目标音',
      _CellRole.none => '',
    };

    final showNode =
        highlighted || (widget.showScaleNotes && (inKey || label != null));
    final dim = !inFocus && !highlighted;

    return Semantics(
      button: true,
      label:
          '${stringIndex + 1}弦 $fret品，${GuitarMath.noteLabel(position.midi)}$semanticsState',
      child: SizedBox(
        width: _cellWidth,
        height: _rowHeight,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: () => widget.onFretTapped(position),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // String.
                Positioned(
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 1 + stringIndex * 0.2,
                    color: c.strongLine.withAlpha(dim ? 90 : 170),
                  ),
                ),
                // Fret wire (the nut is drawn heavier after fret 0).
                Positioned(
                  top: 0,
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: fret == 0 ? 3 : 1,
                    color: fret == 0 ? c.textMuted : c.hairline,
                  ),
                ),
                if (showNode)
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 160),
                    opacity: dim ? 0.35 : 1,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      curve: Curves.easeOut,
                      width: highlighted ? 34 : (inKey ? 28 : 22),
                      height: highlighted ? 28 : (inKey ? 22 : 18),
                      decoration: BoxDecoration(
                        color: fill,
                        borderRadius: BorderRadius.circular(
                          highlighted ? 9 : 7,
                        ),
                        border: Border.all(
                          color: border,
                          width: role == _CellRole.wrong ? 1.4 : 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: role == _CellRole.wrong && label == null
                          ? Icon(Icons.close_rounded, size: 13, color: c.wrong)
                          : Text(
                              label ?? '',
                              style: TextStyle(
                                color: textColor,
                                fontSize: inKey || highlighted ? 10.5 : 9.5,
                                fontWeight: highlighted
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                height: 1,
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
    final resolved = engine.state == TrainingState.showingResult;
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

  /// Fret-marker inlays between the strings: single dots in the middle of
  /// the neck, a double dot at the 12th fret, as on a real guitar.
  List<Widget> _buildInlays(GbColors c) {
    const size = 9.0;
    final strings = tuning.stringCount;
    final middle = _headerHeight + strings / 2 * _rowHeight;
    final pair = [
      _headerHeight + (strings / 2 - 1) * _rowHeight,
      _headerHeight + (strings / 2 + 1) * _rowHeight,
    ];
    return [
      for (var fret = startFret; fret <= _lastFret; fret++)
        if (_markerFrets.contains(fret))
          for (final (i, y) in (fret % 12 == 0 ? pair : [middle]).indexed)
            Positioned(
              key: ValueKey('inlay-$fret-$i'),
              left: (fret - startFret + 0.5) * _cellWidth - size / 2,
              top: y - size / 2,
              child: IgnorePointer(
                child: Opacity(
                  opacity: _inFocus(fret) ? 1 : 0.4,
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      color: c.strongLine,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
    ];
  }

  String? _noteLabel(int midi, KeySignature keySig) {
    final degree = keySig.degreeLabel(midi);
    if (widget.showDegrees && degree != null) return degree;
    if (widget.showNoteNames) return GuitarMath.noteNameAt(midi).sharpName;
    return null;
  }
}

enum _CellRole { none, root, correct, wrong, target }

/// Colour key for the fretboard highlight roles.
class FretboardLegend extends StatelessWidget {
  const FretboardLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.gb;
    return Wrap(
      spacing: 14,
      runSpacing: 4,
      children: [
        Dot(color: c.ink, label: '基准音'),
        Dot(color: c.wrong, label: '已尝试'),
        Dot(color: c.correct, label: '答案'),
      ],
    );
  }
}
