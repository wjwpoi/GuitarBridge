import XCTest
@testable import GuitarBridge

final class TrainingEngineTests: XCTestCase {
    
    // MARK: - Solfege Tests
    
    func testSolfegeNote_Intervals() {
        XCTAssertEqual(SolfegeNote.doFirst.intervalFromRoot, 0)
        XCTAssertEqual(SolfegeNote.mi.intervalFromRoot, 4)
        XCTAssertEqual(SolfegeNote.sol.intervalFromRoot, 7)
    }
    
    func testSolfegeNote_Count() {
        XCTAssertEqual(SolfegeNote.allCases.count, 7)
    }
    
    // MARK: - Difficulty Tests
    
    func testEasyDifficulty_IntervalRange() {
        let difficulty = Difficulty.easy
        XCTAssertTrue(difficulty.intervalRange.contains(0))
        XCTAssertTrue(difficulty.intervalRange.contains(7))
    }
    
    func testMediumDifficulty_IntervalRange() {
        let difficulty = Difficulty.medium
        XCTAssertTrue(difficulty.intervalRange.contains(4))  // Major 3rd
        XCTAssertTrue(difficulty.intervalRange.contains(11)) // Major 7th
    }
    
    func testHardDifficulty_AllIntervals() {
        let difficulty = Difficulty.hard
        XCTAssertEqual(difficulty.intervalRange.count, 7)
    }
    
    // MARK: - Training Mode Tests
    
    func testTrainingMode_Count() {
        XCTAssertEqual(TrainingMode.allCases.count, 3)
    }
    
    func testTrainingMode_Values() {
        XCTAssertTrue(TrainingMode.allCases.contains(.scaleDegrees))
        XCTAssertTrue(TrainingMode.allCases.contains(.intervals))
        XCTAssertTrue(TrainingMode.allCases.contains(.chords))
    }
}


    // MARK: - ScaleType Tests
    
    func testMajorScale_Intervals() {
        let scale = ScaleType.major
        XCTAssertEqual(scale.intervals, [0, 2, 4, 5, 7, 9, 11])
    }
    
    func testBluesScale_Intervals() {
        let scale = ScaleType.blues
        XCTAssertEqual(scale.intervals.count, 6)
        XCTAssertTrue(scale.intervals.contains(3)) // blue note
    }
    
    func testPentatonicMinor_Intervals() {
        let scale = ScaleType.pentatonicMinor
        XCTAssertEqual(scale.intervals, [0, 3, 5, 7, 10])
    }
    
    func testAllScales_HaveRoot() {
        for scale in ScaleType.allCases {
            XCTAssertTrue(scale.intervals.contains(0), "\(scale.rawValue) should contain root")
        }
    }
    
    // MARK: - Interval Calculation Tests
    
    func testIntervalCalculation() {
        let root = 60 // C4
        let intervals = [0, 2, 4, 5, 7, 9, 11]
        let expectedNotes = [60, 62, 64, 65, 67, 69, 71]
        
        for (index, interval) in intervals.enumerated() {
            let note = root + interval
            XCTAssertEqual(note, expectedNotes[index])
        }
    }
