/// 吉他采样 WAV 生成器
///
/// 用法: dart run tool/generate_samples.dart
///
/// 生成 12 个半音 x 3 种音色 = 36 个 WAV 文件
/// 放在 assets/samples/{clean,overdrive,distortion}/ 下
///
/// 原理：合成带泛音的吉他音色 WAV，模拟真实采样。
/// 音符范围：C4-B4（一个完整八度），播放时通过变速覆盖全音域。
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

const sampleRate = 44100;
const bitsPerSample = 16;
const channels = 1;

// 12 半音名称
const noteNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];

// 音色参数
const toneParams = {
  'clean': (gain: 0.8, clip: 1.0, harmonics: [1.0, 0.4, 0.25, 0.15, 0.08]),
  'overdrive': (gain: 1.2, clip: 0.7, harmonics: [1.0, 0.6, 0.4, 0.25, 0.15, 0.1]),
  'distortion': (gain: 1.8, clip: 0.4, harmonics: [1.0, 0.8, 0.6, 0.5, 0.4, 0.3, 0.2]),
};

void main() {
  final baseDir = Directory('assets/samples');
  if (!baseDir.existsSync()) {
    print('Error: Run from project root (GuitarBridge_Flutter/)');
    return;
  }

  for (final tone in ['clean', 'overdrive', 'distortion']) {
    final toneDir = Directory('assets/samples/$tone');
    toneDir.createSync(recursive: true);

    for (int midi = 60; midi <= 71; midi++) {
      // C4-B4
      final freq = 440.0 * pow(2.0, (midi - 69) / 12.0);
      final name = '${noteNames[midi % 12]}${midi ~/ 12 - 1}';
      final path = 'assets/samples/$tone/$name.wav';

      final samples = _generateGuitarTone(freq, tone, duration: 2.0);
      _writeWav(path, samples);
      print('Generated: $path (${freq.toStringAsFixed(1)} Hz)');
    }
  }
  print('\nDone! 36 WAV files generated.');
}

List<int> _generateGuitarTone(double freq, String tone, {double duration = 2.0}) {
  final params = toneParams[tone]!;
  final totalSamples = (sampleRate * duration).toInt();
  final samples = <int>[];

  // ADSR
  final attackSamples = (sampleRate * 0.01).toInt();
  final decaySamples = (sampleRate * 0.15).toInt();
  final sustainLevel = 0.7;
  final releaseStart = totalSamples - (sampleRate * 0.3).toInt();

  for (int i = 0; i < totalSamples; i++) {
    final t = i / sampleRate;

    // 泛音叠加
    double sample = 0;
    for (int h = 0; h < params.harmonics.length; h++) {
      sample += params.harmonics[h] * sin(2 * pi * freq * (h + 1) * t);
    }

    // 轻微颤音
    sample *= 1.0 + 0.005 * sin(2 * pi * 5.5 * t);

    // ADSR
    double envelope;
    if (i < attackSamples) {
      envelope = i / attackSamples;
    } else if (i < attackSamples + decaySamples) {
      envelope = 1.0 - (1.0 - sustainLevel) * (i - attackSamples) / decaySamples;
    } else if (i < releaseStart) {
      envelope = sustainLevel;
    } else {
      envelope = sustainLevel * (1.0 - (i - releaseStart) / (totalSamples - releaseStart));
    }

    sample *= envelope * params.gain;

    // 削波（模拟失真）
    sample = sample.clamp(-params.clip, params.clip);

    // 转 16-bit PCM
    final pcm = (sample * 32767 * 0.8).round().clamp(-32768, 32767);
    samples.add(pcm);
  }
  return samples;
}

void _writeWav(String path, List<int> samples) {
  final file = File(path);
  final bytes = BytesBuilder();

  final dataSize = samples.length * 2; // 16-bit = 2 bytes

  // WAV header
  bytes.add(utf8.encode('RIFF'));
  bytes.add(_int32LE(36 + dataSize));
  bytes.add(utf8.encode('WAVE'));
  bytes.add(utf8.encode('fmt '));
  bytes.add(_int32LE(16));           // chunk size
  bytes.add(_int16LE(1));            // PCM
  bytes.add(_int16LE(channels));
  bytes.add(_int32LE(sampleRate));
  bytes.add(_int32LE(sampleRate * channels * bitsPerSample ~/ 8));
  bytes.add(_int16LE(channels * bitsPerSample ~/ 8));
  bytes.add(_int16LE(bitsPerSample));
  bytes.add(utf8.encode('data'));
  bytes.add(_int32LE(dataSize));

  // PCM data
  for (final s in samples) {
    bytes.add(_int16LE(s));
  }

  file.writeAsBytesSync(bytes.toBytes());
}

List<int> _int32LE(int v) => [(v & 0xFF), (v >> 8) & 0xFF, (v >> 16) & 0xFF, (v >> 24) & 0xFF];
List<int> _int16LE(int v) => [(v & 0xFF), (v >> 8) & 0xFF];
