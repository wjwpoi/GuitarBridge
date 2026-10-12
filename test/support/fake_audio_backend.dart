import 'dart:async';

import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:guitar_bridge/engine/audio_backend.dart';
import 'package:guitar_bridge/engine/tone_mode.dart';

class FakeAudioSource implements AudioSource {
  FakeAudioSource(this.path);
  final String path;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAudioBackend implements AudioBackend {
  @override
  bool isInitialized = false;
  final Map<String, AudioSource> sources = {};
  final Map<SoundHandle, AudioSource> voices = {};
  final Set<SoundHandle> started = {};
  final Map<SoundHandle, double> speeds = {};
  final List<String> loadRequests = [];
  final List<SoundHandle> stopped = [];
  int disposeCount = 0;
  int initializeCount = 0;
  int _nextHandle = 1;
  SoundHandle? lastHandle;
  Completer<void>? initializeGate;
  Completer<SoundHandle>? playGate;
  Future<AudioSource> Function(String path)? onLoad;

  @override
  Future<void> initialize() async {
    initializeCount++;
    if (initializeGate != null) await initializeGate!.future;
    isInitialized = true;
  }

  @override
  Future<AudioSource> loadAsset(String path) async {
    loadRequests.add(path);
    if (onLoad != null) return onLoad!(path);
    return sources.putIfAbsent(path, () => FakeAudioSource(path));
  }

  @override
  Future<SoundHandle> playPaused(AudioSource source, double volume) async {
    final handle = SoundHandle(_nextHandle++);
    lastHandle = handle;
    voices[handle] = source;
    return playGate == null ? handle : playGate!.future;
  }

  @override
  void resume(SoundHandle handle, double speed) {
    started.add(handle);
    speeds[handle] = speed;
  }

  @override
  bool isVoiceValid(SoundHandle handle) => voices.containsKey(handle);

  @override
  Future<void> stop(SoundHandle handle) async {
    stopped.add(handle);
    voices.remove(handle);
    started.remove(handle);
  }

  @override
  void applyToneMode(ToneMode mode) {}

  @override
  Future<void> disposeAllSources() async {
    disposeCount++;
    sources.clear();
    voices.clear();
    started.clear();
  }

  @override
  void deinitialize() => isInitialized = false;
}

class CueClock {
  final List<Completer<void>> cues = [];

  Future<void> delay(Duration duration) {
    final gate = Completer<void>();
    cues.add(gate);
    return gate.future;
  }
}
