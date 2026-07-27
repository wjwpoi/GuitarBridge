import '../engine/audio_engine.dart';

/// 音频采样配置 - 定义需要的采样文件及其元数据
class SampleConfig {
  SampleConfig._();

  /// 吉他标准范围：E2(40) ~ E6(88)，但可以通过八度折叠减少数量
  /// 按八度折叠后只需 12 个采样（一个八度内的所有半音）
  static const int sampleCount = 12; // 一个八度内的12个半音
  static const int sampleOctave = 4; // 采样八度（C4-B4）

  /// 每种音色模式需要的采样文件列表
  static List<String> requiredSamples(ToneMode mode) {
    final noteNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    return noteNames.map((n) => 'assets/samples/${mode.name}/$n$sampleOctave.wav').toList();
  }

  /// 检查采样是否存在（运行时由 flutter_soloud 或 AssetBundle 处理）
  static String samplePath(ToneMode mode, int midiNote) {
    final noteNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    final semitone = midiNote % 12;
    final octave = midiNote ~/ 12 - 1;
    return 'assets/samples/${mode.name}/${noteNames[semitone]}$octave.wav';
  }

  /// 采样回退策略：按八度折叠
  /// E2(40) -> 找 C4.wav 并降调播放
  /// E4(64) -> 直接找 E4.wav
  /// E6(88) -> 找 E4.wav 并升调播放
  static int nearestSampleMidi(int targetMidi) {
    final semitone = targetMidi % 12;
    return sampleOctave * 12 + semitone; // 折叠到采样八度
  }

  /// 从目标 MIDI 到采样 MIDI 的八度偏移
  static int octaveShift(int targetMidi) {
    return (targetMidi ~/ 12) - sampleOctave;
  }
}
