import Foundation
import SwiftData

@Model
final class PracticeRecord {
    var id: UUID
    var date: Date
    var intervalType: Int
    var correctAnswers: Int
    var totalAttempts: Int
    var duration: TimeInterval
    var tuningName: String
    var toneName: String

    init(
        intervalType: Int,
        correctAnswers: Int,
        totalAttempts: Int,
        duration: TimeInterval,
        tuningName: String,
        toneName: String
    ) {
        self.id = UUID()
        self.date = Date()
        self.intervalType = intervalType
        self.correctAnswers = correctAnswers
        self.totalAttempts = totalAttempts
        self.duration = duration
        self.tuningName = tuningName
        self.toneName = toneName
    }

    var accuracy: Double {
        guard totalAttempts > 0 else { return 0 }
        return Double(correctAnswers) / Double(totalAttempts) * 100
    }

    var intervalName: String {
        return "Interval \(intervalType)"
    }
}
