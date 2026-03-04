import SwiftUI

struct ProManager {
    static var isPro: Bool {
        get { UserDefaults.standard.bool(forKey: "isPro") }
        set { UserDefaults.standard.set(newValue, forKey: "isPro") }
    }
    
    static func unlockPro() {
        isPro = true
    }
    
    static func lockPro() {
        isPro = false
    }
    
    // Pro features
    static var advancedTonesAvailable: [ToneMode] {
        if isPro {
            return ToneMode.allCases
        }
        return [.clean] // Only clean is free
    }
    
    static func isToneUnlocked(_ tone: ToneMode) -> Bool {
        return advancedTonesAvailable.contains(tone)
    }
}
