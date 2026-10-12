import 'dart:async';

import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guitar_bridge/engine/audio_engine.dart';
import 'package:guitar_bridge/engine/sample_config.dart';

import 'support/fake_audio_backend.dart';

Future<void> settleAudio() => Future<void>.delayed(Duration.zero);

void main() {
  late FakeAudioBackend backend;
  late CueClock clock;
  late AudioEngine engine;
  var disposed = false;

  setUp(() async {
    disposed = false;
    backend = FakeAudioBackend();
    clock = CueClock();
    engine = AudioEngine(backend: backend, delay: clock.delay);
    await engine.initialize();
  });

  tearDown(() async {
    for (final cue in clock.cues) {
      if (!cue.isCompleted) cue.complete();
    }
    await engine.disposeEngine();
    if (!disposed) engine.dispose();
    await settleAudio();
  });

  test('uses A4 as the 440 Hz reference', () {
    expect(AudioEngine.frequencyForMidi(69), closeTo(440.0, 0.000001));
  });

  test('maps middle C to the standard equal-temperament frequency', () {
    expect(AudioEngine.frequencyForMidi(60), closeTo(261.625565, 0.000001));
  });

  test('one octave doubles the frequency', () {
    expect(
      AudioEngine.frequencyForMidi(69) / AudioEngine.frequencyForMidi(57),
      closeTo(2.0, 0.000001),
    );
  });

  test('a cue resumes at the requested rate and stops its own voice', () async {
    final playback = engine.playNote(69);
    await settleAudio();
    final handle = backend.lastHandle!;
    expect(backend.started, contains(handle));
    expect(backend.speeds[handle], SampleConfig.playbackSpeedForMidi(69));
    clock.cues.single.complete();
    expect(await playback, true);
    expect(backend.voices, isEmpty);
  });

  test(
    'old cleanup cannot dispose the next voice sharing its sample',
    () async {
      final first = engine.playNote(64);
      await settleAudio();
      final firstHandle = backend.lastHandle!;
      final second = engine.playNote(65);
      await settleAudio();
      final secondHandle = backend.lastHandle!;
      expect(backend.loadRequests, hasLength(1));
      expect(backend.isVoiceValid(firstHandle), false);
      clock.cues[0].complete();
      expect(await first, false);
      expect(backend.isVoiceValid(secondHandle), true);
      expect(backend.disposeCount, 0);
      expect(engine.isPlaying, true);
      clock.cues[1].complete();
      expect(await second, true);
    },
  );

  test('stopAll cancels a pending load before it starts any voice', () async {
    final load = Completer<AudioSource>();
    backend.onLoad = (_) => load.future;
    final playback = engine.playNote(64);
    await settleAudio();
    await engine.stopAll();
    load.complete(FakeAudioSource('delayed'));
    expect(await playback, false);
    expect(backend.lastHandle, isNull);
    expect(engine.isPlaying, false);
    expect(engine.isReady, true);
  });

  test('a slower old load cannot overlap a newer cue', () async {
    final oldLoad = Completer<AudioSource>();
    backend.onLoad = (path) => path.endsWith('76_v100_rr1.wav')
        ? oldLoad.future
        : Future.value(FakeAudioSource(path));
    final old = engine.playNote(64);
    await settleAudio();
    final current = engine.playNote(70);
    await settleAudio();
    final handle = backend.lastHandle!;
    oldLoad.complete(FakeAudioSource('old'));
    expect(await old, false);
    expect(backend.started, {handle});
    clock.cues.single.complete();
    expect(await current, true);
  });

  test('a stale load error does not poison a newer cue', () async {
    final oldLoad = Completer<AudioSource>();
    backend.onLoad = (path) => path.endsWith('76_v100_rr1.wav')
        ? oldLoad.future
        : Future.value(FakeAudioSource(path));
    final old = engine.playNote(64);
    await settleAudio();
    final current = engine.playNote(70);
    await settleAudio();
    oldLoad.completeError(StateError('old asset failed'));
    expect(await old, false);
    expect(engine.isReady, true);
    expect(engine.error, isNull);
    clock.cues.single.complete();
    expect(await current, true);
  });

  test(
    'failed resources enter error and can be loaded again after retry',
    () async {
      backend.onLoad = (_) async => throw StateError('asset missing');
      expect(await engine.playNote(64), false);
      expect(engine.state, AudioEngineState.error);
      backend.onLoad = null;
      await engine.initialize();
      final retry = engine.playNote(64);
      await settleAudio();
      clock.cues.single.complete();
      expect(await retry, true);
      expect(backend.loadRequests, hasLength(2));
    },
  );

  test(
    'cancellation while acquiring a paused voice never resumes it',
    () async {
      backend.playGate = Completer<SoundHandle>();
      final playback = engine.playNote(64);
      await settleAudio();
      final handle = backend.lastHandle!;
      await engine.stopAll();
      backend.playGate!.complete(handle);
      expect(await playback, false);
      expect(backend.started, isEmpty);
      expect(backend.voices, isEmpty);
    },
  );

  test(
    'dispose waits for pending loads and cannot resurrect playback',
    () async {
      final load = Completer<AudioSource>();
      backend.onLoad = (_) => load.future;
      final playback = engine.playNote(64);
      await settleAudio();
      engine.dispose();
      disposed = true;
      load.complete(FakeAudioSource('late'));
      expect(await playback, false);
      await engine.disposeEngine();
      expect(backend.disposeCount, 1);
      expect(backend.isInitialized, false);
      expect(engine.state, AudioEngineState.uninitialized);
    },
  );

  test('dispose during initialization cannot restore ready state', () async {
    await engine.disposeEngine();
    backend.initializeGate = Completer<void>();
    final initialization = engine.initialize();
    await settleAudio();
    engine.dispose();
    disposed = true;
    backend.initializeGate!.complete();
    await initialization;
    await engine.disposeEngine();
    expect(engine.state, AudioEngineState.uninitialized);
    expect(backend.isInitialized, false);
  });

  test('concurrent initialization opens the backend once', () async {
    await engine.disposeEngine();
    backend.initializeGate = Completer<void>();
    final first = engine.initialize();
    final second = engine.initialize();
    await settleAudio();
    final beforeRelease = backend.initializeCount;
    backend.initializeGate!.complete();
    await Future.wait([first, second]);
    expect(beforeRelease, 2); // One original initialization plus one retry.
    expect(backend.initializeCount, beforeRelease);
  });

  test(
    'reinitializing waits for shutdown to finish pending resource loads',
    () async {
      final load = Completer<AudioSource>();
      backend.onLoad = (_) => load.future;
      final playback = engine.playNote(64);
      await settleAudio();
      final closing = engine.disposeEngine();
      final reopening = engine.initialize();
      await settleAudio();
      expect(backend.initializeCount, 1);
      load.complete(FakeAudioSource('late'));
      expect(await playback, false);
      await closing;
      await reopening;
      expect(engine.isReady, true);
      expect(backend.isInitialized, true);
    },
  );
}
