
/// 吉他调弦配置
class Tuning {
  final String name;
  final List<int> openStringNotes; // 各弦空弦 MIDI 音高（从1弦到6弦）

  const Tuning(this.name, this.openStringNotes);

  /// 标准调弦 E2 A2 D3 G3 B3 E4
  static const standard = Tuning('标准 (EADGBE)', [64, 59, 55, 50, 45, 40]);

  /// 降半音
  static const halfStepDown = Tuning('降半音 (Eb)', [63, 58, 54, 49, 44, 39]);

  /// 降全音
  static const fullStepDown = Tuning('降全音 (D)', [62, 57, 53, 48, 43, 38]);

  /// Drop D
  static const dropD = Tuning('Drop D', [64, 59, 55, 50, 45, 38]);

  /// DADGAD
  static const dadgad = Tuning('DADGAD', [62, 57, 55, 50, 45, 38]);

  /// Open G
  static const openG = Tuning('Open G', [64, 60, 55, 50, 43, 38]);

  static const all = [standard, halfStepDown, fullStepDown, dropD, dadgad, openG];

  int get stringCount => openStringNotes.length;

  /// 计算指定弦和品的 MIDI 音高
  int noteAt(int stringIndex, int fret) {
    return openStringNotes[stringIndex] + fret;
  }

  /// 在指板范围内查找指定 MIDI 音高的所有位置
  List<(int, int)> findNotePositions(int midiNote, {int maxFret = 22}) {
    final positions = <(int, int)>[];
    for (int s = 0; s < stringCount; s++) {
      for (int f = 0; f <= maxFret; f++) {
        if (noteAt(s, f) == midiNote) {
          positions.add((s, f));
        }
      }
    }
    return positions;
  }
}
