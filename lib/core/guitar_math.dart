import 'dart:math';
import '../models/note.dart';
import '../models/scale.dart';
import '../models/tuning.dart';
import 'constants.dart';

/// 吉他数学引擎（对应原 Swift GuitarMath.swift）
/// 所有音程计算、指板逻辑的核心
class GuitarMath {
  GuitarMath._();

  // === 音程计算 ===

  /// 两个 MIDI 音之间的半音数
  static int semitonesBetween(int midiA, int midiB) => (midiB - midiA).abs();

  /// 从基准音到目标音的音程类型（八度内）
  static IntervalType intervalBetween(int rootMidi, int targetMidi) {
    final semitones = ((targetMidi - rootMidi) % 12 + 12) % 12;
    return IntervalType.values.firstWhere((i) => i.semitones == semitones);
  }

  /// 在给定调性下，两个音之间的级数差 (1-7)
  static int? degreeDifference(KeySignature key, int rootMidi, int targetMidi) {
    final rootDeg = key.degreeOf(rootMidi);
    final targetDeg = key.degreeOf(targetMidi);
    if (rootDeg == null || targetDeg == null) return null;
    return ((targetDeg - rootDeg + 7) % 7) + 1;
  }

  // === 指板计算（Fender 17.817 品间距公式） ===

  /// 品距比例：第 n 品的弦枕距离比例
  /// d(n) = scaleLength * (1 - 2^(-n/12))
  static double fretRatio(int fret) {
    return 1.0 - pow(2.0, -fret / 12.0);
  }

  /// 弦枕到第 n 品的距离 (scaleLength 默认 648mm = 25.5 英寸)
  static double fretDistance(int fret, {double scaleLength = 648.0}) {
    return scaleLength * fretRatio(fret);
  }

  /// 相邻两品之间的距离
  static double fretSpacing(int fromFret, {double scaleLength = 648.0}) {
    return fretDistance(fromFret + 1, scaleLength: scaleLength) -
        fretDistance(fromFret, scaleLength: scaleLength);
  }

  // === 指板查询 ===

  /// 在指板范围内查找所有匹配 MIDI 音高的位置
  static List<(int stringIdx, int fret)> findNoteOnFretboard(
    int midiNote,
    Tuning tuning, {
    int maxFret = AppConstants.maxFret,
  }) {
    final positions = <(int, int)>[];
    for (int s = 0; s < tuning.stringCount; s++) {
      for (int f = 0; f <= maxFret; f++) {
        if (tuning.noteAt(s, f) == midiNote) {
          positions.add((s, f));
        }
      }
    }
    return positions;
  }

  /// 判断某指板位置是否在给定调性内
  static bool isInKey(int midiNote, KeySignature key) {
    return key.degreeOf(midiNote) != null;
  }

  /// 获取 MIDI 音对应的音名
  static NoteName noteNameAt(int midiNote) {
    return NoteName.values[midiNote % 12];
  }

  /// 获取音名和八度
  static (NoteName, int) noteAndOctave(int midiNote) {
    return (NoteName.values[midiNote % 12], midiNote ~/ 12 - 1);
  }

  // === MIDI 工具 ===

  /// MIDI 音高转频率 (A4=69 -> 440Hz)
  static double midiToFrequency(int midiNote) {
    return 440.0 * pow(2.0, (midiNote - 69) / 12.0);
  }

  /// 频率转最近的 MIDI 音高
  static int frequencyToMidi(double freq) {
    return (69 + 12 * log(freq / 440.0) / log(2.0)).round();
  }
}
