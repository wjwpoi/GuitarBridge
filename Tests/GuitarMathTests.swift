import XCTest
@testable import GuitarBridge

final class GuitarMathTests: XCTestCase {
    
    // MARK: - Tuning Tests
    
    func testStandardTuning_MIDIValues() {
        let tuning = Tuning.standard
        XCTAssertEqual(tuning.openStringMidiNotes.count, 6)
        // Index 0 = string 1 = high E = 64
        XCTAssertEqual(tuning.openStringMidiNotes[0], 64) 
    }
    
    func testFACGCE_OpenGTuning() {
        let tuning = Tuning.facgce
        // Index 0 = string 1 = high E = 64
        XCTAssertEqual(tuning.openStringMidiNotes[0], 64) 
    }
    
    func testDADGAD_Tuning() {
        let tuning = Tuning.dadgad
        // Index 0 = string 1 = high D = 62
        XCTAssertEqual(tuning.openStringMidiNotes[0], 62) 
    }
    
    // MARK: - Fret Position Tests
    
    func testFretPosition_String6IsLowE() {
        let tuning = Tuning.standard
        // String 6 = index 5 = low E = 40
        let position = GuitarMath.fretPosition(string: 6, fret: 0, tuning: tuning)
        XCTAssertEqual(position.midiNote, 40) 
    }
    
    func testFretPosition_String1IsHighE() {
        let tuning = Tuning.standard
        // String 1 = index 0 = high E = 64
        let position = GuitarMath.fretPosition(string: 1, fret: 0, tuning: tuning)
        XCTAssertEqual(position.midiNote, 64)
    }
    
    func testFretPosition_12FretOctave() {
        let tuning = Tuning.standard
        let openE = GuitarMath.fretPosition(string: 6, fret: 0, tuning: tuning)
        let octaveE = GuitarMath.fretPosition(string: 6, fret: 12, tuning: tuning)
        XCTAssertEqual(octaveE.midiNote - openE.midiNote, 12)
    }
    
    func testAllStrings_WithinValidRange() {
        let tuning = Tuning.standard
        for string in 1...6 {
            for fret in 0...15 {
                let position = GuitarMath.fretPosition(string: string, fret: fret, tuning: tuning)
                XCTAssertGreaterThanOrEqual(position.midiNote, 20)
                XCTAssertLessThanOrEqual(position.midiNote, 100)
            }
        }
    }
    
    func testMidiNote_Calculation() {
        let tuning = Tuning.standard
        let midi = GuitarMath.midiNote(for: 6, fret: 0, tuning: tuning)
        XCTAssertEqual(midi, 40) // Low E (string 6 = index 5)
    }
    
    func testFretPosition_LowE() {
        let tuning = Tuning.standard
        let position = GuitarMath.fretPosition(string: 6, fret: 0, tuning: tuning)
        XCTAssertEqual(position.noteName, "E2")
    }
}
