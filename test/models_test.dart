import 'package:flutter_test/flutter_test.dart';
import 'package:guitar_bridge/models/note.dart';
import 'package:guitar_bridge/models/scale.dart';
import 'package:guitar_bridge/models/tuning.dart';
import 'package:guitar_bridge/core/guitar_math.dart';

void main() {
  group('IntervalType', () {
    test('all 13 intervals have correct semitone counts', () {
      expect(IntervalType.unison.semitones, 0);
      expect(IntervalType.minorSecond.semitones, 1);
      expect(IntervalType.majorSecond.semitones, 2);
      expect(IntervalType.minorThird.semitones, 3);
      expect(IntervalType.majorThird.semitones, 4);
      expect(IntervalType.perfectFourth.semitones, 5);
      expect(IntervalType.tritone.semitones, 6);
      expect(IntervalType.perfectFifth.semitones, 7);
      expect(IntervalType.minorSixth.semitones, 8);
      expect(IntervalType.majorSixth.semitones, 9);
      expect(IntervalType.minorSeventh.semitones, 10);
      expect(IntervalType.majorSeventh.semitones, 11);
      expect(IntervalType.octave.semitones, 12);
    });

    test('Chinese names are not empty', () {
      for (final i in IntervalType.values) {
        expect(i.chineseName.isNotEmpty, true);
        expect(i.abbreviation.isNotEmpty, true);
      }
    });
  });

  group('GuitarMath - Interval Calculation', () {
    test('intervalBetween returns correct intervals for common cases', () {
      expect(GuitarMath.intervalBetween(60, 64), IntervalType.majorThird);
      expect(GuitarMath.intervalBetween(60, 67), IntervalType.perfectFifth);
      expect(GuitarMath.intervalBetween(60, 72), IntervalType.octave);
      expect(GuitarMath.intervalBetween(60, 61), IntervalType.minorSecond);
      expect(GuitarMath.intervalBetween(60, 66), IntervalType.tritone);
      expect(GuitarMath.intervalBetween(60, 69), IntervalType.majorSixth);
    });

    test('intervalBetween works regardless of octave', () {
      expect(GuitarMath.intervalBetween(48, 55), IntervalType.perfectFifth);
      expect(GuitarMath.intervalBetween(72, 79), IntervalType.perfectFifth);
      expect(GuitarMath.intervalBetween(60, 67), IntervalType.perfectFifth);
    });

    test('semitonesBetween returns absolute difference', () {
      expect(GuitarMath.semitonesBetween(60, 64), 4);
      expect(GuitarMath.semitonesBetween(64, 60), 4);
      expect(GuitarMath.semitonesBetween(60, 60), 0);
      expect(GuitarMath.semitonesBetween(40, 88), 48); // full guitar range
    });

    test('midiToFrequency produces correct standard values', () {
      expect(GuitarMath.midiToFrequency(69), closeTo(440.0, 0.1));
      expect(GuitarMath.midiToFrequency(81), closeTo(880.0, 0.1));
      expect(GuitarMath.midiToFrequency(57), closeTo(220.0, 0.1));
      expect(GuitarMath.midiToFrequency(60), closeTo(261.63, 0.5));
    });

    test('frequencyToMidi rounds correctly', () {
      expect(GuitarMath.frequencyToMidi(440.0), 69);
      expect(GuitarMath.frequencyToMidi(880.0), 81);
      expect(GuitarMath.frequencyToMidi(261.63), closeTo(60, 1)); // slightly off due to rounding
    });

    test('noteNameAt returns correct note names for all 12 semitones', () {
      expect(GuitarMath.noteNameAt(60), NoteName.c);
      expect(GuitarMath.noteNameAt(61), NoteName.cSharp);
      expect(GuitarMath.noteNameAt(62), NoteName.d);
      expect(GuitarMath.noteNameAt(63), NoteName.dSharp);
      expect(GuitarMath.noteNameAt(64), NoteName.e);
      expect(GuitarMath.noteNameAt(65), NoteName.f);
      expect(GuitarMath.noteNameAt(66), NoteName.fSharp);
      expect(GuitarMath.noteNameAt(67), NoteName.g);
      expect(GuitarMath.noteNameAt(68), NoteName.gSharp);
      expect(GuitarMath.noteNameAt(69), NoteName.a);
      expect(GuitarMath.noteNameAt(70), NoteName.aSharp);
      expect(GuitarMath.noteNameAt(71), NoteName.b);
    });

    test('noteAndOctave splits correctly', () {
      final (name, octave) = GuitarMath.noteAndOctave(60);
      expect(name, NoteName.c);
      expect(octave, 4);
    });

    test('fretRatio at 12th fret is exactly 0.5', () {
      expect(GuitarMath.fretRatio(12), closeTo(0.5, 0.0001));
    });

    test('fretRatio at 0th fret is 0', () {
      expect(GuitarMath.fretRatio(0), closeTo(0.0, 0.0001));
    });

    test('fretDistance calculates based on scale length', () {
      final d12 = GuitarMath.fretDistance(12, scaleLength: 648.0);
      expect(d12, closeTo(324.0, 0.1)); // half of 648mm
    });
  });

  group('KeySignature', () {
    test('degreeOf returns correct degrees for C major', () {
      final cMajor = KeySignature(NoteName.c, ScaleType.major);
      expect(cMajor.degreeOf(60), 1); // C = I
      expect(cMajor.degreeOf(62), 2); // D = II
      expect(cMajor.degreeOf(64), 3); // E = III
      expect(cMajor.degreeOf(65), 4); // F = IV
      expect(cMajor.degreeOf(67), 5); // G = V
      expect(cMajor.degreeOf(69), 6); // A = VI
      expect(cMajor.degreeOf(71), 7); // B = VII
    });

    test('degreeOf returns null for chromatic notes in C major', () {
      final cMajor = KeySignature(NoteName.c, ScaleType.major);
      expect(cMajor.degreeOf(61), null); // C#
      expect(cMajor.degreeOf(63), null); // D#
      expect(cMajor.degreeOf(66), null); // F#
      expect(cMajor.degreeOf(68), null); // G#
      expect(cMajor.degreeOf(70), null); // A#
    });

    test('degreeOf works for A minor (C major relative)', () {
      final aMinor = KeySignature(NoteName.a, ScaleType.naturalMinor);
      expect(aMinor.degreeOf(69), 1); // A = I
      expect(aMinor.degreeOf(71), 2); // B = II
      expect(aMinor.degreeOf(60), 3); // C = III
      expect(aMinor.degreeOf(62), 4); // D = IV
      expect(aMinor.degreeOf(64), 5); // E = V
      expect(aMinor.degreeOf(65), 6); // F = VI
      expect(aMinor.degreeOf(67), 7); // G = VII
    });

    test('degreeOf works for G major', () {
      final gMajor = KeySignature(NoteName.g, ScaleType.major);
      expect(gMajor.degreeOf(67), 1); // G = I
      expect(gMajor.degreeOf(69), 2); // A = II
      expect(gMajor.degreeOf(71), 3); // B = III
      expect(gMajor.degreeOf(60), 4); // C = IV (octave up)
      expect(gMajor.degreeOf(62), 5); // D = V
      expect(gMajor.degreeOf(64), 6); // E = VI
      expect(gMajor.degreeOf(66), 7); // F# = VII
    });

    test('degreeOf handles all octaves correctly', () {
      final cMajor = KeySignature(NoteName.c, ScaleType.major);
      expect(cMajor.degreeOf(48), 1); // C3 = I
      expect(cMajor.degreeOf(60), 1); // C4 = I
      expect(cMajor.degreeOf(72), 1); // C5 = I
      expect(cMajor.degreeOf(84), 1); // C6 = I
    });

    test('notesInKey returns correct scale for C major', () {
      final cMajor = KeySignature(NoteName.c, ScaleType.major);
      final notes = cMajor.notesInKey(octave: 4);
      expect(notes, [60, 62, 64, 65, 67, 69, 71]);
    });

    test('pentatonic scales have 5 notes', () {
      final cMajPent = KeySignature(NoteName.c, ScaleType.majorPentatonic);
      final cMinPent = KeySignature(NoteName.c, ScaleType.minorPentatonic);
      expect(cMajPent.notesInKey().length, 5);
      expect(cMinPent.notesInKey().length, 5);
    });

    test('all 12 scale types produce valid note arrays', () {
      for (final scale in ScaleType.values) {
        final ks = KeySignature(NoteName.c, scale);
        final notes = ks.notesInKey();
        expect(notes.isNotEmpty, true, reason: '${scale.chineseName} should have notes');
        expect(notes.first % 12, NoteName.c.index, reason: '${scale.chineseName} should start with C');
      }
    });
  });

  group('Tuning', () {
    test('standard tuning has 6 strings', () {
      expect(Tuning.standard.stringCount, 6);
      expect(Tuning.standard.openStringNotes.length, 6);
    });

    test('all tunings have 6 strings', () {
      for (final t in Tuning.all) {
        expect(t.stringCount, 6, reason: '${t.name} should have 6 strings');
      }
    });

    test('standard open string MIDI values', () {
      final std = Tuning.standard;
      expect(std.noteAt(5, 0), 40); // Low E
      expect(std.noteAt(4, 0), 45); // A
      expect(std.noteAt(3, 0), 50); // D
      expect(std.noteAt(2, 0), 55); // G
      expect(std.noteAt(1, 0), 59); // B
      expect(std.noteAt(0, 0), 64); // High E
    });

    test('5th fret on each string equals next string open (except G->B)', () {
      final std = Tuning.standard;
      expect(std.noteAt(5, 5), 45); // Low E 5th = A
      expect(std.noteAt(4, 5), 50); // A 5th = D
      expect(std.noteAt(3, 5), 55); // D 5th = G
      expect(std.noteAt(2, 4), 59); // G 4th = B (not 5th!)
      expect(std.noteAt(1, 5), 64); // B 5th = High E
    });

    test('12th fret is one octave above open', () {
      final std = Tuning.standard;
      for (int s = 0; s < 6; s++) {
        expect(std.noteAt(s, 12), std.noteAt(s, 0) + 12);
      }
    });

    test('findNotePositions finds E4 in multiple locations', () {
      final std = Tuning.standard;
      final positions = std.findNotePositions(64); // E4
      // 1st string open, 2nd string 5th, 3rd string 9th, 4th string 14th...
      expect(positions, contains((0, 0)));
      expect(positions, contains((1, 5)));
      expect(positions, contains((2, 9)));
    });

    test('findNotePositions respects maxFret', () {
      final std = Tuning.standard;
      final allPositions = std.findNotePositions(64, maxFret: 22);
      final limitedPositions = std.findNotePositions(64, maxFret: 4);
      expect(limitedPositions.length, lessThan(allPositions.length));
    });

    test('Drop D lowers 6th string by 2 semitones', () {
      expect(Tuning.dropD.noteAt(5, 0), 38); // D2 instead of E2
      expect(Tuning.dropD.noteAt(4, 0), 45); // A stays same
    });

    test('DADGAD has open strings forming Dsus4', () {
      final d = Tuning.dadgad;
      expect(d.noteAt(5, 0) % 12, NoteName.d.index); // D
      expect(d.noteAt(4, 0) % 12, NoteName.a.index); // A
      expect(d.noteAt(3, 0) % 12, NoteName.d.index); // D
      expect(d.noteAt(2, 0) % 12, NoteName.g.index); // G
      expect(d.noteAt(1, 0) % 12, NoteName.a.index); // A
      expect(d.noteAt(0, 0) % 12, NoteName.d.index); // D
    });
  });

  group('GuitarMath - Fretboard Queries', () {
    test('findNoteOnFretboard locates open E on standard', () {
      final positions = GuitarMath.findNoteOnFretboard(64, Tuning.standard);
      expect(positions, contains((0, 0)));
    });

    test('findNoteOnFretboard finds low E (40) only on 6th string', () {
      final positions = GuitarMath.findNoteOnFretboard(40, Tuning.standard);
      expect(positions.length, 1);
      expect(positions.first, (5, 0));
    });

    test('isInKey correctly identifies notes in C major', () {
      final cMajor = KeySignature(NoteName.c, ScaleType.major);
      expect(GuitarMath.isInKey(60, cMajor), true);  // C
      expect(GuitarMath.isInKey(62, cMajor), true);  // D
      expect(GuitarMath.isInKey(61, cMajor), false); // C#
      expect(GuitarMath.isInKey(66, cMajor), false); // F#
    });

    test('degreeDifference calculates correctly in C major', () {
      final cMajor = KeySignature(NoteName.c, ScaleType.major);
      expect(GuitarMath.degreeDifference(cMajor, 60, 64), 3); // C->E = 3rd
      expect(GuitarMath.degreeDifference(cMajor, 60, 67), 5); // C->G = 5th
      expect(GuitarMath.degreeDifference(cMajor, 67, 60), 4); // G->C = 4th
    });
  });
}
