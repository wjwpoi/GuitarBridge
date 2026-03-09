import SwiftUI
import SwiftData

struct StatsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PracticeRecord.date, order: .reverse) private var records: [PracticeRecord]
    @StateObject private var streakManager = StreakManager()
    @State private var showClearConfirmation = false
    
    // Computed stats
    private var totalSessions: Int { records.count }
    
    private var totalQuestions: Int {
        records.reduce(0) { $0 + $1.totalAttempts }
    }
    
    private var totalCorrect: Int {
        records.reduce(0) { $0 + $1.correctAnswers }
    }
    
    private var overallAccuracy: Double {
        guard totalQuestions > 0 else { return 0 }
        return Double(totalCorrect) / Double(totalQuestions) * 100
    }
    
    private var totalPracticeTime: TimeInterval {
        records.reduce(0) { $0 + $1.duration }
    }
    
    private var formattedPracticeTime: String {
        let hours = Int(totalPracticeTime) / 3600
        let minutes = (Int(totalPracticeTime) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private var bestStreak: Int {
        var best = 0
        var current = 0
        for record in records.sorted(by: { $0.date < $1.date }) {
            if record.accuracy >= 80 {
                current += 1
                best = max(best, current)
            } else {
                current = 0
            }
        }
        return best
    }
    
    private var sessionsThisWeek: Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return records.filter { $0.date >= weekAgo }.count
    }
    
    private var averageAccuracy: Double {
        guard !records.isEmpty else { return 0 }
        return records.reduce(0.0) { $0 + $1.accuracy } / Double(records.count)
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Practice Streak Section
                Section("练习连续天数") {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("当前连续")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("\(streakManager.currentStreak) 天")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("最长连续")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("\(streakManager.longestStreak) 天")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.yellow)
                        }
                    }
                    .padding(.vertical, 4)
                    
                    HStack {
                        Text("总练习天数")
                            .foregroundColor(.primary)
                        Spacer()
                        Text("\(streakManager.totalPracticeDays) 天")
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                }
                
                // Overview Section
                Section("Overview") {
                    StatRow(title: "总练习次数", value: "\(totalSessions)")
                    StatRow(title: "This Week", value: "\(sessionsThisWeek)")
                }
                
                // Performance Section
                Section("Performance") {
                    StatRow(title: "总准确率", value: String(format: "%.1f%%", overallAccuracy))
                    StatRow(title: "Average Session Accuracy", value: String(format: "%.1f%%", averageAccuracy))
                    StatRow(title: "Total Questions", value: "\(totalQuestions)")
                    StatRow(title: "正确题数", value: "\(totalCorrect)")
                }
                
                // Practice Time Section
                Section("Practice Time") {
                    StatRow(title: "Total Time", value: formattedPracticeTime)
                    if totalSessions > 0 {
                        StatRow(title: "平均时长", value: String(format: "%.1fm", totalPracticeTime / Double(totalSessions) / 60))
                    }
                }
                
                // Streaks Section
                Section("连击") {
                    StatRow(title: "最佳连击", value: "\(bestStreak) 次")
                }
                
                // Recent Sessions
                Section("最近记录") {
                    if records.isEmpty {
                        Text("暂无练习记录")
                            .foregroundColor(.gray)
                            .italic()
                    } else {
                        ForEach(records.prefix(10)) { record in
                            SessionRow(record: record)
                        }
                    }
                }
            }
            .navigationTitle("统计")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    if !records.isEmpty {
                        Button(role: .destructive) {
                            showClearConfirmation = true
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
            .onAppear {
                streakManager.configure(modelContext: modelContext)
            }
            .alert("清除所有统计?", isPresented: $showClearConfirmation) {
                Button("取消", role: .cancel) { }
                Button("清除", role: .destructive) {
                    clearAllRecords()
                }
            } message: {
                Text("This will permanently delete all your practice history. This action cannot be undone.")
            }
        }
    }
    
    private func clearAllRecords() {
        for record in records {
            modelContext.delete(record)
        }
        do {
            try modelContext.save()
        } catch {
            #if DEBUG
            print("[StatsView] Failed to clear records: \(error)")
            #endif
        }
    }
}

// MARK: - Stat Row
struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.primary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundColor(.cyan)
        }
    }
}

// MARK: - Session Row
struct SessionRow: View {
    let record: PracticeRecord
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(dateFormatter.string(from: record.date))
                .font(.caption)
                .foregroundColor(.gray)
            
            HStack {
                Text("\(record.correctAnswers)/\(record.totalAttempts)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(String(format: "%.0f%%", record.accuracy))
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(accuracyColor.opacity(0.2))
                    .foregroundColor(accuracyColor)
                    .cornerRadius(4)
                
                Spacer()
                
                Text(formatDuration(record.duration))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var accuracyColor: Color {
        if record.accuracy >= 80 { return .green }
        else if record.accuracy >= 60 { return .yellow }
        else { return .red }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
}
