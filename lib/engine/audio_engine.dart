import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import '../core/constants.dart';
import 'sample_config.dart';
import 'training_audio_port.dart';

enum AudioEngineState { uninitialized, loading, ready, error }

/// The three tone modes are the existing user-facing choices. They all start
/// from the same real electric-guitar recording; overdrive and distortion add
/// SoLoud's global wave-shaper effect without changing the requested pitch.
enum ToneMode { clean, overdrive, distortion }

/// Pitch-first cross-platform audio service.
///
/// The engine picks the closest bundled real-guitar root and retunes it by an
/// exact equal-temperament playback-rate ratio. Keeping the sample root close
/// to the target avoids the extreme artifacts of folding one octave across
/// the full guitar range.
class AudioEngine extends ChangeNotifier implements TrainingAudioPort {
  final SoLoud _soloud = SoLoud.instance;

  AudioEngineState _state = AudioEngineState.uninitialized;
  ToneMode _currentMode = ToneMode.clean;
  double _volume = AppConstants.defaultVolume;
  bool _isPlaying = false;
  String? _error;
  bool _disposed = false;
  SoundHandle? _activeHandle;
  int _playbackGeneration = 0;

  AudioEngineState get state => _state;
  ToneMode get currentMode => _currentMode;
  double get volume => _volume;
  bool get isPlaying => _isPlaying;
  @override
  bool get isReady => _state == AudioEngineState.ready;
  String? get error => _error;

  bool hasSamples(ToneMode mode) =>
      SampleConfig.requiredSamples(mode).isNotEmpty;

  /// Returns the equal-temperament frequency used by the pitch-first cue.
  static double frequencyForMidi(int midiNote) =>
      440.0 * pow(2.0, (midiNote - 69) / 12.0);

  Future<void> initialize() async {
    if (_state == AudioEngineState.ready || _disposed) return;
    _state = AudioEngineState.loading;
    _error = null;
    notifyListeners();

    try {
      if (!_soloud.isInitialized) {
        await _soloud.init(
          sampleRate: 44100,
          bufferSize: 1024,
          channels: Channels.stereo,
        );
      }
      await _applyToneModeEffect();
      _state = AudioEngineState.ready;
    } catch (error) {
      _state = AudioEngineState.error;
      _error = error.toString();
      debugPrint('[AudioEngine] initialization failed: $error');
    }
    if (!_disposed) notifyListeners();
  }

  @override
  Future<bool> playNote(int midiNote) async {
    if (!isReady || _disposed) return false;

    final generation = ++_playbackGeneration;
    await _stopActiveHandle();
    _isPlaying = true;
    _error = null;
    notifyListeners();

    try {
      await _playPitchCue(midiNote, generation);
      return generation == _playbackGeneration && !_disposed;
    } catch (error) {
      _state = AudioEngineState.error;
      _error = '无法播放 MIDI $midiNote：$error';
      debugPrint('[AudioEngine] playback failed: $error');
      if (!_disposed) notifyListeners();
      return false;
    } finally {
      if (generation == _playbackGeneration) {
        _isPlaying = false;
        if (!_disposed) notifyListeners();
      }
    }
  }

  Future<void> _playPitchCue(int midiNote, int generation) async {
    final source = await _soloud.loadAsset(
      SampleConfig.samplePath(_currentMode, midiNote),
    );
    final handle = await _soloud.play(
      source,
      volume: _volume.clamp(0.0, 1.0).toDouble(),
    );
    _soloud.setRelativePlaySpeed(
      handle,
      SampleConfig.playbackSpeedForMidi(midiNote),
    );
    if (generation == _playbackGeneration) {
      _activeHandle = handle;
    }

    try {
      await Future<void>.delayed(const Duration(milliseconds: 900));
    } finally {
      if (_activeHandle == handle) _activeHandle = null;
      if (_soloud.isInitialized && !handle.isError) {
        try {
          await _soloud.stop(handle);
        } catch (_) {
          // The voice may have ended or been stopped by a newer cue.
        }
      }
      if (_soloud.isInitialized) {
        try {
          await _soloud.disposeSource(source);
        } catch (_) {
          // Deinitialization can race with application disposal.
        }
      }
    }
  }

  Future<void> _stopActiveHandle() async {
    final handle = _activeHandle;
    _activeHandle = null;
    if (handle != null && _soloud.isInitialized && !handle.isError) {
      try {
        await _soloud.stop(handle);
      } catch (_) {
        // Treat an already-finished voice as stopped.
      }
    }
  }

  @override
  Future<void> stopAll() async {
    _playbackGeneration++;
    _isPlaying = false;
    await _stopActiveHandle();
    if (!_disposed) notifyListeners();
  }

  Future<void> switchToneMode(ToneMode newMode) async {
    if (_disposed) return;
    _currentMode = newMode;
    if (_state == AudioEngineState.ready) {
      await _applyToneModeEffect();
    }
    notifyListeners();
  }

  Future<void> _applyToneModeEffect() async {
    if (!_soloud.isInitialized) return;

    final waveShaper = _soloud.filters.waveShaperFilter;
    if (waveShaper.isActive) {
      waveShaper.deactivate();
    }
    if (_currentMode == ToneMode.clean) return;

    waveShaper.activate();
    waveShaper.wet.value = 1.0;
    waveShaper.amount.value = switch (_currentMode) {
      ToneMode.overdrive => 0.28,
      ToneMode.distortion => 0.72,
      ToneMode.clean => 0.0,
    };
  }

  void setVolume(double value) {
    _volume = value.clamp(0.0, 1.0).toDouble();
    notifyListeners();
  }

  Future<void> disposeEngine() async {
    _playbackGeneration++;
    await _stopActiveHandle();
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
