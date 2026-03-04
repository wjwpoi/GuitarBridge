import SwiftUI
import SwiftData

@main
struct GuitarBridgeApp: App {
    @StateObject private var firstLaunch = FirstLaunchManager.shared
    
    var body: some Scene {
        WindowGroup {
            if firstLaunch.hasLaunched {
                ContentView()
            } else {
                OnboardingView {
                    firstLaunch.markLaunched()
                }
            }
        }
        .modelContainer(for: [PracticeRecord.self, PracticeStreak.self])
    }
}
