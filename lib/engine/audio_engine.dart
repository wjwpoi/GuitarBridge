import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import '../core/constants.dart';
import 'audio_backend.dart';
import 'sample_config.dart';
import 'tone_mode.dart';
import 'training_audio_port.dart';

export 'tone_mode.dart';

enum AudioEngineState { uninitialized, loading, ready, error }

/// Owns loaded samples for its lifetime; individual cues own only their voice.
class AudioEngine extends ChangeNotifier implements TrainingAudioPort {
  AudioEngine({AudioBackend? backend, Future<void> Function(Duration)? delay})
    : _backend = backend ?? SoLoudAudioBackend(),
      _delay = delay ?? Future<void>.delayed;

  final AudioBackend _backend;
  final Future<void> Function(Duration) _delay;
  final Map<String, Future<AudioSource>> _sources = {};

  AudioEngineState _state = AudioEngineState.uninitialized;
  ToneMode _currentMode = ToneMode.clean;
  double _volume = AppConstants.defaultVolume;
  bool _isPlaying = false;
  String? _error;
  bool _disposed = false;
  SoundHandle? _activeHandle;
  int _playbackGeneration = 0;
  int _lifecycleGeneration = 0;
  Future<void>? _initialization;
  Future<void>? _shutdown;

  AudioEngineState get state => _state;
  ToneMode get currentMode => _currentMode;
  double get volume => _volume;
  bool get isPlaying => _isPlaying;
  @override
  bool get isReady => _state == AudioEngineState.ready && !_disposed;
  String? get error => _error;

  bool hasSamples(ToneMode mode) =>
      SampleConfig.requiredSamples(mode).isNotEmpty;

  static double frequencyForMidi(int midiNote) =>
      440.0 * pow(2.0, (midiNote - 69) / 12.0);

  Future<void> initialize() async {
    if (_disposed || isReady) return;
    final closing = _shutdown;
    if (closing != null) await closing;
    if (_disposed) return;
    final pending = _initialization;
    if (pending != null) return pending;
    final operation = _initialize();
    _initialization = operation;
    try {
      await operation;
    } finally {
      if (_initialization == operation) _initialization = null;
    }
  }

  Future<void> _initialize() async {
    final generation = _lifecycleGeneration;
    _state = AudioEngineState.loading;
    _error = null;
    notifyListeners();
    try {
      await _backend.initialize();
      if (_disposed || generation != _lifecycleGeneration) return;
      _backend.applyToneMode(_currentMode);
      _state = AudioEngineState.ready;
    } catch (error) {
      if (_disposed || generation != _lifecycleGeneration) return;
      _state = AudioEngineState.error;
      _error = error.toString();
      debugPrint('[AudioEngine] initialization failed: $error');
    }
    if (!_disposed) notifyListeners();
  }

  Future<AudioSource> _loadSource(String path) async {
    final cached = _sources[path];
    if (cached != null) return cached;
    final pending = _backend.loadAsset(path);
    _sources[path] = pending;
    try {
      return await pending;
    } catch (_) {
      // Failed loads must be retried after resources become available again.
      if (_sources[path] == pending) _sources.remove(path);
      rethrow;
    }
  }

  bool _isCurrent(int generation) =>
      generation == _playbackGeneration && !_disposed && isReady;

  @override
  Future<bool> playNote(int midiNote) async {
    if (!isReady) return false;
    final generation = ++_playbackGeneration;
    final path = SampleConfig.samplePath(_currentMode, midiNote);
    await _stopActiveHandle();
    if (!_isCurrent(generation)) return false;
    _isPlaying = true;
    _error = null;
    notifyListeners();

    SoundHandle? handle;
    try {
      final source = await _loadSource(path);
      if (!_isCurrent(generation)) return false;
      handle = await _backend.playPaused(source, _volume);
      if (!_isCurrent(generation)) return false;
      if (handle.isError || !_backend.isVoiceValid(handle)) {
        throw StateError('Audio backend returned an invalid voice');
      }
      _activeHandle = handle;
      _backend.resume(handle, SampleConfig.playbackSpeedForMidi(midiNote));
      await _delay(const Duration(milliseconds: 900));
      return _isCurrent(generation) && _backend.isVoiceValid(handle);
    } catch (error) {
      // A cancelled load/play must not overwrite a newer cue's ready state.
      if (_isCurrent(generation)) {
        _state = AudioEngineState.error;
        _error = '无法播放 MIDI $midiNote：$error';
        debugPrint('[AudioEngine] playback failed: $error');
        notifyListeners();
      }
      return false;
    } finally {
      if (handle != null) {
        if (_activeHandle == handle) _activeHandle = null;
        await _stopHandle(handle);
      }
      if (generation == _playbackGeneration) {
        _isPlaying = false;
        if (!_disposed) notifyListeners();
      }
    }
  }

  Future<void> _stopHandle(SoundHandle handle) async {
    if (!handle.isError && _backend.isInitialized) {
      try {
        await _backend.stop(handle);
      } catch (_) {
        // An already-ended voice is safely stopped.
      }
    }
  }

  Future<void> _stopActiveHandle() async {
    final handle = _activeHandle;
    _activeHandle = null;
    if (handle != null) await _stopHandle(handle);
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
    if (isReady) _backend.applyToneMode(newMode);
    notifyListeners();
  }

  void setVolume(double value) {
    _volume = value.clamp(0.0, 1.0).toDouble();
    if (!_disposed) notifyListeners();
  }

  Future<void> disposeEngine() async {
    final pending = _shutdown;
    if (pending != null) return pending;
    final operation = _disposeBackend();
    _shutdown = operation;
    try {
      await operation;
    } finally {
      if (_shutdown == operation) _shutdown = null;
    }
  }

  Future<void> _disposeBackend() async {
    _lifecycleGeneration++;
    _playbackGeneration++;
    _state = AudioEngineState.uninitialized;
    _isPlaying = false;
    await _stopActiveHandle();
    // Let in-flight loads finish before deinitializing their native backend.
    await _initialization;
    await Future.wait(
      _sources.values.map((source) async {
        try {
          await source;
        } catch (_) {
          // Failed loads have no resource to dispose.
        }
      }),
    );
    _sources.clear();
    if (_backend.isInitialized) {
      await _backend.disposeAllSources();
      _backend.deinitialize();
    }
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(disposeEngine());
    super.dispose();
  }
}
