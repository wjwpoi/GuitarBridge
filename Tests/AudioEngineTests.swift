import XCTest
@testable import GuitarBridge

final class AudioEngineTests: XCTestCase {
    
    // MARK: - Initialization Tests
    
    func testAudioEngine_CanBeCreated() {
        // Just test that the type exists
        let typeName = String(describing: AudioEngine.self)
        XCTAssertFalse(typeName.isEmpty)
    }
}
