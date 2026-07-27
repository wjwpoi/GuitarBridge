import 'note.dart';

/// 音阶类型
enum ScaleType {
  major('自然大调', [0, 2, 4, 5, 7, 9, 11]),
  naturalMinor('自然小调', [0, 2, 3, 5, 7, 8, 10]),
  harmonicMinor('和声小调', [0, 2, 3, 5, 7, 8, 11]),
  melodicMinor('旋律小调', [0, 2, 3, 5, 7, 9, 11]),
  majorPentatonic('大调五声', [0, 2, 4, 7, 9]),
  minorPentatonic('小调五声', [0, 3, 5, 7, 10]),
  blues('蓝调音阶', [0, 3, 5, 6, 7, 10]),
  dorian('多利亚调式', [0, 2, 3, 5, 7, 9, 10]),
  phrygian('弗里吉亚调式', [0, 1, 3, 5, 7, 8, 10]),
  lydian('利底亚调式', [0, 2, 4, 6, 7, 9, 11]),
  mixolydian('混合利底亚', [0, 2, 4, 5, 7, 9, 10]),
  locrian('洛克里亚调式', [0, 1, 3, 5, 6, 8, 10]);

  final String chineseName;
  final List<int> intervals; // 半音偏移量，从根音起

  const ScaleType(this.chineseName, this.intervals);

  /// 在给定根音下调内的所有音高（MIDI）
  List<int> notesInKey(int rootMidi) {
    return intervals.map((i) => rootMidi + i).toList();
  }

  /// 在给定根音下指定八度内的所有音高
  List<int> notesInOctaveRange(int rootMidi, int minMidi, int maxMidi) {
    final base = notesInKey(rootMidi);
    final result = <int>[];
    for (int octave = -2; octave <= 3; octave++) {
      for (final n in base) {
        final pitch = n + octave * 12;
        if (pitch >= minMidi && pitch <= maxMidi) {
          result.add(pitch);
        }
      }
    }
    result.sort();
    return result;
  }
}

/// 调性（调号 + 调式）
class KeySignature {
  final NoteName tonic;
  final ScaleType scaleType;

  const KeySignature(this.tonic, this.scaleType);

  String get displayName => '${tonic.sharpName} ${scaleType.chineseName}';

  List<int> notesInKey({int octave = 4}) {
    final root = tonic.semitoneIndex + (octave + 1) * 12;
    return scaleType.notesInKey(root);
  }

  /// 某个 MIDI 音高在此调内的级数（1-7），不在调内返回 null
  int? degreeOf(int midiNote) {
    final root = tonic.semitoneIndex;
    final semitoneInOctave = ((midiNote - root) % 12 + 12) % 12;
    final idx = scaleType.intervals.indexOf(semitoneInOctave);
    return idx >= 0 ? idx + 1 : null;
  }
}
