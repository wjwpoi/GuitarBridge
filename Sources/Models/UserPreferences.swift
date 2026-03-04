import Foundation
import SwiftData

@Model
final class UserPreferences {
    var id: UUID
    var preferredTuning: String
    var preferredTone: String
    var volume: Float
    var hapticFeedbackEnabled: Bool
    var showNoteNames: Bool
    var showFretNumbers: Bool
    var dailyGoal: Int
    var streakDays: Int
    var lastPracticeDate: Date?
    var totalPracticeTime: TimeInterval

    init() {
        self.id = UUID()
        self.preferredTuning = "Standard"
        self.preferredTone = "Clean"
        self.volume = 0.8
        self.hapticFeedbackEnabled = true
        self.showNoteNames = true
        self.showFretNumbers = true
        self.dailyGoal = 20
        self.streakDays = 0
        self.lastPracticeDate = nil
        self.totalPracticeTime = 0
    }

    func updateStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let lastDate = lastPracticeDate {
            let lastDay = calendar.startOfDay(for: lastDate)
            let daysDifference = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0

            if daysDifference == 1 {
                streakDays += 1
            } else if daysDifference > 1 {
                streakDays = 1
            }
        } else {
            streakDays = 1
        }

        lastPracticeDate = Date()
    }

    func addPracticeTime(_ duration: TimeInterval) {
        totalPracticeTime += duration
        updateStreak()
    }

    var formattedTotalTime: String {
        let hours = Int(totalPracticeTime) / 3600
        let minutes = (Int(totalPracticeTime) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    var streakDescription: String {
        if streakDays == 0 {
            return "Start practicing to build a streak!"
        } else if streakDays == 1 {
            return "1 day streak"
        } else {
            return "\(streakDays) day streak"
        }
    }
}
