import Foundation
import SwiftData

@Model
final class PracticeStreak {
    var id: UUID
    var currentStreak: Int
    var longestStreak: Int
    var lastPracticeDate: Date?
    var totalPracticeDays: Int

    init() {
        self.id = UUID()
        self.currentStreak = 0
        self.longestStreak = 0
        self.lastPracticeDate = nil
        self.totalPracticeDays = 0
    }

    func updateStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let lastDate = lastPracticeDate {
            let lastPracticeDay = calendar.startOfDay(for: lastDate)
            let daysDifference = calendar.dateComponents([.day], from: lastPracticeDay, to: today).day ?? 0
            
            if daysDifference == 0 {
                // Already practiced today, no change
                return
            } else if daysDifference == 1 {
                // Consecutive day - increase streak
                currentStreak += 1
            } else {
                // Streak broken - reset
                currentStreak = 1
            }
        } else {
            // First time practicing
            currentStreak = 1
            totalPracticeDays = 1
        }
        
        lastPracticeDate = Date()
        
        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }
        
        if currentStreak == 1 {
            totalPracticeDays += 1
        }
    }

    var isStreakActive: Bool {
        guard let lastDate = lastPracticeDate else { return false }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastPracticeDay = calendar.startOfDay(for: lastDate)
        let daysDifference = calendar.dateComponents([.day], from: lastPracticeDay, to: today).day ?? 0
        return daysDifference <= 1
    }
}
