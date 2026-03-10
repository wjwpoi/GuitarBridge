import Foundation
import SwiftUI

// MARK: - Journal Entry
struct JournalEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    var content: String
    var mood: Mood
    var tags: [String]
    var practiceDuration: Int  // minutes
    
    enum Mood: String, CaseIterable, Codable {
        case great = "很棒"
        case good = "不错"
        case normal = "一般"
        case tired = "疲惫"
        case frustrated = "挫折"
        
        var icon: String {
            switch self {
            case .great: return "😄"
            case .good: return "🙂"
            case .normal: return "😐"
            case .tired: return "😴"
            case .frustrated: return "😤"
            }
        }
    }
}

// MARK: - Journal Manager
@MainActor
class JournalManager: ObservableObject {
    static let shared = JournalManager()
    
    @Published var entries: [JournalEntry] = []
    
    private let key = "journalEntries"
    
    init() {
        loadEntries()
    }
    
    func addEntry(_ entry: JournalEntry) {
        entries.insert(entry, at: 0)
        saveEntries()
    }
    
    func updateEntry(_ entry: JournalEntry) {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[index] = entry
            saveEntries()
        }
    }
    
    func deleteEntry(_ entry: JournalEntry) {
        entries.removeAll { $0.id == entry.id }
        saveEntries()
    }
    
    func getEntries(for date: Date) -> [JournalEntry] {
        let calendar = Calendar.current
        return entries.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }
    
    func getEntriesThisWeek() -> [JournalEntry] {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        return entries.filter { $0.date >= weekAgo }
    }
    
    func getEntriesThisMonth() -> [JournalEntry] {
        let calendar = Calendar.current
        let monthAgo = calendar.date(byAdding: .month, value: -1, to: Date())!
        return entries.filter { $0.date >= monthAgo }
    }
    
    private func saveEntries() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    private func loadEntries() {
        if let data = UserDefaults.standard.data(forKey: key),
           let saved = try? JSONDecoder().decode([JournalEntry].self, from: data) {
            entries = saved
        }
    }
}

// MARK: - Journal View
struct JournalView: View {
    @StateObject private var manager = JournalManager.shared
    @State private var showingNewEntry = false
    
    var body: some View {
        NavigationStack {
            List {
                // This week summary
                Section {
                    WeekSummary(entries: manager.getEntriesThisWeek())
                }
                
                // Entries list
                Section("日记") {
                    ForEach(manager.entries) { entry in
                        JournalEntryRow(entry: entry)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            manager.deleteEntry(manager.entries[index])
                        }
                    }
                }
            }
            .navigationTitle("练习日记")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button {
                        showingNewEntry = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewEntry) {
                NewJournalEntryView()
            }
        }
    }
}

// MARK: - Week Summary
struct WeekSummary: View {
    let entries: [JournalEntry]
    
    var totalMinutes: Int {
        entries.reduce(0) { $0 + $1.practiceDuration }
    }
    
    var averageMood: String {
        guard !entries.isEmpty else { return "-" }
        let moods = entries.map { $0.mood }
        let moodOrder: [JournalEntry.Mood: Int] = [.great: 5, .good: 4, .normal: 3, .tired: 2, .frustrated: 1]
        let avg = moods.compactMap { moodOrder[$0] }.reduce(0, +) / moods.count
        return JournalEntry.Mood.allCases.first { moodOrder[$0] == avg }?.icon ?? "😐"
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("本周")
                    .font(.headline)
                Spacer()
                Text(averageMood)
                    .font(.title2)
            }
            
            HStack(spacing: 20) {
                StatBox(value: "\(entries.count)", label: "次练习")
                StatBox(value: "\(totalMinutes)", label: "分钟")
                StatBox(value: "\(entries.count > 0 ? totalMinutes / entries.count : 0)", label: "平均分钟")
            }
        }
        .padding()
        .background(Color(Color.gray.opacity(0.2)))
        .cornerRadius(UIConstants.cornerRadiusMedium)
    }
}

struct StatBox: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Journal Entry Row
struct JournalEntryRow: View {
    let entry: JournalEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(entry.mood.icon)
                Text(formatDate(entry.date))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(entry.practiceDuration) 分钟")
                    .font(.caption)
                    .foregroundColor(.cyan)
            }
            
            Text(entry.content)
                .font(.body)
                .lineLimit(2)
            
            if !entry.tags.isEmpty {
                HStack {
                    ForEach(entry.tags, id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - New Journal Entry View
struct NewJournalEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = JournalManager.shared
    
    @State private var content: String = ""
    @State private var selectedMood: JournalEntry.Mood = .good
    @State private var practiceDuration: Int = 10
    @State private var newTag: String = ""
    @State private var tags: [String] = []
    
    var body: some View {
        NavigationStack {
            Form {
                Section("练习时长") {
                    Stepper("\(practiceDuration) 分钟", value: $practiceDuration, in: 5...180, step: 5)
                }
                
                Section("感受") {
                    Picker("心情", selection: $selectedMood) {
                        ForEach(JournalEntry.Mood.allCases, id: \.self) { mood in
                            Text("\(mood.icon) \(mood.rawValue)").tag(mood)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("日记内容") {
                    TextEditor(text: $content)
                        .frame(minHeight: 100)
                }
                
                Section("标签") {
                    HStack {
                        TextField("添加标签", text: $newTag)
                        Button("添加") {
                            if !newTag.isEmpty && !tags.contains(newTag) {
                                tags.append(newTag)
                                newTag = ""
                            }
                        }
                        .disabled(newTag.isEmpty)
                    }
                    
                    if !tags.isEmpty {
                        FlowLayout(spacing: 8) {
                            ForEach(tags, id: \.self) { tag in
                                HStack(spacing: 4) {
                                    Text("#\(tag)")
                                    Button {
                                        tags.removeAll { $0 == tag }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.caption)
                                    }
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.cyan.opacity(0.2))
                                .cornerRadius(UIConstants.cornerRadiusMedium)
                            }
                        }
                    }
                }
            }
            .navigationTitle("新日记")
            .toolbar { ToolbarItem(placement: .principal) { Text("") } }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let entry = JournalEntry(
                            id: UUID(),
                            date: Date(),
                            content: content,
                            mood: selectedMood,
                            tags: tags,
                            practiceDuration: practiceDuration
                        )
                        manager.addEntry(entry)
                        dismiss()
                    }
                    .disabled(content.isEmpty)
                }
            }
        }
    }
}

// MARK: - Flow Layout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }
    
    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            totalHeight = currentY + lineHeight
        }
        
        return (CGSize(width: maxWidth, height: totalHeight), positions)
    }
}

#Preview {
    JournalView()
}
