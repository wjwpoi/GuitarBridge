import XCTest
@testable import GuitarBridge

final class TuningManagerTests: XCTestCase {
    
    // MARK: - Tuning Enum Tests
    
    func testStandardTuning_Exists() {
        let tuning = Tuning.standard
        XCTAssertTrue(tuning.rawValue.contains("Standard"))
    }
    
    func testAllTunings_Exist() {
        XCTAssertGreaterThanOrEqual(Tuning.allCases.count, 5)
    }
    
    func testTuningRawValues() {
        XCTAssertTrue(Tuning.standard.rawValue.count > 0)
        XCTAssertTrue(Tuning.dadgad.rawValue.count > 0)
    }
}
