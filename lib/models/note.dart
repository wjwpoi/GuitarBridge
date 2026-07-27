/// 音符模型 - 完整的音名、半音索引、音高映射
enum NoteName {
  c, cSharp, d, dSharp, e, f, fSharp, g, gSharp, a, aSharp, b;

  static const _sharpNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
  static const _flatNames  = ['C', 'Db', 'D', 'Eb', 'E', 'F', 'Gb', 'G', 'Ab', 'A', 'Bb', 'B'];

  String get sharpName => _sharpNames[index];
  String get flatName => _flatNames[index];

  /// 显示名：默认用升号，C大调/A小调上下文可切换为降号
  String displayName({bool useFlats = false}) => useFlats ? flatName : sharpName;

  /// 半音索引 (0=C, 1=C#, ..., 11=B)
  int get semitoneIndex => index;
}

/// 音程类型（相对音准训练核心）
enum IntervalType {
  unison(0, '纯一度', 'P1'),
  minorSecond(1, '小二度', 'm2'),
  majorSecond(2, '大二度', 'M2'),
  minorThird(3, '小三度', 'm3'),
  majorThird(4, '大三度', 'M3'),
  perfectFourth(5, '纯四度', 'P4'),
  tritone(6, '三全音', 'TT'),
  perfectFifth(7, '纯五度', 'P5'),
  minorSixth(8, '小六度', 'm6'),
  majorSixth(9, '大六度', 'M6'),
  minorSeventh(10, '小七度', 'm7'),
  majorSeventh(11, '大七度', 'M7'),
  octave(12, '纯八度', 'P8');

  final int semitones;
  final String chineseName;
  final String abbreviation;
  const IntervalType(this.semitones, this.chineseName, this.abbreviation);
}

/// 音阶级数（罗马数字）
enum ScaleDegree {
  i(0, 'I', '主音'),
  ii(1, 'II', '上主音'),
  iii(2, 'III', '中音'),
  iv(3, 'IV', '下属音'),
  v(4, 'V', '属音'),
  vi(5, 'VI', '下中音'),
  vii(6, 'VII', '导音');

  final int index;
  final String roman;
  final String chineseName;
  const ScaleDegree(this.index, this.roman, this.chineseName);
}
