import Foundation

// MARK: - Tuning Enum
enum Tuning: String, CaseIterable, Identifiable {
    case standard = "Standard (EADGBE)"
    case dropD = "Drop D (DADGBE)"
    case dadgad = "DADGAD"
    case openG = "Open G (DGDGBD)"
    case openD = "Open D (DAD#F#AD)"
    case facgce = "FACGCE (Open G)"

    var id: String { rawValue }

    /// MIDI note numbers for the open string (fret 0) for each string (1-6)
    /// Standard: E4=64 (string 1), B3=59, G3=55, D3=50, A2=45, E2=40 (string 6)
    /// Array index 0 = string 1 (high E), index 5 = string 6 (low E)
    var openStringMidiNotes: [Int] {
        switch self {
        case .standard:
            return [64, 59, 55, 50, 45, 40]  // E4, B3, G3, D3, A2, E2 (high to low)
        case .dropD:
            return [64, 59, 55, 50, 45, 38]  // E4, B3, G3, D3, A2, D3
        case .dadgad:
            return [62, 57, 55, 50, 45, 38]  // D4, A3, G3, D3, A2, D3
        case .openG:
            return [62, 59, 55, 50, 55, 38]  // D4, B3, G3, D3, G3, D3
        case .openD:
            return [62, 57, 54, 50, 45, 38]  // D4, A3, F#3, D3, A2, D3
        case .facgce:
            return [64, 60, 55, 48, 45, 41]  // E4, C4, G3, C3, A2, F2
        }
    }

    /// String names for display (index 0 = string 1/high E, index 5 = string 6/low E)
    var stringNames: [String] {
        switch self {
        case .standard:
            return ["E", "B", "G", "D", "A", "E"]
        case .dropD:
            return ["E", "B", "G", "D", "A", "D"]
        case .dadgad:
            return ["D", "A", "G", "D", "A", "D"]
        case .openG:
            return ["D", "B", "G", "D", "G", "D"]
        case .openD:
            return ["D", "A", "F#", "D", "A", "D"]
        case .facgce:
            return ["E", "C", "G", "C", "A", "F"]
        }
    }
}

// MARK: - FretPosition Struct
struct FretPosition: Equatable, Hashable {
    let string: Int      // 1-6 (1 = high E, 6 = low E)
    let fret: Int       // 0-15
    let midiNote: Int   // Calculated MIDI note number
    
    /// Validated initializer - ensures string is 1-6 and fret is 0-15
    init?(string: Int, fret: Int, midiNote: Int) {
        guard string >= 1, string <= 6 else {
            return nil
        }
        guard fret >= 0, fret <= 15 else {
            return nil
        }
        self.string = string
        self.fret = fret
        self.midiNote = midiNote
    }
    
    /// Unchecked initializer for trusted sources (e.g., from GuitarMath.midiNote which validates)
    internal init(unchecked string: Int, fret: Int, midiNote: Int) {
        self.string = string
        self.fret = fret
        self.midiNote = midiNote
    }

    var frequency: Double {
        // MIDI note 69 = A4 = 440 Hz
        // Formula: f = 440 * 2^((midiNote - 69) / 12)
        return 440.0 * pow(2.0, Double(midiNote - 69) / 12.0)
    }

    var noteName: String {
        let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let octave = (midiNote / 12) - 1
        let noteIndex = midiNote % 12
        return "\(noteNames[noteIndex])\(octave)"
    }
    
    var simpleNoteName: String {
        let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let noteIndex = midiNote % 12
        return noteNames[noteIndex]
    }
}

// MARK: - GuitarMath Module
struct GuitarMath {
    /// Standard note names for MIDI notes (C = 0, C# = 1, ..., B = 11)
    static let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    
    /// Calculate MIDI note number for a given string and fret
    /// - Parameters:
    ///   - string: String number (1-6, where 1 = high E)
    ///   - fret: Fret number (0-15)
    ///   - tuning: The selected tuning
    /// - Returns: MIDI note number
    static func midiNote(for string: Int, fret: Int, tuning: Tuning) -> Int {
        guard string >= 1, string <= 6 else {
            return 0
        }
        guard fret >= 0, fret <= 15 else {
            return 0
        }

        let stringIndex = string - 1
        let openNote = tuning.openStringMidiNotes[stringIndex]
        let midiNote = openNote + fret

        return midiNote
    }

    /// Create a FretPosition for a given string and fret
    /// - Parameters:
    ///   - string: String number (1-6)
    ///   - fret: Fret number (0-15)
    ///   - tuning: The selected tuning
    /// - Returns: FretPosition with calculated MIDI note
    static func fretPosition(string: Int, fret: Int, tuning: Tuning) -> FretPosition {
        let midiNote = midiNote(for: string, fret: fret, tuning: tuning)
        return FretPosition(unchecked: string, fret: fret, midiNote: midiNote)
    }
}
