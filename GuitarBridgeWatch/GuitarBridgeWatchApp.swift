import SwiftUI
import WatchKit

// MARK: - Watch App Entry Point
@main
struct GuitarBridgeWatchApp: App {
    var body: some Scene {
        WindowGroup {
            WatchHomeView()
        }
    }
}

// MARK: - Watch Home View
struct WatchHomeView: View {
    @StateObject private var goalManager = DailyGoalManager.shared
    
    var progress: Double {
        guard goalManager.targetMinutes > 0 else { return 0 }
        return min(Double(goalManager.todayMinutes) / Double(goalManager.targetMinutes), 1.0)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Progress ring
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 12)
                        
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(
                                progress >= 1 ? Color.green : Color.cyan,
                                style: StrokeStyle(lineWidth: 12, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                        
                        VStack(spacing: 2) {
                            Text("\(Int(progress * 100))%")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("完成")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(width: 120, height: 120)
                    
                    // Stats
                    HStack(spacing: 20) {
                        VStack {
                            Text("\(goalManager.currentStreak)")
                                .font(.title3)
                                .fontWeight(.bold)
                            Text("天连续")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                        
                        VStack {
                            Text("\(goalManager.todayMinutes)")
                                .font(.title3)
                                .fontWeight(.bold)
                            Text("分钟")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // Quick start buttons
                    VStack(spacing: 8) {
                        Button("音阶练习") {
                            // Open iPhone app with this mode
                        }
                        .buttonStyle(.bordered)
                        
                        Button("和弦练习") {
                            // Open iPhone app with this mode
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
            }
            .navigationTitle("GuitarBridge")
        }
    }
}

// MARK: - Watch Stats View
struct WatchStatsView: View {
    @StateObject private var goalManager = DailyGoalManager.shared
    
    var body: some View {
        List {
            Section("进度") {
                HStack {
                    Text("今日练习")
                    Spacer()
                    Text("\(goalManager.todayMinutes) / \(goalManager.targetMinutes) 分钟")
                        .foregroundColor(.gray)
                }
                
                HStack {
                    Text("连续天数")
                    Spacer()
                    Text("\(goalManager.currentStreak) 天")
                        .foregroundColor(.orange)
                }
            }
            
            Section("目标") {
                HStack {
                    Text("目标分钟")
                    Spacer()
                    Text("\(goalManager.targetMinutes) 分钟")
                        .foregroundColor(.gray)
                }
                
                HStack {
                    Text("目标题目")
                    Spacer()
                    Text("\(goalManager.targetQuestions) 题")
                        .foregroundColor(.gray)
                }
            }
        }
        .navigationTitle("统计")
    }
}

// MARK: - Notification Controller
class NotificationController: WKUserNotificationHostingController<WatchNotificationView> {
    override var body: WatchNotificationView {
        WatchNotificationView()
    }
}

struct WatchNotificationView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "guitars")
                .font(.largeTitle)
            
            Text("练习时间到！")
                .font(.headline)
            
            Text("打开 GuitarBridge 开始练习吧")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
    }
}
