
/// ������������
class Tuning {
  final String name;
  final List<int> openStringNotes; // ���ҿ��� MIDI ���ߣ���1�ҵ�6�ң�

  const Tuning(this.name, this.openStringNotes);

  /// ��׼���� E2 A2 D3 G3 B3 E4
  static const standard = Tuning('��׼ (EADGBE)', [40, 45, 50, 55, 59, 64]);

  /// ������
  static const halfStepDown = Tuning('������ (Eb)', [39, 44, 49, 54, 58, 63]);

  /// ��ȫ��
  static const fullStepDown = Tuning('��ȫ�� (D)', [38, 43, 48, 53, 57, 62]);

  /// Drop D
  static const dropD = Tuning('Drop D', [38, 45, 50, 55, 59, 64]);

  /// DADGAD
  static const dadgad = Tuning('DADGAD', [38, 43, 50, 55, 59, 62]);

  /// Open G
  static const openG = Tuning('Open G', [38, 43, 50, 55, 60, 64]);

  static const all = [standard, halfStepDown, fullStepDown, dropD, dadgad, openG];

  int get stringCount => openStringNotes.length;

  /// ����ָ���Һ�Ʒ�� MIDI ����
  int noteAt(int stringIndex, int fret) {
    return openStringNotes[stringIndex] + fret;
  }

  /// ��ָ�巶Χ�ڲ���ָ�� MIDI ���ߵ�����λ��
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
