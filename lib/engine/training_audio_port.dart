/// Minimal audio contract needed by [TrainingEngine].
///
/// Implementations must not require third-party plugin initialization in
/// their constructor, so that pure-Dart unit-test fakes can implement
/// this port without triggering native-library loads.
abstract class TrainingAudioPort {
  bool get isReady;
  Future<void> playNote(int midiNote);

  /// Stop all currently playing voices. Callers must be able to invoke
  /// this safely even when nothing is playing.
  Future<void> stopAll();
}
