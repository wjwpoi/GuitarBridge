import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../core/constants.dart';

/// 音频引擎状态
enum AudioEngineState { uninitialized, loading, ready, error }

/// 音色模式
enum ToneMode { clean, overdrive, distortion }

/// 跨平台音频引擎（对应原 Swift AudioEngine.swift）
/// 封装 flutter_soloud 实现低延迟采样播放 + crossfade
class AudioEngine extends ChangeNotifier {
  AudioEngineState _state = AudioEngineState.uninitialized;
  ToneMode _currentMode = ToneMode.clean;
  double _volume = AppConstants.defaultVolume;
  bool _isPlaying = false;
  String? _error;

  // 各音色模式的采样缓存（MIDI音高 -> 采样句柄）
  final Map<ToneMode, Map<int, dynamic>> _sampleCache = {
    for (var m in ToneMode.values) m: <int, dynamic>{},
  };

  // Crossfade 状态
  dynamic _currentHandle;
  bool _crossfading = false;

  AudioEngineState get state => _state;
  ToneMode get currentMode => _currentMode;
  double get volume => _volume;
  bool get isPlaying => _isPlaying;
  bool get isReady => _state == AudioEngineState.ready;
  String? get error => _error;

  /// 初始化音频引擎
  Future<void> initialize() async {
    if (_state == AudioEngineState.ready) return;
    _state = AudioEngineState.loading;
    notifyListeners();

    try {
      // TODO: 使用 flutter_soloud 初始化
      // final soloud = SoLoud.instance;
      // await soloud.init();
      // await _preloadSamples(soloud);

      // 模拟初始化完成
      await Future.delayed(const Duration(milliseconds: 500));
      _state = AudioEngineState.ready;
    } catch (e) {
      _state = AudioEngineState.error;
      _error = e.toString();
    }
    notifyListeners();
  }

  /// 预加载采样文件
  Future<void> _preloadSamples(dynamic soloud) async {
    for (final mode in ToneMode.values) {
      for (int midi = AppConstants.guitarLowestMidi;
          midi <= AppConstants.guitarHighestMidi;
          midi++) {
        final noteName = _midiToNoteName(midi);
        final path = 'assets/samples/${mode.name}/$noteName.wav';
        try {
          // final handle = await soloud.loadAsset(path);
          // _sampleCache[mode]![midi] = handle;
        } catch (_) {
          // 采样缺失则不加载，后续触发合成音
        }
      }
    }
  }

  /// 播放 MIDI 音高
  Future<void> playNote(int midiNote) async {
    if (_state != AudioEngineState.ready) return;

    _isPlaying = true;
    notifyListeners();

    try {
      await _playWithCrossfade(midiNote);
    } catch (e) {
      debugPrint('[AudioEngine] Play error: $e');
    }

    _isPlaying = false;
    notifyListeners();
  }

  /// 带 crossfade 的播放
  Future<void> _playWithCrossfade(int midiNote) async {
    if (_crossfading) return;

    final handle = _sampleCache[_currentMode]?[midiNote];
    if (handle != null) {
      // 有真实采样：直接播放
      // await soloud.play(handle, volume: _volume);
    } else {
      // 无采样：合成正弦波（fallback）
      await _synthesizeAndPlay(midiNote);
    }
  }

  /// 合成正弦波播放（采样缺失时的 fallback）
  Future<void> _synthesizeAndPlay(int midiNote) async {
    // flutter_soloud 支持实时波形生成
    // 此处为占位，实际使用 soloud 的 Oscillator 或 Wave 功能
    debugPrint('[AudioEngine] Synthesizing note $midiNote');
    await Future.delayed(const Duration(milliseconds: 800));
  }

  /// 切换到新音色（带 crossfade）
  Future<void> switchToneMode(ToneMode newMode) async {
    if (newMode == _currentMode) return;

    _crossfading = true;
    final oldMode = _currentMode;
    _currentMode = newMode;
    notifyListeners();

    // Crossfade: 用正弦曲线做增益斜坡，防止爆音
    final steps = AppConstants.crossfadeSteps;
    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      // Sine curve easing
      final oldGain = cos(t * pi / 2);
      final newGain = sin(t * pi / 2);

      // TODO: soloud.setVolume(handle, volume * gain)
      await Future.delayed(
        AppConstants.crossfadeDuration ~/ steps,
      );
    }

    _crossfading = false;
    notifyListeners();
  }

  void setVolume(double vol) {
    _volume = vol.clamp(0.0, 1.0);
    notifyListeners();
  }

  Future<void> disposeEngine() async {
    _state = AudioEngineState.uninitialized;
    // TODO: soloud.deinit();
    notifyListeners();
  }

  String _midiToNoteName(int midi) {
    const names = [
      'C', 'C#', 'D', 'D#', 'E', 'F',
      'F#', 'G', 'G#', 'A', 'A#', 'B'
    ];
    final octave = midi ~/ 12 - 1;
    return '${names[midi % 12]}$octave';
  }
}
