import Foundation
import SwiftUI

// MARK: - Achievement Type
enum AchievementType: String, CaseIterable, Identifiable, Codable {
    case firstPractice = "first_practice"
    case streak7 = "streak_7"
    case streak30 = "streak_30"
    case streak100 = "streak_100"
    case totalTime1Hour = "time_1h"
    case totalTime10Hours = "time_10h"
    case totalTime100Hours = "time_100h"
    case accuracy100 = "accuracy_100"
    case accuracy90Streak = "accuracy_90_streak"
    case chords10 = "chords_10"
    case scalesMastered = "scales_mastered"
    case perfectSession = "perfect_session"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .firstPractice: return "初学者"
        case .streak7: return "一周坚持"
        case .streak30: return "月度练习"
        case .streak100: return "百日达人"
        case .totalTime1Hour: return "1小时练习"
        case .totalTime10Hours: return "10小时练习"
        case .totalTime100Hours: return "100小时练习"
        case .accuracy100: return "满分通过"
        case .accuracy90Streak: return "90%连续"
        case .chords10: return "和弦达人"
        case .scalesMastered: return "音阶掌握"
        case .perfectSession: return "完美表现"
        }
    }
    
    var icon: String {
        switch self {
        case .firstPractice: return "🎯"
        case .streak7: return "🔥"
        case .streak30: return "📅"
        case .streak100: return "🏆"
        case .totalTime1Hour: return "⏱️"
        case .totalTime10Hours: return "🎸"
        case .totalTime100Hours: return "👑"
        case .accuracy100: return "💯"
        case .accuracy90Streak: return "📈"
        case .chords10: return "🎵"
        case .scalesMastered: return "🎼"
        case .perfectSession: return "⭐"
        }
    }
    
    var description: String {
        switch self {
        case .firstPractice: return "完成第一次练习"
        case .streak7: return "连续练习7天"
        case .streak30: return "连续练习30天"
        case .streak100: return "连续练习100天"
        case .totalTime1Hour: return "累计练习1小时"
        case .totalTime10Hours: return "累计练习10小时"
        case .totalTime100Hours: return "累计练习100小时"
        case .accuracy100: return "一次练习获得100%准确率"
        case .accuracy90Streak: return "连续10次练习准确率90%+"
        case .chords10: return "练习10种不同和弦"
        case .scalesMastered: return "掌握所有主要音阶"
        case .perfectSession: return "一次练习全部答对"
        }
    }
}

// MARK: - User Achievement
struct UserAchievement: Identifiable, Codable {
    let id: UUID
    let type: AchievementType
    let unlockedAt: Date
    var progress: Double  // 0.0 to 1.0
    
    init(type: AchievementType, progress: Double = 1.0) {
        self.id = UUID()
        self.type = type
        self.unlockedAt = Date()
        self.progress = progress
    }
}

// MARK: - Achievement Manager
@MainActor
class AchievementManager: ObservableObject {
    static let shared = AchievementManager()
    
    @Published var achievements: [UserAchievement] = []
    @Published var newAchievement: AchievementType?
    
    private let totalTimeKey = "totalPracticeTime"
    private let accuracy90StreakKey = "accuracy90Streak"
    private let chordsAttemptedKey = "chordsAttempted"
    private let sessionsCompletedKey = "sessionsCompleted"
    
    init() {
        loadAchievements()
    }
    
    // MARK: - Check Achievements
    
    func checkAllAchievements(
        streak: Int,
        totalTime: TimeInterval,
        accuracy: Double,
        chordsAttempted: Int,
        sessionCorrect: Int,
        sessionTotal: Int
    ) {
        var newUnlocked: [AchievementType] = []
        
        // First practice
        if !hasAchievement(.firstPractice) {
            unlock(.firstPractice)
            newUnlocked.append(.firstPractice)
        }
        
        // Streak achievements
        if streak >= 7 && !hasAchievement(.streak7) {
            unlock(.streak7)
            newUnlocked.append(.streak7)
        }
        
        if streak >= 30 && !hasAchievement(.streak30) {
            unlock(.streak30)
            newUnlocked.append(.streak30)
        }
        
        if streak >= 100 && !hasAchievement(.streak100) {
            unlock(.streak100)
            newUnlocked.append(.streak100)
        }
        
        // Time achievements
        let hours = totalTime / 3600
        if hours >= 1 && !hasAchievement(.totalTime1Hour) {
            unlock(.totalTime1Hour)
            newUnlocked.append(.totalTime1Hour)
        }
        
        if hours >= 10 && !hasAchievement(.totalTime10Hours) {
            unlock(.totalTime10Hours)
            newUnlocked.append(.totalTime10Hours)
        }
        
        if hours >= 100 && !hasAchievement(.totalTime100Hours) {
            unlock(.totalTime100Hours)
            newUnlocked.append(.totalTime100Hours)
        }
        
        // Accuracy achievements
        if accuracy == 100 && !hasAchievement(.accuracy100) {
            unlock(.accuracy100)
            newUnlocked.append(.accuracy100)
        }
        
        // Perfect session
        if sessionCorrect == sessionTotal && sessionTotal > 0 && !hasAchievement(.perfectSession) {
            unlock(.perfectSession)
            newUnlocked.append(.perfectSession)
        }
        
        // Chords attempted
        if chordsAttempted >= 10 && !hasAchievement(.chords10) {
            unlock(.chords10)
            newUnlocked.append(.chords10)
        }
        
        // Show first new achievement
        if let first = newUnlocked.first {
            newAchievement = first
        }
        
        saveAchievements()
    }
    
    // MARK: - Achievement Management
    
    func hasAchievement(_ type: AchievementType) -> Bool {
        achievements.contains { $0.type == type }
    }
    
    func unlock(_ type: AchievementType, progress: Double = 1.0) {
        guard !hasAchievement(type) else { return }
        
        let achievement = UserAchievement(type: type, progress: progress)
        achievements.append(achievement)
    }
    
    func updateProgress(_ type: AchievementType, progress: Double) {
        if let index = achievements.firstIndex(where: { $0.type == type }) {
            achievements[index].progress = progress
        } else {
            let achievement = UserAchievement(type: type, progress: progress)
            achievements.append(achievement)
        }
    }
    
    func dismissNewAchievement() {
        newAchievement = nil
    }
    
    // MARK: - Storage
    
    private func saveAchievements() {
        if let data = try? JSONEncoder().encode(achievements) {
            UserDefaults.standard.set(data, forKey: "achievements")
        }
    }
    
    private func loadAchievements() {
        if let data = UserDefaults.standard.data(forKey: "achievements"),
           let saved = try? JSONDecoder().decode([UserAchievement].self, from: data) {
            achievements = saved
        }
    }
    
    // MARK: - Stats
    
    var unlockedCount: Int { achievements.count }
    var totalCount: Int { AchievementType.allCases.count }
    
    var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(unlockedCount) / Double(totalCount)
    }
}

// MARK: - Achievement Detail View
struct AchievementDetailView: View {
    let achievement: UserAchievement
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            // Icon
            Text(achievement.type.icon)
                .font(.system(size: 60))
            
            // Title
            Text(achievement.type.title)
                .font(.title)
                .fontWeight(.bold)
            
            // Description
            Text(achievement.type.description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Unlock date
            Text("获得于 \(formatDate(achievement.unlockedAt))")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button("确定") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Achievement Badge View
struct AchievementBadgeView: View {
    let type: AchievementType
    let isUnlocked: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Text(type.icon)
                .font(.title)
                .opacity(isUnlocked ? 1 : 0.3)
            
            Text(type.title)
                .font(.caption2)
                .opacity(isUnlocked ? 1 : 0.5)
        }
        .frame(width: 60, height: 60)
        .background(isUnlocked ? Color.cyan.opacity(0.2) : Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}
