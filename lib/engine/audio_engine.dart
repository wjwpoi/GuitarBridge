import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import '../core/constants.dart';
import 'training_audio_port.dart';

enum AudioEngineState { uninitialized, loading, ready, error }

/// The three tone modes are the existing user-facing choices. Each one uses
/// a generated SoLoud waveform so pitch is still derived directly from MIDI;
/// no octave-shifted sample is used for any mode.
enum ToneMode { clean, overdrive, distortion }

/// Pitch-first cross-platform audio service.
///
/// The former implementation shifted twelve synthetic WAV files across four
/// octaves, changing pitch, duration, and timbre together. Audio V2 generates
/// every requested MIDI pitch directly at its twelve-tone equal-temperament
/// frequency. A stable, simple cue is more useful for ear training than an
/// unverified guitar imitation.
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

  /// Kept for source compatibility with the previous UI.
  bool hasSamples(ToneMode mode) => false;

  /// Returns the equal-temperament frequency used by the pitch-first cue.
  static double frequencyForMidi(int midiNote) =>
      440.0 * pow(2.0, (midiNote - 69) / 12.0);

  /// Maps each persisted tone choice to a deterministic pitch-preserving
  /// waveform. Kept static so pure tests do not construct the native SoLoud
  /// singleton.
  static WaveForm waveformForTone(ToneMode mode) => switch (mode) {
    ToneMode.clean => WaveForm.sin,
    ToneMode.overdrive => WaveForm.fSaw,
    ToneMode.distortion => WaveForm.fSquare,
  };

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
    final source = await _soloud.loadWaveform(
      waveformForTone(_currentMode),
      false,
      0.25,
      1,
    );
    final frequency = frequencyForMidi(midiNote);
    _soloud.setWaveformFreq(source, frequency);
    final handle = await _soloud.play(
      source,
      volume: _volume.clamp(0.0, 1.0).toDouble(),
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
    notifyListeners();
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
