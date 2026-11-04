import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import '../core/constants.dart';
import 'sample_config.dart';
import 'training_audio_port.dart';

enum AudioEngineState { uninitialized, loading, ready, error }

/// Pitch-first cross-platform audio service.
///
/// The engine picks the closest bundled real-guitar root and retunes it by an
/// exact equal-temperament playback-rate ratio. Keeping the sample root close
/// to the target avoids the extreme artifacts of folding one octave across
/// the full guitar range.
///
/// Decoded samples are cached for the lifetime of the engine (19 short WAVs),
/// so repeated cues never hit the asset bundle again. Voices are released
/// with a short fade instead of a hard stop to avoid clicks, and a new cue
/// fades the previous one out.
class AudioEngine extends ChangeNotifier implements TrainingAudioPort {
  /// How long [playNote] waits before reporting the cue as heard.
  static const Duration cueDuration = Duration(milliseconds: 900);

  /// How long a voice keeps ringing before it is faded out on its own.
  static const Duration ringDuration = Duration(milliseconds: 1600);
  static const Duration releaseFade = Duration(milliseconds: 260);
  static const Duration interruptFade = Duration(milliseconds: 45);

  SoLoud get _soloud => SoLoud.instance;

  AudioEngineState _state = AudioEngineState.uninitialized;
  double _volume = AppConstants.defaultVolume;
  bool _isPlaying = false;
  String? _error;
  bool _disposed = false;
  SoundHandle? _activeHandle;
  int _playbackGeneration = 0;
  Future<void>? _initialization;
  final Map<int, AudioSource> _sources = {};
  final Map<int, Future<AudioSource>> _pendingSources = {};
  Future<void> _loadQueue = Future<void>.value();

  AudioEngineState get state => _state;
  double get volume => _volume;
  bool get isPlaying => _isPlaying;
  @override
  bool get isReady => _state == AudioEngineState.ready;
  String? get error => _error;

  /// Returns the equal-temperament frequency used by the pitch-first cue.
  static double frequencyForMidi(int midiNote) =>
      440.0 * pow(2.0, (midiNote - 69) / 12.0);

  Future<void> initialize() {
    if (_state == AudioEngineState.ready || _disposed) {
      return Future<void>.value();
    }
    final activeInitialization = _initialization;
    if (activeInitialization != null) return activeInitialization;

    final initialization = _initializeOnce();
    _initialization = initialization;
    return initialization.whenComplete(() {
      if (identical(_initialization, initialization)) {
        _initialization = null;
      }
    });
  }

  Future<void> _initializeOnce() async {
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
      _ensureCleanTone();
      _state = AudioEngineState.ready;
      // Warm the sample cache in the background so the first question does
      // not wait for decoding. Failures surface on the first real play.
      unawaited(_preloadSamples());
    } catch (error) {
      _state = AudioEngineState.error;
      _error = '音频初始化失败：$error';
      debugPrint('[AudioEngine] initialization failed: $error');
    }
    if (!_disposed) notifyListeners();
  }

  Future<void> _preloadSamples() async {
    for (final root in SampleConfig.rootMidis) {
      if (_disposed || !_soloud.isInitialized) return;
      // Leave room for cues requested by the user to jump the queue.
      await Future<void>.delayed(const Duration(milliseconds: 30));
      try {
        await _sourceForRoot(root);
      } catch (error) {
        debugPrint('[AudioEngine] preload of $root failed: $error');
      }
    }
  }

  /// Loads (once) and caches the sample for [rootMidi].
  ///
  /// Loads are serialised: the SoLoud web loader does not support several
  /// concurrent `loadAsset` calls, and a cue requested during background
  /// preloading must not hang waiting on a lost completion.
  Future<AudioSource> _sourceForRoot(int rootMidi) {
    final cached = _sources[rootMidi];
    if (cached != null) return Future.value(cached);
    final pending = _pendingSources[rootMidi];
    if (pending != null) return pending;
    final load = _loadQueue
        .catchError((_) {})
        .then((_) async {
          final ready = _sources[rootMidi];
          if (ready != null) return ready;
          final source = await _soloud.loadAsset(
            SampleConfig.samplePathForRoot(rootMidi),
          );
          _sources[rootMidi] = source;
          return source;
        })
        // Block body on purpose: returning the removed future (this very
        // load) from whenComplete would make it wait on itself forever.
        .whenComplete(() {
          _pendingSources.remove(rootMidi);
        });
    _pendingSources[rootMidi] = load;
    _loadQueue = load;
    return load;
  }

  /// Plays [midiNote] and completes after [cueDuration].
  ///
  /// Returns false only when the backend failed. A cue interrupted by a newer
  /// cue still counts as played: it reached the speakers, it was just cut
  /// short on purpose.
  @override
  Future<bool> playNote(int midiNote) async {
    if (!isReady || _disposed) return false;

    final generation = ++_playbackGeneration;
    _releaseActiveHandle(interruptFade);
    _isPlaying = true;
    notifyListeners();

    try {
      final source = await _sourceForRoot(
        SampleConfig.nearestSampleMidi(midiNote),
      );
      if (generation != _playbackGeneration || _disposed) return true;
      final handle = await _soloud.play(
        source,
        volume: _volume.clamp(0.0, 1.0).toDouble(),
      );
      _soloud.setRelativePlaySpeed(
        handle,
        SampleConfig.playbackSpeedForMidi(midiNote),
      );
      if (generation != _playbackGeneration) {
        _release(handle, interruptFade);
        return true;
      }
      _activeHandle = handle;
      _scheduleNaturalRelease(handle);
      await Future<void>.delayed(cueDuration);
      return !_disposed;
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

  void _scheduleNaturalRelease(SoundHandle handle) {
    Timer(ringDuration, () {
      if (identical(_activeHandle, handle)) _activeHandle = null;
      _release(handle, releaseFade);
    });
  }

  void _releaseActiveHandle(Duration fade) {
    final handle = _activeHandle;
    _activeHandle = null;
    if (handle != null) _release(handle, fade);
  }

  void _release(SoundHandle handle, Duration fade) {
    if (!_soloud.isInitialized || handle.isError) return;
    try {
      if (!_soloud.getIsValidVoiceHandle(handle)) return;
      _soloud.fadeVolume(handle, 0, fade);
      _soloud.scheduleStop(handle, fade);
    } catch (_) {
      // The voice may already have ended.
    }
  }

  @override
  Future<void> stopAll() async {
    _playbackGeneration++;
    _isPlaying = false;
    _releaseActiveHandle(interruptFade);
    if (!_disposed) notifyListeners();
  }

  void _ensureCleanTone() {
    if (!_soloud.isInitialized) return;

    final waveShaper = _soloud.filters.waveShaperFilter;
    if (waveShaper.isActive) {
      waveShaper.deactivate();
    }
  }

  void setVolume(double value) {
    _volume = value.clamp(0.0, 1.0).toDouble();
    notifyListeners();
  }

  Future<void> disposeEngine() async {
    _playbackGeneration++;
    _releaseActiveHandle(interruptFade);
    if (_soloud.isInitialized) {
      await _soloud.disposeAllSources();
      _soloud.deinit();
    }
    _sources.clear();
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
