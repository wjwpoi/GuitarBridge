import Foundation
import SwiftUI

// MARK: - Custom Practice Configuration
struct CustomPracticeConfig: Identifiable, Codable {
    let id: UUID
    var name: String
    var modes: [TrainingMode]
    var questionCount: Int
    var timeLimit: Int?  // minutes, nil = no limit
    var tuning: Tuning
    var difficulty: Difficulty
    
    init(
        name: String,
        modes: [TrainingMode],
        questionCount: Int = 10,
        timeLimit: Int? = nil,
        tuning: Tuning = .standard,
        difficulty: Difficulty = .easy
    ) {
        self.id = UUID()
        self.name = name
        self.modes = modes
        self.questionCount = questionCount
        self.timeLimit = timeLimit
        self.tuning = tuning
        self.difficulty = difficulty
    }
    
    static let `default` = CustomPracticeConfig(
        name: "默认练习",
        modes: [.intervals],
        questionCount: 10,
        timeLimit: nil,
        tuning: .standard,
        difficulty: .easy
    )
    
    static let quickPractice = CustomPracticeConfig(
        name: "快速练习",
        modes: [.intervals],
        questionCount: 5,
        timeLimit: 3,
        tuning: .standard,
        difficulty: .easy
    )
    
    static let chordMaster = CustomPracticeConfig(
        name: "和弦大师",
        modes: [.chords],
        questionCount: 20,
        timeLimit: nil,
        tuning: .standard,
        difficulty: .hard
    )
    
    static let scalePractice = CustomPracticeConfig(
        name: "音阶练习",
        modes: [.scaleDegrees],
        questionCount: 15,
        timeLimit: nil,
        tuning: .standard,
        difficulty: .medium
    )
}

// MARK: - Custom Practice Manager
@MainActor
class CustomPracticeManager: ObservableObject {
    static let shared = CustomPracticeManager()
    
    @Published var configs: [CustomPracticeConfig] = []
    @Published var currentConfig: CustomPracticeConfig?
    
    init() {
        loadConfigs()
        
        // Add default configs if empty
        if configs.isEmpty {
            configs = [
                .default,
                .quickPractice,
                .chordMaster,
                .scalePractice
            ]
            saveConfigs()
        }
    }
    
    // MARK: - CRUD
    
    func addConfig(_ config: CustomPracticeConfig) {
        configs.append(config)
        saveConfigs()
    }
    
    func updateConfig(_ config: CustomPracticeConfig) {
        if let index = configs.firstIndex(where: { $0.id == config.id }) {
            configs[index] = config
            saveConfigs()
        }
    }
    
    func deleteConfig(_ config: CustomPracticeConfig) {
        configs.removeAll { $0.id == config.id }
        saveConfigs()
    }
    
    func selectConfig(_ config: CustomPracticeConfig) {
        currentConfig = config
    }
    
    // MARK: - Generate Questions
    
    func generateQuestions(from config: CustomPracticeConfig) -> [Question] {
        var questions: [Question] = []
        
        let mode = config.modes.randomElement() ?? .intervals
        
        for _ in 0..<config.questionCount {
            // Generate based on mode
            let question = generateSingleQuestion(
                mode: mode,
                tuning: config.tuning,
                difficulty: config.difficulty
            )
            questions.append(question)
        }
        
        return questions
    }
    
    private func generateSingleQuestion(
        mode: TrainingMode,
        tuning: Tuning,
        difficulty: Difficulty
    ) -> Question {
        // Simplified question generation
        // Real implementation would integrate with TrainingEngine
        return Question(
            id: UUID(),
            type: mode,
            targetNote: 60,  // Middle C as default
            tuning: tuning,
            difficulty: difficulty
        )
    }
    
    // MARK: - Storage
    
    private func saveConfigs() {
        if let data = try? JSONEncoder().encode(configs) {
            UserDefaults.standard.set(data, forKey: "customPracticeConfigs")
        }
    }
    
    private func loadConfigs() {
        if let data = UserDefaults.standard.data(forKey: "customPracticeConfigs"),
           let saved = try? JSONDecoder().decode([CustomPracticeConfig].self, from: data) {
            configs = saved
        }
    }
}

// MARK: - Question Model
struct Question: Identifiable {
    let id: UUID
    let type: TrainingMode
    let targetNote: Int
    let tuning: Tuning
    let difficulty: Difficulty
    
    var noteName: String {
        let names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        return names[targetNote % 12]
    }
}

// MARK: - Custom Practice View
struct CustomPracticeView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = CustomPracticeManager.shared
    @State private var editingConfig: CustomPracticeConfig?
    @State private var isCreating = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(manager.configs) { config in
                    ConfigRow(config: config) {
                        manager.selectConfig(config)
                        // Start practice with this config
                        dismiss()
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            manager.deleteConfig(config)
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            editingConfig = config
                        } label: {
                            Label("编辑", systemImage: "pencil")
                        }
                        .tint(.orange)
                    }
                }
            }
            .navigationTitle("自定义练习")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button {
                        isCreating = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .automatic) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $isCreating) {
                ConfigEditorView(config: nil) { newConfig in
                    manager.addConfig(newConfig)
                }
            }
            .sheet(item: $editingConfig) { config in
                ConfigEditorView(config: config) { updatedConfig in
                    manager.updateConfig(updatedConfig)
                }
            }
        }
    }
}

// MARK: - Config Row
struct ConfigRow: View {
    let config: CustomPracticeConfig
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 4) {
                Text(config.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack {
                    Text(config.modes.map { $0.rawValue }.joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(config.questionCount)题")
                        .font(.caption)
                        .foregroundColor(.cyan)
                }
                
                HStack {
                    Text(config.tuning.rawValue)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(config.difficulty.rawValue)
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Config Editor View
struct ConfigEditorView: View {
    @Environment(\.dismiss) private var dismiss
    
    let config: CustomPracticeConfig?
    let onSave: (CustomPracticeConfig) -> Void
    
    @State private var name: String = ""
    @State private var selectedModes: Set<TrainingMode> = [.intervals]
    @State private var questionCount: Int = 10
    @State private var hasTimeLimit: Bool = false
    @State private var timeLimit: Int = 5
    @State private var selectedTuning: Tuning = .standard
    @State private var selectedDifficulty: Difficulty = .easy
    
    init(config: CustomPracticeConfig?, onSave: @escaping (CustomPracticeConfig) -> Void) {
        self.config = config
        self.onSave = onSave
        
        if let config = config {
            _name = State(initialValue: config.name)
            _selectedModes = State(initialValue: Set(config.modes))
            _questionCount = State(initialValue: config.questionCount)
            _hasTimeLimit = State(initialValue: config.timeLimit != nil)
            _timeLimit = State(initialValue: config.timeLimit ?? 5)
            _selectedTuning = State(initialValue: config.tuning)
            _selectedDifficulty = State(initialValue: config.difficulty)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("练习名称") {
                    TextField("名称", text: $name)
                }
                
                Section("训练模式") {
                    ForEach(TrainingMode.allCases) { mode in
                        Toggle(mode.rawValue, isOn: Binding(
                            get: { selectedModes.contains(mode) },
                            set: { isSelected in
                                if isSelected {
                                    selectedModes.insert(mode)
                                } else {
                                    selectedModes.remove(mode)
                                }
                            }
                        ))
                    }
                }
                
                Section("题目数量") {
                    Stepper("\(questionCount) 题", value: $questionCount, in: 5...50, step: 5)
                }
                
                Section("时间限制") {
                    Toggle("启用时间限制", isOn: $hasTimeLimit)
                    if hasTimeLimit {
                        Stepper("\(timeLimit) 分钟", value: $timeLimit, in: 1...30)
                    }
                }
                
                Section("调弦") {
                    Picker("调弦", selection: $selectedTuning) {
                        ForEach(Tuning.allCases) { tuning in
                            Text(tuning.rawValue).tag(tuning)
                        }
                    }
                }
                
                Section("难度") {
                    Picker("难度", selection: $selectedDifficulty) {
                        ForEach(Difficulty.allCases) { diff in
                            Text(diff.rawValue).tag(diff)
                        }
                    }
                }
            }
            .navigationTitle(config == nil ? "新建练习" : "编辑练习")
            .toolbar { ToolbarItem(placement: .principal) { Text("") } }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let newConfig = CustomPracticeConfig(
                            name: name.isEmpty ? "自定义练习" : name,
                            modes: Array(selectedModes),
                            questionCount: questionCount,
                            timeLimit: hasTimeLimit ? timeLimit : nil,
                            tuning: selectedTuning,
                            difficulty: selectedDifficulty
                        )
                        onSave(newConfig)
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    CustomPracticeView()
}
