/// Minimal audio contract needed by [TrainingEngine].
///
/// Implementations must not require third-party plugin initialization in
/// their constructor, so that pure-Dart unit-test fakes can implement
/// this port without triggering native-library loads.
abstract class TrainingAudioPort {
  bool get isReady;

  /// Plays one pitch and completes when its audible cue is finished.
  ///
  /// Returns false when no trustworthy cue reached the audio backend. Training
  /// callers must not advance into an answer state after a false result.
  Future<bool> playNote(int midiNote);

  /// Stop all currently playing voices. Callers must be able to invoke
  /// this safely even when nothing is playing.
  Future<void> stopAll();
}
