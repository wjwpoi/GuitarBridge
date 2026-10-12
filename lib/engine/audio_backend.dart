import 'package:flutter_soloud/flutter_soloud.dart';

import 'audio_module_stub.dart'
    if (dart.library.js_interop) 'audio_module_web.dart';
import 'tone_mode.dart';

/// Playback boundary, replaceable in tests without opening an audio device.
abstract class AudioBackend {
  bool get isInitialized;
  Future<void> initialize();
  Future<AudioSource> loadAsset(String path);
  Future<SoundHandle> playPaused(AudioSource source, double volume);
  void resume(SoundHandle handle, double speed);
  bool isVoiceValid(SoundHandle handle);
  Future<void> stop(SoundHandle handle);
  void applyToneMode(ToneMode mode);
  Future<void> disposeAllSources();
  void deinitialize();
}

class SoLoudAudioBackend implements AudioBackend {
  late final SoLoud _soloud = SoLoud.instance;
  bool _initialized = false;

  @override
  bool get isInitialized => _initialized && _soloud.isInitialized;

  @override
  Future<void> initialize() async {
    // The Web factory has no native exports until its WASM Promise resolves.
    await ensureAudioModuleReady();
    if (!_soloud.isInitialized) {
      await _soloud.init(
        sampleRate: 44100,
        bufferSize: 1024,
        channels: Channels.stereo,
      );
    }
    _initialized = true;
  }

  @override
  Future<AudioSource> loadAsset(String path) => _soloud.loadAsset(path);

  @override
  Future<SoundHandle> playPaused(AudioSource source, double volume) =>
      _soloud.play(source, volume: volume, paused: true);

  @override
  void resume(SoundHandle handle, double speed) {
    // Set the rate before unpausing, so even the attack has the requested pitch.
    _soloud.setRelativePlaySpeed(handle, speed);
    _soloud.setPause(handle, false);
  }

  @override
  bool isVoiceValid(SoundHandle handle) =>
      !handle.isError && _soloud.getIsValidVoiceHandle(handle);

  @override
  Future<void> stop(SoundHandle handle) => _soloud.stop(handle);

  @override
  void applyToneMode(ToneMode mode) {
    final waveShaper = _soloud.filters.waveShaperFilter;
    if (waveShaper.isActive) waveShaper.deactivate();
    if (mode == ToneMode.clean) return;
    waveShaper.activate();
    waveShaper.wet.value = 1.0;
    waveShaper.amount.value = mode == ToneMode.overdrive ? 0.28 : 0.72;
  }

  @override
  Future<void> disposeAllSources() => _soloud.disposeAllSources();

  @override
  void deinitialize() {
    _initialized = false;
    _soloud.deinit();
  }
}
