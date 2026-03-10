import SwiftUI
import SwiftData
import Charts

// MARK: - Practice History View
struct PracticeHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PracticeRecord.date, order: .reverse) private var records: [PracticeRecord]
    
    @State private var selectedMode: TrainingMode?
    @State private var dateRange: DateRange = .week
    
    enum DateRange: String, CaseIterable {
        case week = "最近7天"
        case month = "最近30天"
        case all = "全部"
    }
    
    var filteredRecords: [PracticeRecord] {
        var result = records
        
        // Filter by mode
        if let mode = selectedMode {
            result = result.filter { _ in true } // Would need mode stored in record
        }
        
        // Filter by date
        let calendar = Calendar.current
        let now = Date()
        
        switch dateRange {
        case .week:
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: now)!
            result = result.filter { $0.date >= weekAgo }
        case .month:
            let monthAgo = calendar.date(byAdding: .day, value: -30, to: now)!
            result = result.filter { $0.date >= monthAgo }
        case .all:
            break
        }
        
        return result
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Date range picker
                    Picker("时间范围", selection: $dateRange) {
                        ForEach(DateRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // Summary cards
                    if !filteredRecords.isEmpty {
                        // Accuracy trend chart
                        VStack(alignment: .leading, spacing: 8) {
                            Text("准确率趋势")
                                .font(.headline)
                            
                            AccuracyTrendChart(records: filteredRecords)
                                .frame(height: 150)
                        }
                        .padding()
                        .background(Color(Color.gray.opacity(0.2)))
                        .cornerRadius(UIConstants.cornerRadiusMedium)
                        
                        // Practice time chart
                        VStack(alignment: .leading, spacing: 8) {
                            Text("练习时长")
                                .font(.headline)
                            
                            PracticeTimeChart(records: filteredRecords)
                                .frame(height: 150)
                        }
                        .padding()
                        .background(Color(Color.gray.opacity(0.2)))
                        .cornerRadius(UIConstants.cornerRadiusMedium)
                        
                        // Mode distribution
                        VStack(alignment: .leading, spacing: 8) {
                            Text("练习模式分布")
                                .font(.headline)
                            
                            ModeDistributionChart(records: filteredRecords)
                                .frame(height: 150)
                        }
                        .padding()
                        .background(Color(Color.gray.opacity(0.2)))
                        .cornerRadius(UIConstants.cornerRadiusMedium)
                        
                        // Records list
                        VStack(alignment: .leading, spacing: 8) {
                            Text("练习记录")
                                .font(.headline)
                            
                            ForEach(groupedRecords, id: \.key) { date, records in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(date)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    ForEach(records) { record in
                                        RecordRow(record: record)
                                    }
                                }
                            }
                        }
                    } else {
                        Text("暂无练习记录")
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
                .padding()
            }
            .navigationTitle("练习历史")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    var groupedRecords: [(key: String, value: [PracticeRecord])] {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        let grouped = Dictionary(grouping: filteredRecords) { record in
            formatter.string(from: record.date)
        }
        
        return grouped.sorted { $0.key > $1.key }
    }
}

// MARK: - Record Row
struct RecordRow: View {
    let record: PracticeRecord
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(formatTime(record.date))
                    .font(.subheadline)
                
                Text("\(Int(record.duration / 60)) 分钟")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.0f%%", record.accuracy))
                    .font(.headline)
                    .foregroundColor(accuracyColor(record.accuracy))
                
                Text("\(record.correctAnswers)/\(record.totalAttempts)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    func accuracyColor(_ accuracy: Double) -> Color {
        if accuracy >= 80 { return .green }
        if accuracy >= 60 { return .orange }
        return .red
    }
}

// MARK: - Accuracy Trend Chart
struct AccuracyTrendChart: View {
    let records: [PracticeRecord]
    
    var body: some View {
        Chart {
            ForEach(sortedRecords, id: \.date) { record in
                LineMark(
                    x: .value("日期", record.date, unit: .day),
                    y: .value("准确率", record.accuracy)
                )
                .foregroundStyle(.cyan)
                
                AreaMark(
                    x: .value("日期", record.date, unit: .day),
                    y: .value("准确率", record.accuracy)
                )
                .foregroundStyle(.cyan.opacity(0.2))
            }
        }
    }
    
    var sortedRecords: [PracticeRecord] {
        records.sorted { $0.date < $1.date }
    }
}

// MARK: - Practice Time Chart
struct PracticeTimeChart: View {
    let records: [PracticeRecord]
    
    var body: some View {
        Chart {
            ForEach(groupedByDay, id: \.key) { day, duration in
                BarMark(
                    x: .value("日期", day, unit: .day),
                    y: .value("时长", duration / 60)
                )
                .foregroundStyle(.orange.gradient)
            }
        }
    }
    
    var groupedByDay: [(key: Date, value: Double)] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: records) { record in
            calendar.startOfDay(for: record.date)
        }
        
        return grouped.map { (day, records) in
            (day, records.reduce(0) { $0 + $1.duration })
        }.sorted { $0.key < $1.key }
    }
}

// MARK: - Mode Distribution Chart
struct ModeDistributionChart: View {
    let records: [PracticeRecord]
    
    var body: some View {
        Chart {
            ForEach(modeData, id: \.mode) { data in
                SectorMark(
                    angle: .value("次数", data.count),
                    innerRadius: .ratio(0.5),
                    angularInset: 1
                )
                .foregroundStyle(by: .value("模式", data.mode))
                .annotation(position: .overlay) {
                    if data.count > 0 {
                        Text("\(data.count)")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }
    
    var modeData: [(mode: String, count: Int)] {
        // Since records don't store mode, show total counts
        [("练习次数", records.count)]
    }
}

#Preview {
    PracticeHistoryView()
}
