import WidgetKit
import SwiftUI

// MARK: - Practice Widget Entry
struct PracticeEntry: TimelineEntry {
    let date: Date
    let todayMinutes: Int
    let targetMinutes: Int
    let streak: Int
    let accuracy: Double
}

// MARK: - Practice Timeline Provider
struct PracticeProvider: TimelineProvider {
    func placeholder(in context: Context) -> PracticeEntry {
        PracticeEntry(
            date: Date(),
            todayMinutes: 15,
            targetMinutes: 30,
            streak: 7,
            accuracy: 85
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (PracticeEntry) -> Void) {
        let entry = PracticeEntry(
            date: Date(),
            todayMinutes: UserDefaults.standard.integer(forKey: "todayMinutes"),
            targetMinutes: UserDefaults.standard.integer(forKey: "targetMinutes"),
            streak: UserDefaults.standard.integer(forKey: "currentStreak"),
            accuracy: 0
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<PracticeEntry>) -> Void) {
        let entry = PracticeEntry(
            date: Date(),
            todayMinutes: UserDefaults.standard.integer(forKey: "todayMinutes"),
            targetMinutes: UserDefaults.standard.integer(forKey: "targetMinutes"),
            streak: UserDefaults.standard.integer(forKey: "currentStreak"),
            accuracy: 0
        )
        
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

// MARK: - Small Widget View
struct SmallWidgetView: View {
    let entry: PracticeEntry
    
    var progress: Double {
        guard entry.targetMinutes > 0 else { return 0 }
        return min(Double(entry.todayMinutes) / Double(entry.targetMinutes), 1.0)
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 8)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    progress >= 1 ? Color.green : Color.cyan,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            
            VStack(spacing: 2) {
                Text("\(entry.todayMinutes)")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("/ \(entry.targetMinutes) min")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Medium Widget View
struct MediumWidgetView: View {
    let entry: PracticeEntry
    
    var progress: Double {
        guard entry.targetMinutes > 0 else { return 0 }
        return min(Double(entry.todayMinutes) / Double(entry.targetMinutes), 1.0)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Progress circle
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 6)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        progress >= 1 ? Color.green : Color.cyan,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                
                VStack {
                    Text("\(Int(progress * 100))%")
                        .font(.headline)
                    Text("完成")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 70, height: 70)
            
            // Stats
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("\(entry.streak) 天连续")
                        .font(.subheadline)
                }
                
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.cyan)
                    Text("\(entry.todayMinutes)/\(entry.targetMinutes) 分钟")
                        .font(.subheadline)
                }
                
                Text("点击开始练习 →")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Large Widget View
struct LargeWidgetView: View {
    let entry: PracticeEntry
    
    var progress: Double {
        guard entry.targetMinutes > 0 else { return 0 }
        return min(Double(entry.todayMinutes) / Double(entry.targetMinutes), 1.0)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("🎸 GuitarBridge")
                    .font(.headline)
                Spacer()
                Text("今日")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Main progress
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            LinearGradient(
                                colors: progress >= 1 ? [.green, .cyan] : [.cyan, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                    
                    VStack {
                        Text("\(Int(progress * 100))%")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("完成")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 120, height: 120)
                
                Text("\(entry.todayMinutes) / \(entry.targetMinutes) 分钟")
                    .font(.subheadline)
            }
            
            Divider()
            
            // Stats grid
            HStack(spacing: 20) {
                StatView(icon: "flame.fill", value: "\(entry.streak)", label: "连续天数", color: .orange)
                StatView(icon: "checkmark.circle.fill", value: "85%", label: "准确率", color: .green)
                StatView(icon: "music.note", value: "12", label: "已解锁徽章", color: .cyan)
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Stat View
struct StatView: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Widget Configuration
struct GuitarBridgeWidget: Widget {
    let kind: String = "GuitarBridgeWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PracticeProvider()) { entry in
            if #available(iOS 17.0, *) {
                SmallWidgetView(entry: entry)
            } else {
                SmallWidgetView(entry: entry)
            }
        }
        .configurationDisplayName("练习进度")
        .description("显示今日练习进度和连续天数")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Widget Bundle
@main
struct GuitarBridgeWidgetBundle: WidgetBundle {
    var body: some Widget {
        GuitarBridgeWidget()
    }
}

#Preview(as: .systemSmall) {
    GuitarBridgeWidget()
} timeline: {
    PracticeEntry(date: .now, todayMinutes: 20, targetMinutes: 30, streak: 7, accuracy: 85)
}

#Preview(as: .systemMedium) {
    GuitarBridgeWidget()
} timeline: {
    PracticeEntry(date: .now, todayMinutes: 20, targetMinutes: 30, streak: 7, accuracy: 85)
}

#Preview(as: .systemLarge) {
    GuitarBridgeWidget()
} timeline: {
    PracticeEntry(date: .now, todayMinutes: 20, targetMinutes: 30, streak: 7, accuracy: 85)
}
