import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../core/constants.dart';
import 'sample_config.dart';

/// 音频引擎状态
enum AudioEngineState { uninitialized, loading, ready, error }

/// 音色模式
enum ToneMode { clean, overdrive, distortion }

/// 跨平台音频引擎
///
/// 采样策略：
/// - 有真实采样：通过 flutter_soloud 加载并播放，支持八度折叠复用
/// - 无采样：实时合成正弦波（带 ADSR 包络）
/// - 音色切换：30步 sine curve crossfade
class AudioEngine extends ChangeNotifier {
  AudioEngineState _state = AudioEngineState.uninitialized;
  ToneMode _currentMode = ToneMode.clean;
  double _volume = AppConstants.defaultVolume;
  bool _isPlaying = false;
  String? _error;

  // 采样缓存：mode -> midi -> 加载状态
  final Map<ToneMode, Map<int, bool>> _sampleAvailability = {
    for (var m in ToneMode.values) m: <int, bool>{},
  };

  // Crossfade 状态
  bool _crossfading = false;
  Timer? _crossfadeTimer;
  int _crossfadeStep = 0;

  // 合成音参数
  static const int _sampleRate = 44100;
  final Map<ToneMode, double> _modeGain = {
    ToneMode.clean: 1.0,
    ToneMode.overdrive: 1.4,
    ToneMode.distortion: 1.8,
  };

  AudioEngineState get state => _state;
  ToneMode get currentMode => _currentMode;
  double get volume => _volume;
  bool get isPlaying => _isPlaying;
  bool get isReady => _state == AudioEngineState.ready;
  String? get error => _error;
  bool get isCrossfading => _crossfading;

  /// 检查特定音色模式下是否有采样
  bool hasSamples(ToneMode mode) {
    return _sampleAvailability[mode]?.values.any((v) => v) ?? false;
  }

  /// 初始化音频引擎
  Future<void> initialize() async {
    if (_state == AudioEngineState.ready) return;
    _state = AudioEngineState.loading;
    notifyListeners();

    try {
      // 扫描可用采样文件
      await _scanAvailableSamples();

      // 初始化 flutter_soloud
      // final soloud = SoLoud.instance;
      // await soloud.init(
      //   sampleRate: _sampleRate,
      //   bufferSize: 256,
      //   channels: 2,
      // );

      // 预加载发现的采样
      // await _preloadSamples(soloud);

      await Future.delayed(const Duration(milliseconds: 300));
      _state = AudioEngineState.ready;
    } catch (e) {
      debugPrint('[AudioEngine] Init error: $e');
      _state = AudioEngineState.error;
      _error = e.toString();
    }
    notifyListeners();
  }

  /// 扫描 assets 目录确认哪些采样可用
  Future<void> _scanAvailableSamples() async {
    for (final mode in ToneMode.values) {
      for (int midi = AppConstants.guitarLowestMidi;
          midi <= AppConstants.guitarHighestMidi;
          midi++) {
        try {
          // 尝试加载以确认文件存在
          // await rootBundle.load(path);
          // _sampleAvailability[mode]![midi] = true;

          // 模拟：假设所有 clean 模式采样都可用
          if (mode == ToneMode.clean) {
            _sampleAvailability[mode]![midi] = true;
          } else {
            _sampleAvailability[mode]![midi] = false;
          }
        } catch (_) {
          _sampleAvailability[mode]![midi] = false;
        }
      }
    }
    debugPrint('[AudioEngine] Clean samples: ${_sampleAvailability[ToneMode.clean]!.values.where((v) => v).length} available');
  }



  /// 播放指定 MIDI 音高
  Future<void> playNote(int midiNote) async {
    if (_state != AudioEngineState.ready) return;

    _isPlaying = true;
    notifyListeners();

    try {
      final hasSample = _sampleAvailability[_currentMode]?[midiNote] ?? false;

      if (hasSample) {
        await _playSample(midiNote);
      } else {
        await _synthesizeNote(midiNote);
      }
    } catch (e) {
      debugPrint('[AudioEngine] Play error: $e');
    }

    _isPlaying = false;
    notifyListeners();
  }

  /// 播放真实采样（支持八度折叠复用）
  Future<void> _playSample(int midiNote) async {
    final shift = SampleConfig.octaveShift(midiNote);
    final playbackRate = pow(2.0, shift).toDouble();

    // 使用 flutter_soloud:
    // final handle = _sampleHandles[_currentMode]?[nearestMidi];
    // if (handle != null) {
    //   await soloud.play(handle, volume: _volume, speed: playbackRate);
    // }

    debugPrint('[AudioEngine] Playing sample: midi=$midiNote rate=${playbackRate.toStringAsFixed(3)}');
    await Future.delayed(Duration(milliseconds: (800 / playbackRate).toInt()));
  }

  /// 合成正弦波并播放（带 ADSR 包络 + 泛音）
  Future<void> _synthesizeNote(int midiNote) async {
    final freq = 440.0 * pow(2.0, (midiNote - 69) / 12.0);
    final duration = 0.8; // 秒
    final totalSamples = (_sampleRate * duration).toInt();
    final gain = _volume * (_modeGain[_currentMode] ?? 1.0);

    // 生成带 ADSR 包络和泛音的正弦波
    final buffer = Float64List(totalSamples);

    // ADSR 参数
    final attackSamples = (_sampleRate * 0.02).toInt();  // 20ms
    final decaySamples = (_sampleRate * 0.1).toInt();    // 100ms
    final sustainLevel = 0.7;
    final releaseSamples = (_sampleRate * 0.2).toInt();  // 200ms
    final releaseStart = totalSamples - releaseSamples;

    for (int i = 0; i < totalSamples; i++) {
      final t = i / _sampleRate;

      // 基频 + 泛音（模拟吉他音色）
      double sample = 0;
      sample += sin(2 * pi * freq * t);           // 基频
      sample += 0.5 * sin(2 * pi * freq * 2 * t); // 二次泛音
      sample += 0.3 * sin(2 * pi * freq * 3 * t); // 三次泛音
      sample += 0.15 * sin(2 * pi * freq * 4 * t);// 四次泛音
      sample += 0.08 * sin(2 * pi * freq * 5 * t);// 五次泛音

      // ADSR 包络
      double envelope;
      if (i < attackSamples) {
        envelope = i / attackSamples;  // Attack: 0 -> 1
      } else if (i < attackSamples + decaySamples) {
        final decayT = (i - attackSamples) / decaySamples;
        envelope = 1.0 - (1.0 - sustainLevel) * decayT;  // Decay: 1 -> sustain
      } else if (i < releaseStart) {
        envelope = sustainLevel;  // Sustain
      } else {
        final releaseT = (i - releaseStart) / releaseSamples;
        envelope = sustainLevel * (1.0 - releaseT);  // Release: sustain -> 0
      }

      // Overdrive/Distortion 效果
      if (_currentMode == ToneMode.overdrive) {
        sample = sample.clamp(-0.7, 0.7) * 1.4;
      } else if (_currentMode == ToneMode.distortion) {
        sample = sample.clamp(-0.5, 0.5) * 1.8;
        // 额外谐波
        sample += 0.2 * (sample > 0 ? 1.0 : -1.0) * sin(2 * pi * freq * 1.5 * t);
      }

      buffer[i] = sample * envelope * gain * 0.3; // 归一化
    }

    // flutter_soloud 播放合成波形:
    // final wave = SoLoudWave.fromBuffer(buffer, _sampleRate, 1);
    // await soloud.playWave(wave, volume: 1.0);

    debugPrint('[AudioEngine] Synthesized: ${freq.toStringAsFixed(1)}Hz, ${totalSamples}samples');
    await Future.delayed(Duration(milliseconds: (duration * 1000).toInt()));
  }

  /// 音色切换（带 crossfade）
  Future<void> switchToneMode(ToneMode newMode) async {
    if (newMode == _currentMode || _crossfading) return;

    _crossfading = true;
    _crossfadeStep = 0;
    _currentMode = newMode;
    notifyListeners();

    // 30步 sine curve crossfade
    const steps = AppConstants.crossfadeSteps;
    final stepDuration = AppConstants.crossfadeDuration ~/ steps;

    _crossfadeTimer?.cancel();
    _crossfadeTimer = Timer.periodic(stepDuration, (timer) {
      _crossfadeStep++;
      // Sine curve easing for smooth gain transition
      // final oldGain = cos(t * pi / 2);  // unused if no active voice
      // final newGain = sin(t * pi / 2);

      if (_crossfadeStep >= steps) {
        timer.cancel();
        _crossfading = false;
        notifyListeners();
      }
    });
  }

  /// 取消正在进行的 crossfade（快速切换场景）
  void cancelCrossfade() {
    _crossfadeTimer?.cancel();
    _crossfading = false;
    _crossfadeStep = AppConstants.crossfadeSteps;
    notifyListeners();
  }

  void setVolume(double vol) {
    _volume = vol.clamp(0.0, 1.0);
    notifyListeners();
  }

  Future<void> disposeEngine() async {
    _crossfadeTimer?.cancel();
    _state = AudioEngineState.uninitialized;
    // await soloud.deinit();
    notifyListeners();
  }
}
