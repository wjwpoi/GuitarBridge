import Foundation
import SwiftUI
#if os(iOS)
import UserNotifications
#endif

@MainActor
class DailyGoalManager: ObservableObject {
    static let shared = DailyGoalManager()
    
    // Goal settings
    @Published var targetMinutes: Int {
        didSet { UserDefaults.standard.set(targetMinutes, forKey: "targetMinutes") }
    }
    
    @Published var targetQuestions: Int {
        didSet { UserDefaults.standard.set(targetQuestions, forKey: "targetQuestions") }
    }
    
    @Published var reminderEnabled: Bool {
        didSet { UserDefaults.standard.set(reminderEnabled, forKey: "reminderEnabled") }
    }
    
    @Published var reminderHour: Int {
        didSet { UserDefaults.standard.set(reminderHour, forKey: "reminderHour") }
    }
    
    // Today's progress
    @Published var todayMinutes: Int = 0
    @Published var todayQuestions: Int = 0
    @Published var todaySessions: Int = 0
    
    // Streak
    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0
    
    // Date tracking
    private let lastPracticeDateKey = "lastPracticeDate"
    private let streakKey = "currentStreak"
    private let longestStreakKey = "longestStreak"
    
    init() {
        targetMinutes = UserDefaults.standard.object(forKey: "targetMinutes") as? Int ?? 10
        targetQuestions = UserDefaults.standard.object(forKey: "targetQuestions") as? Int ?? 20
        reminderEnabled = UserDefaults.standard.bool(forKey: "reminderEnabled")
        reminderHour = UserDefaults.standard.object(forKey: "reminderHour") as? Int ?? 20
        
        loadStreak()
        checkAndResetDaily()
    }
    
    // MARK: - Progress
    
    var minutesProgress: Double {
        guard targetMinutes > 0 else { return 0 }
        return min(Double(todayMinutes) / Double(targetMinutes), 1.0)
    }
    
    var questionsProgress: Double {
        guard targetQuestions > 0 else { return 0 }
        return min(Double(todayQuestions) / Double(targetQuestions), 1.0)
    }
    
    var overallProgress: Double {
        return (minutesProgress + questionsProgress) / 2.0
    }
    
    var isGoalReached: Bool {
        return todayMinutes >= targetMinutes && todayQuestions >= targetQuestions
    }
    
    var remainingMinutes: Int {
        return max(0, targetMinutes - todayMinutes)
    }
    
    var remainingQuestions: Int {
        return max(0, targetQuestions - todayQuestions)
    }
    
    // MARK: - Recording
    
    func recordPractice(duration: TimeInterval, questions: Int) {
        todayMinutes += Int(duration / 60)
        todayQuestions += questions
        todaySessions += 1
        
        savePracticeDate()
        
        if isGoalReached {
            checkStreak()
        }
    }
    
    // MARK: - Streak Management
    
    private func loadStreak() {
        currentStreak = UserDefaults.standard.integer(forKey: streakKey)
        longestStreak = UserDefaults.standard.integer(forKey: longestStreakKey)
    }
    
    private func savePracticeDate() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        UserDefaults.standard.set(today, forKey: lastPracticeDateKey)
    }
    
    private func checkStreak() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        let lastDate = UserDefaults.standard.string(forKey: lastPracticeDateKey)
        
        if lastDate == today {
            // Already practiced today, streak continues
            return
        }
        
        // Check if yesterday
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let yesterdayString = formatter.string(from: yesterday)
        
        if lastDate == yesterdayString {
            currentStreak += 1
        } else {
            currentStreak = 1
        }
        
        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }
        
        UserDefaults.standard.set(currentStreak, forKey: streakKey)
        UserDefaults.standard.set(longestStreak, forKey: longestStreakKey)
    }
    
    private func checkAndResetDaily() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        let lastDate = UserDefaults.standard.string(forKey: "lastPracticeDate")
        
        if lastDate != today {
            // New day, reset counters
            todayMinutes = 0
            todayQuestions = 0
            todaySessions = 0
        }
    }
    
    // MARK: - Reminders
    
    func scheduleReminder() {
        #if os(iOS)
        guard reminderEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "🎸 练习时间到！"
        content.body = "今天的吉他练习目标还没有完成哦，快来练一会儿吧！"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = reminderHour
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "dailyGoalReminder",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
        #endif
    }
    
    func cancelReminder() {
        #if os(iOS)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["dailyGoalReminder"])
        #endif
    }
}
