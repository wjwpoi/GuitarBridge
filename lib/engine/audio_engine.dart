import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import '../core/constants.dart';
import 'sample_config.dart';

enum AudioEngineState { uninitialized, loading, ready, error }

enum ToneMode { clean, overdrive, distortion }

/// Cross-platform audio service backed by flutter_soloud.
class AudioEngine extends ChangeNotifier {
  final SoLoud _soloud = SoLoud.instance;
  final Map<ToneMode, Map<int, AudioSource>> _sampleSources = {
    for (final mode in ToneMode.values) mode: <int, AudioSource>{},
  };
  final Map<ToneMode, double> _modeGain = {
    ToneMode.clean: 0.85,
    ToneMode.overdrive: 0.95,
    ToneMode.distortion: 1.0,
  };

  AudioEngineState _state = AudioEngineState.uninitialized;
  ToneMode _currentMode = ToneMode.clean;
  double _volume = AppConstants.defaultVolume;
  bool _isPlaying = false;
  String? _error;
  Timer? _crossfadeTimer;
  int _crossfadeStep = 0;
  bool _disposed = false;

  AudioEngineState get state => _state;
  ToneMode get currentMode => _currentMode;
  double get volume => _volume;
  bool get isPlaying => _isPlaying;
  bool get isReady => _state == AudioEngineState.ready;
  String? get error => _error;
  bool get isCrossfading => _crossfadeTimer?.isActive ?? false;

  bool hasSamples(ToneMode mode) => _sampleSources[mode]?.isNotEmpty ?? false;

  Future<void> initialize() async {
    if (_state == AudioEngineState.ready) return;
    _state = AudioEngineState.loading;
    _error = null;
    notifyListeners();

    try {
      await _soloud.init(
        sampleRate: 44100,
        bufferSize: 2048,
        channels: Channels.stereo,
      );
      await _loadSamples();
      _state = AudioEngineState.ready;
    } catch (error) {
      _state = AudioEngineState.error;
      _error = error.toString();
      debugPrint('[AudioEngine] initialization failed: $error');
    }
    notifyListeners();
  }

  Future<void> _loadSamples() async {
    for (final mode in ToneMode.values) {
      final sources = _sampleSources[mode]!;
      for (var offset = 0; offset < SampleConfig.sampleCount; offset++) {
        final sampleMidi = SampleConfig.firstSampleMidi + offset;
        final path = SampleConfig.samplePath(mode, sampleMidi);
        try {
          sources[sampleMidi] = await _soloud.loadAsset(path);
        } catch (error) {
          debugPrint('[AudioEngine] missing sample $path: $error');
        }
      }
    }
  }

  Future<void> playNote(int midiNote) async {
    if (!isReady || _disposed) return;
    _isPlaying = true;
    notifyListeners();
    try {
      final sample = _sampleSources[_currentMode]?
          [SampleConfig.nearestSampleMidi(midiNote)];
      if (sample != null) {
        await _playSample(sample, midiNote);
      } else {
        await _playSynthesized(midiNote);
      }
    } catch (error) {
      debugPrint('[AudioEngine] playback failed: $error');
    } finally {
      _isPlaying = false;
      notifyListeners();
    }
  }

  Future<void> _playSample(AudioSource source, int midiNote) async {
    final speed = pow(2.0, SampleConfig.octaveShift(midiNote)).toDouble();
    final handle = await _soloud.play(
      source,
      volume: (_volume * (_modeGain[_currentMode] ?? 1.0))
          .clamp(0.0, 1.0)
          .toDouble(),
    );
    try {
      _soloud.setRelativePlaySpeed(handle, speed);
      final milliseconds = (800 / speed).round().clamp(120, 1800).toInt();
      await Future<void>.delayed(Duration(milliseconds: milliseconds));
    } finally {
      if (_soloud.isInitialized && !handle.isError) {
        try {
          await _soloud.stop(handle);
        } catch (_) {
          // The handle can finish naturally during the delay.
        }
      }
    }
  }

  Future<void> _playSynthesized(int midiNote) async {
    final source = await _soloud.loadWaveform(WaveForm.sin, false, 0.25, 1);
    final frequency = 440.0 * pow(2.0, (midiNote - 69) / 12.0);
    _soloud.setWaveformFreq(source, frequency);
    final handle = await _soloud.play(
      source,
      volume: (_volume * (_modeGain[_currentMode] ?? 1.0))
          .clamp(0.0, 1.0)
          .toDouble(),
    );
    try {
      await Future<void>.delayed(const Duration(milliseconds: 800));
    } finally {
      if (_soloud.isInitialized && !handle.isError) {
        try {
          await _soloud.stop(handle);
        } catch (_) {
          // The handle may already have ended.
        }
      }
      if (_soloud.isInitialized) {
        await _soloud.disposeSource(source);
      }
    }
  }

  Future<void> switchToneMode(ToneMode newMode) async {
    if (newMode == _currentMode || _disposed) return;
    _crossfadeTimer?.cancel();
    _currentMode = newMode;
    _crossfadeStep = 0;
    notifyListeners();

    // The mode is applied immediately to the next note. Keep the state
    // transition observable for UI and future active-voice crossfades.
    final stepDuration = AppConstants.crossfadeDuration ~/ AppConstants.crossfadeSteps;
    _crossfadeTimer = Timer.periodic(stepDuration, (timer) {
      _crossfadeStep++;
      if (_crossfadeStep >= AppConstants.crossfadeSteps) {
        timer.cancel();
        notifyListeners();
      }
    });
  }

  void cancelCrossfade() {
    _crossfadeTimer?.cancel();
    _crossfadeStep = AppConstants.crossfadeSteps;
    notifyListeners();
  }

  void setVolume(double value) {
    _volume = value.clamp(0.0, 1.0).toDouble();
    notifyListeners();
  }

  Future<void> disposeEngine() async {
    _crossfadeTimer?.cancel();
    if (_soloud.isInitialized) {
      await _soloud.disposeAllSources();
      _soloud.deinit();
    }
    _state = AudioEngineState.uninitialized;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(disposeEngine());
    super.dispose();
  }
}
