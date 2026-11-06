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

/// The fretboard drawn as an instrument: strings of increasing gauge, fret
/// wires, a nut and inlays, with round note marks on top.
///
/// Fret 0 has its own narrow column left of the nut; frets 1–22 share one
/// width that stretches to show the whole neck when there is room and falls
/// back to horizontal scrolling with a 44 px minimum on phones. A new
/// question scrolls the root into view.
class FretboardWidget extends StatefulWidget {
  final TrainingEngine trainingEngine;
  final Tuning tuning;
  final ScaleType scaleType;
  final String selectedKey;
  final bool showDegrees;
  final bool showNoteNames;
  final bool showFretNumbers;

  /// False hides every scale-note mark so only the inlays of a real guitar
  /// are left to orient by. The root, attempts and the revealed answer stay.
  final bool showScaleNotes;
  final ValueChanged<FretPosition> onFretTapped;

  /// Always 0: the open-string column is part of the layout.
  final int startFret;
  final int visibleFrets;

  /// Fret range questions are drawn from. Frets beyond it are washed out
  /// during a session (answers there are still accepted).
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

/// Geometry shared by painting, hit-testing and scrolling.
class _Geometry {
  final double nutWidth;
  final double cell;
  final double row;
  final double top;
  final int lastFret;

  const _Geometry({
    required this.nutWidth,
    required this.cell,
    required this.row,
    required this.top,
    required this.lastFret,
  });

  double get width => nutWidth + lastFret * cell;
  double get height => top * 2 + row * 5;
  double cellStart(int fret) => fret == 0 ? 0 : nutWidth + (fret - 1) * cell;
  double cellEnd(int fret) => fret == 0 ? nutWidth : nutWidth + fret * cell;
  double cellWidth(int fret) => fret == 0 ? nutWidth : cell;
  double centerX(int fret) => (cellStart(fret) + cellEnd(fret)) / 2;
  double stringY(int string) => top + string * row;
}

class _FretboardWidgetState extends State<FretboardWidget> {
  late final ScrollController _scrollController;
  _Geometry _geometry = const _Geometry(
    nutWidth: 48,
    cell: 56,
    row: 36,
    top: 22,
    lastFret: 22,
  );
  double _viewport = 0;
  TrainingQuestion? _lastQuestion;
  TrainingState? _lastState;

  TrainingEngine get engine => widget.trainingEngine;
  Tuning get tuning => widget.tuning;
  int get _lastFret => widget.startFret + widget.visibleFrets - 1;

  static const Set<int> _markerFrets = {3, 5, 7, 9, 12, 15, 17, 19, 21};
  static const List<double> _gauges = [1, 1.2, 1.5, 2, 2.4, 2.8];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
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
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (mounted) setState(() {});
  }

  double get _offset =>
      _scrollController.hasClients ? _scrollController.offset : 0;

  int get _firstVisibleFret {
    for (var f = 0; f <= _lastFret; f++) {
      if (_geometry.cellEnd(f) > _offset + 1) return f;
    }
    return _lastFret;
  }

  int get _lastVisibleFret {
    var last = 0;
    for (var f = 0; f <= _lastFret; f++) {
      if (_geometry.cellEnd(f) <= _offset + _viewport + 0.5) last = f;
    }
    return last;
  }

  bool _isFretVisible(int fret) =>
      fret >= _firstVisibleFret && fret <= _lastVisibleFret;

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

  void _ensureFretVisible(int fret) {
    if (_isFretVisible(fret)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final target = (_geometry.cellStart(fret) - _geometry.cell).clamp(
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

  Future<void> _scrollByFrets(int fretDelta) async {
    if (!_scrollController.hasClients) return;
    final target = (_scrollController.offset + fretDelta * _geometry.cell)
        .clamp(0.0, _scrollController.position.maxScrollExtent);
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
        final compact = constraints.maxWidth < 520;
        final railWidth = compact ? 22.0 : 28.0;
        final nutWidth = compact ? 36.0 : 48.0;
        final row = compact ? 44.0 : 36.0;
        _viewport = math.max(
          FretboardWidget.minCellWidth,
          constraints.maxWidth - railWidth,
        );
        final frets = math.max(1, _lastFret);
        final cell = ((_viewport - nutWidth) / frets).clamp(
          FretboardWidget.minCellWidth,
          FretboardWidget.maxCellWidth,
        );
        _geometry = _Geometry(
          nutWidth: nutWidth,
          cell: cell,
          row: row,
          top: compact ? 26 : 22,
          lastFret: _lastFret,
        );
        final fitsAll = _geometry.width <= _viewport + 0.5;

        final board = ListenableBuilder(
          listenable: engine,
          builder: (context, _) => _buildBoard(c, keySig),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!fitsAll) _buildNavigationBar(context),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStringRail(c, railWidth),
                Expanded(
                  child: fitsAll
                      ? Align(alignment: Alignment.topLeft, child: board)
                      : ScrollConfiguration(
                          behavior: ScrollConfiguration.of(context).copyWith(
                            dragDevices: const {
                              PointerDeviceKind.touch,
                              PointerDeviceKind.mouse,
                              PointerDeviceKind.stylus,
                              PointerDeviceKind.trackpad,
                            },
                            scrollbars: false,
                          ),
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            scrollDirection: Axis.horizontal,
                            child: board,
                          ),
                        ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildNavigationBar(BuildContext context) {
    final c = context.gb;
    final first = _firstVisibleFret;
    final last = _lastVisibleFret;
    final atStart = first <= 0;
    final atEnd = _scrollController.hasClients
        ? _scrollController.offset >=
              _scrollController.position.maxScrollExtent - 1
        : false;
    return Row(
      children: [
        Text(
          '$first–$last 品',
          style: AppTheme.monoStyle(size: 12, color: c.textBody),
        ),
        const Spacer(),
        IconButton(
          onPressed: atStart ? null : () => _scrollByFrets(-4),
          tooltip: '向低把位移动',
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        IconButton(
          onPressed: atEnd ? null : () => _scrollByFrets(4),
          tooltip: '向高把位移动',
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }

  Widget _buildStringRail(GbColors c, double width) {
    final g = _geometry;
    return SizedBox(
      width: width,
      height: g.height,
      child: Stack(
        children: [
          for (var s = 0; s < tuning.stringCount; s++)
            Positioned(
              left: 0,
              right: 6,
              top: g.stringY(s) - 8,
              height: 16,
              child: Center(
                child: Text(
                  GuitarMath.noteNameAt(tuning.noteAt(s, 0)).sharpName,
                  style: AppTheme.monoStyle(
                    size: 11.5,
                    color: c.textMuted,
                  ).copyWith(height: 1.3),
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

  Widget _buildBoard(GbColors c, KeySignature keySig) {
    final g = _geometry;
    final range = widget.focusFretRange;
    final shadeFrom = range != null && engine.isSessionActive
        ? range.$2 + 1
        : null;
    final shadeLeft = shadeFrom != null && shadeFrom <= g.lastFret
        ? g.cellStart(shadeFrom)
        : null;
    final numbersHeight = widget.showFretNumbers ? 22.0 : 0.0;
    final captionHeight = shadeLeft != null ? 20.0 : 0.0;

    return SizedBox(
      width: g.width,
      height: g.height + numbersHeight + captionHeight + 8,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 0,
            width: g.width,
            height: g.height,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: c.sunken,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          if (shadeLeft != null)
            Positioned(
              left: shadeLeft,
              top: 0,
              width: g.width - shadeLeft,
              height: g.height,
              child: IgnorePointer(
                child: ColoredBox(color: c.canvas.withAlpha(140)),
              ),
            ),
          Positioned(
            left: 0,
            top: 0,
            width: g.width,
            height: g.height,
            child: IgnorePointer(
              child: CustomPaint(
                painter: _NeckPainter(
                  geometry: g,
                  strings: tuning.stringCount,
                  gauges: _gauges,
                  colors: c,
                ),
              ),
            ),
          ),
          if (!widget.showScaleNotes) ..._buildInlays(c),
          for (var s = 0; s < tuning.stringCount; s++)
            for (var f = 0; f <= g.lastFret; f++) _buildCell(c, s, f, keySig),
          if (widget.showFretNumbers)
            for (var f = 0; f <= g.lastFret; f++)
              Positioned(
                left: g.cellStart(f),
                width: g.cellWidth(f),
                top: g.height + 6,
                child: Text(
                  '$f',
                  textAlign: TextAlign.center,
                  style: AppTheme.monoStyle(
                    size: 11,
                    color: _markerFrets.contains(f) ? c.textBody : c.textMuted,
                    weight: _markerFrets.contains(f)
                        ? FontWeight.w500
                        : FontWeight.w400,
                  ),
                ),
              ),
          if (shadeLeft != null)
            Positioned(
              left: shadeLeft + 10,
              top: g.height + numbersHeight + 4,
              child: Text(
                '范围外也算，但不出题',
                style: TextStyle(fontSize: 11.5, color: c.textMuted),
              ),
            ),
        ],
      ),
    );
  }

  /// Fret-marker inlays between the strings: single dots in the middle of
  /// the neck, a double dot at the 12th fret, as on a real guitar.
  List<Widget> _buildInlays(GbColors c) {
    final g = _geometry;
    const size = 9.0;
    final strings = tuning.stringCount;
    final middle = g.top + (strings - 1) / 2 * g.row;
    final pair = [middle - g.row, middle + g.row];
    return [
      for (var fret = 0; fret <= g.lastFret; fret++)
        if (_markerFrets.contains(fret))
          for (final (i, y) in (fret % 12 == 0 ? pair : [middle]).indexed)
            Positioned(
              key: ValueKey('inlay-$fret-$i'),
              left: g.centerX(fret) - size / 2,
              top: y - size / 2,
              child: IgnorePointer(
                child: Opacity(
                  opacity: _inFocus(fret) ? 1 : 0.45,
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      color: c.inlay,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
    ];
  }

  Widget _buildCell(
    GbColors c,
    int stringIndex,
    int fret,
    KeySignature keySig,
  ) {
    final g = _geometry;
    final position = FretPosition.fromTuning(
      tuning: tuning,
      stringIndex: stringIndex,
      fret: fret,
    );
    final state = engine.state;
    final inKey = GuitarMath.isInKey(position.midi, keySig);
    final questionVisible =
        state == TrainingState.playingRoot ||
        state == TrainingState.waitingAnswer ||
        state == TrainingState.showingResult;
    final role = _roleFor(position, questionVisible);
    final highlighted = role != _CellRole.none;
    final compact = g.row > 40;

    // In the inlay-only mode nothing names a note until the answer is shown.
    final String? label;
    if (!widget.showScaleNotes) {
      label = role == _CellRole.correct || role == _CellRole.target
          ? GuitarMath.noteNameAt(position.midi).sharpName
          : null;
    } else if (highlighted) {
      label = GuitarMath.noteNameAt(position.midi).sharpName;
    } else {
      label = inKey ? _noteLabel(position.midi, keySig) : null;
    }
    final showMark = highlighted || (widget.showScaleNotes && inKey);

    final markSize = highlighted
        ? (compact ? 32.0 : 30.0)
        : (compact ? 26.0 : 24.0);
    final (Color fill, Border? border, Color textColor) = switch (role) {
      _CellRole.root => (c.ink, null, c.onInk),
      _CellRole.correct || _CellRole.target => (c.correct, null, c.surface),
      _CellRole.wrong => (
        c.wrongSoft,
        Border.all(color: c.wrong, width: 1.5),
        c.wrong,
      ),
      _CellRole.none => (c.surface, Border.all(color: c.chip), c.textBody),
    };
    final semanticsState = switch (role) {
      _CellRole.root => '，基准音',
      _CellRole.correct => '，正确',
      _CellRole.wrong => '，已尝试',
      _CellRole.target => '，目标音',
      _CellRole.none => '',
    };

    return Positioned(
      left: g.cellStart(fret),
      width: g.cellWidth(fret),
      top: g.stringY(stringIndex) - g.row / 2,
      height: g.row,
      child: Semantics(
        button: true,
        label:
            '${stringIndex + 1}弦 $fret品，${GuitarMath.noteLabel(position.midi)}$semanticsState',
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: () => widget.onFretTapped(position),
            customBorder: const CircleBorder(),
            child: Center(
              child: showMark
                  ? AnimatedOpacity(
                      duration: const Duration(milliseconds: 160),
                      opacity: highlighted || _inFocus(fret) ? 1 : 0.45,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        curve: Curves.easeOut,
                        width: markSize,
                        height: markSize,
                        decoration: BoxDecoration(
                          color: fill,
                          shape: BoxShape.circle,
                          border: border,
                        ),
                        alignment: Alignment.center,
                        child: label == null
                            ? null
                            : Text(
                                label,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: highlighted ? 12.5 : 11,
                                  fontWeight:
                                      highlighted && role != _CellRole.wrong
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  height: 1,
                                ),
                              ),
                      ),
                    )
                  : const SizedBox.shrink(),
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

  String? _noteLabel(int midi, KeySignature keySig) {
    final degree = keySig.degreeLabel(midi);
    if (widget.showDegrees && degree != null) return degree;
    if (widget.showNoteNames) return GuitarMath.noteNameAt(midi).sharpName;
    return null;
  }
}

enum _CellRole { none, root, correct, wrong, target }

/// Strings, fret wires and the nut.
class _NeckPainter extends CustomPainter {
  final _Geometry geometry;
  final int strings;
  final List<double> gauges;
  final GbColors colors;

  _NeckPainter({
    required this.geometry,
    required this.strings,
    required this.gauges,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final g = geometry;
    final wire = Paint()..color = colors.fretWire;
    for (var f = 1; f <= g.lastFret; f++) {
      canvas.drawRect(
        Rect.fromLTWH(g.cellEnd(f) - 0.75, 6, 1.5, g.height - 12),
        wire,
      );
    }
    canvas.drawRect(
      Rect.fromLTWH(g.nutWidth - 3, 4, 3, g.height - 8),
      Paint()..color = colors.nut,
    );
    for (var s = 0; s < strings; s++) {
      final gauge = gauges[s.clamp(0, gauges.length - 1)];
      canvas.drawRect(
        Rect.fromLTWH(0, g.stringY(s) - gauge / 2, g.width, gauge),
        Paint()..color = s < 3 ? colors.stringPlain : colors.stringWound,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _NeckPainter old) =>
      old.geometry.cell != geometry.cell ||
      old.geometry.row != geometry.row ||
      old.geometry.lastFret != geometry.lastFret ||
      old.colors != colors ||
      old.strings != strings;
}

/// Colour key for the fretboard highlight roles.
class FretboardLegend extends StatelessWidget {
  const FretboardLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.gb;
    Widget ring(Color color) => Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.5),
      ),
    );
    return Wrap(
      spacing: 18,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Dot(color: c.ink, label: '基准音', size: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ring(c.wrong),
            const SizedBox(width: 6),
            Text('试过', style: context.text.bodySmall),
          ],
        ),
        Dot(color: c.correct, label: '答案', size: 10),
      ],
    );
  }
}
