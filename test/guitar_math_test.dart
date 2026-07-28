import 'package:flutter_test/flutter_test.dart';
import 'package:guitar_bridge/models/note.dart';
import 'package:guitar_bridge/models/scale.dart';
import 'package:guitar_bridge/models/tuning.dart';
import 'package:guitar_bridge/core/guitar_math.dart';

void main() {
  group('GuitarMath', () {
    test('intervalBetween returns correct intervals', () {
      // C4(60) to E4(64) = Major Third (4 semitones)
      expect(GuitarMath.intervalBetween(60, 64), IntervalType.majorThird);
      // C4(60) to G4(67) = Perfect Fifth (7 semitones)
      expect(GuitarMath.intervalBetween(60, 67), IntervalType.perfectFifth);
      // C4(60) to C5(72) = Octave (12 semitones)
      expect(GuitarMath.intervalBetween(60, 72), IntervalType.octave);
      // C4(60) to C#4(61) = Minor Second (1 semitones)
      expect(GuitarMath.intervalBetween(60, 61), IntervalType.minorSecond);
    });

    test('semitonesBetween returns absolute difference', () {
      expect(GuitarMath.semitonesBetween(60, 64), 4);
      expect(GuitarMath.semitonesBetween(64, 60), 4);
      expect(GuitarMath.semitonesBetween(60, 60), 0);
    });

    test('midiToFrequency produces correct values', () {
      // A4(69) = 440Hz
      expect(GuitarMath.midiToFrequency(69), closeTo(440.0, 0.1));
      // A5(81) = 880Hz
      expect(GuitarMath.midiToFrequency(81), closeTo(880.0, 0.1));
    });

    test('noteNameAt returns correct note names', () {
      expect(GuitarMath.noteNameAt(60), NoteName.c); // C4
      expect(GuitarMath.noteNameAt(64), NoteName.e); // E4
      expect(GuitarMath.noteNameAt(67), NoteName.g); // G4
      expect(GuitarMath.noteNameAt(61), NoteName.cSharp); // C#4
    });
  });

  group('KeySignature', () {
    test('degreeOf returns correct scale degrees for C major', () {
      final cMajor = KeySignature(NoteName.c, ScaleType.major);
      expect(cMajor.degreeOf(60), 1); // C = I
      expect(cMajor.degreeOf(62), 2); // D = II
      expect(cMajor.degreeOf(64), 3); // E = III
      expect(cMajor.degreeOf(65), 4); // F = IV
      expect(cMajor.degreeOf(67), 5); // G = V
      expect(cMajor.degreeOf(69), 6); // A = VI
      expect(cMajor.degreeOf(71), 7); // B = VII
    });

    test('degreeOf returns null for notes outside the key', () {
      final cMajor = KeySignature(NoteName.c, ScaleType.major);
      expect(cMajor.degreeOf(61), null); // C# not in C major
      expect(cMajor.degreeOf(63), null); // D# not in C major
      expect(cMajor.degreeOf(66), null); // F# not in C major
    });
  });

  group('Tuning', () {
    test('standard tuning has correct open string notes', () {
      final std = Tuning.standard;
      expect(std.noteAt(5, 0), 40); // Low E = E2 = MIDI 40
      expect(std.noteAt(4, 0), 45); // A = A2 = MIDI 45
      expect(std.noteAt(3, 0), 50); // D = D3 = MIDI 50
      expect(std.noteAt(2, 0), 55); // G = G3 = MIDI 55
      expect(std.noteAt(1, 0), 59); // B = B3 = MIDI 59
      expect(std.noteAt(0, 0), 64); // High E = E4 = MIDI 64
    });

    test('noteAt calculates fretted notes correctly', () {
      final std = Tuning.standard;
      // Low E string, 5th fret = A2 = MIDI 45
      expect(std.noteAt(5, 5), 45);
      // A string, 5th fret = D3 = MIDI 50
      expect(std.noteAt(4, 5), 50);
    });

    test('findNotePositions finds multiple positions for open E', () {
      final std = Tuning.standard;
      // E4 = MIDI 64: open 1st string, 5th fret 2nd string, etc.
      final positions = std.findNotePositions(64);
      expect(positions, contains((0, 0))); // open high E
      expect(positions, contains((1, 5))); // B string 5th fret
    });
  });

  group('IntervalType', () {
    test('all intervals have correct semitone values', () {
      expect(IntervalType.unison.semitones, 0);
      expect(IntervalType.perfectFifth.semitones, 7);
      expect(IntervalType.octave.semitones, 12);
      expect(IntervalType.tritone.semitones, 6);
    });
  });

  group('NoteName', () {
    test('sharpName and flatName are correct', () {
      expect(NoteName.c.sharpName, 'C');
      expect(NoteName.cSharp.sharpName, 'C#');
      expect(NoteName.cSharp.flatName, 'Db');
      expect(NoteName.d.sharpName, 'D');
      expect(NoteName.dSharp.sharpName, 'D#');
      expect(NoteName.dSharp.flatName, 'Eb');
    });
  });
}
