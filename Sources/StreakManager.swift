import Foundation
import SwiftData

@MainActor
class StreakManager: ObservableObject {
    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0
    @Published var totalPracticeDays: Int = 0
    @Published var isStreakActive: Bool = false
    
    private var modelContext: ModelContext?
    private var streak: PracticeStreak?
    
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadStreak()
    }
    
    private func loadStreak() {
        guard let context = modelContext else { return }
        
        let descriptor = FetchDescriptor<PracticeStreak>()
        
        do {
            let streaks = try context.fetch(descriptor)
            if let existingStreak = streaks.first {
                self.streak = existingStreak
                self.currentStreak = existingStreak.currentStreak
                self.longestStreak = existingStreak.longestStreak
                self.totalPracticeDays = existingStreak.totalPracticeDays
                self.isStreakActive = existingStreak.isStreakActive
            } else {
                // Create new streak
                let newStreak = PracticeStreak()
                context.insert(newStreak)
                try context.save()
                self.streak = newStreak
            }
        } catch {
            #if DEBUG
            print("Failed to load streak: \(error)")
            #endif
        }
    }
    
    func recordPractice() {
        guard let streak = streak else { return }
        
        streak.updateStreak()
        
        do {
            try modelContext?.save()
            self.currentStreak = streak.currentStreak
            self.longestStreak = streak.longestStreak
            self.totalPracticeDays = streak.totalPracticeDays
            self.isStreakActive = streak.isStreakActive
        } catch {
            #if DEBUG
            print("Failed to save streak: \(error)")
            #endif
        }
    }
}
