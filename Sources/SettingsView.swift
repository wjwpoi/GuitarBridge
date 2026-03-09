import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var preferences: [UserPreferences]
    
    @ObservedObject var audioEngine: AudioEngine
    
    @State private var showNoteNames = true
    @State private var showFretNumbers = true
    @State private var hapticEnabled = true
    @State private var volume: Double = 0.8
    @State private var crossfadeDurationBinding: Double = 0.15
    @State private var selectedToneMode: ToneMode = .clean
    @State private var dailyGoal = 20
    @State private var showReminderSettings = false
    @State private var isPro = ProManager.isPro
    @State private var viewMode: ViewMode = .normal
    
    private var userPrefs: UserPreferences {
        preferences.first ?? UserPreferences()
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Display Settings
                Section("显示") {
                    Toggle("显示音名", isOn: $showNoteNames)
                        .onChange(of: showNoteNames) { _, newValue in
                            userPrefs.showNoteNames = newValue
                            UserDefaults.standard.set(newValue, forKey: "showNoteNames")
                            saveChanges()
                        }
                    
                    Toggle("显示品丝编号", isOn: $showFretNumbers)
                        .onChange(of: showFretNumbers) { _, newValue in
                            userPrefs.showFretNumbers = newValue
                            UserDefaults.standard.set(newValue, forKey: "showFretNumbers")
                            saveChanges()
                        }
                }
                
                // Feedback Settings
                Section("反馈") {
                    Toggle("触感反馈", isOn: $hapticEnabled)
                        .onChange(of: hapticEnabled) { _, newValue in
                            userPrefs.hapticFeedbackEnabled = newValue
                            saveChanges()
                        }
                    
                    VStack(alignment: .leading) {
                        Text("音量: \(Int(volume * 100))%")
                        Slider(value: $volume, in: 0...1)
                            .onChange(of: volume) { _, newValue in
                                let floatValue = Float(newValue)
                                UserDefaults.standard.set(floatValue, forKey: "audioVolume")
                                audioEngine.volume = floatValue
                            }
                    }
                }
                
                // Tone Settings
                Section("音色") {
                    Picker("音色模式", selection: $selectedToneMode) {
                        ForEach(ToneMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedToneMode) { _, newValue in
                        audioEngine.setToneMode(newValue.rawValue)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("切换渐变: \(Int(audioEngine.crossfadeDuration * 1000))ms")
                        Slider(value: $crossfadeDurationBinding, in: 0.05...0.3, step: 0.05)
                            .onChange(of: crossfadeDurationBinding) { _, newValue in
                                audioEngine.crossfadeDuration = newValue
                            }
                        Text("范围: 50ms - 300ms")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                // Practice Goals
                Section("练习目标") {
                    Stepper("每日目标: \(dailyGoal) 题", value: $dailyGoal, in: 5...100, step: 5)
                        .onChange(of: dailyGoal) { _, newValue in
                            userPrefs.dailyGoal = newValue
                            saveChanges()
                        }
                }
                
                // Pro Features
                Section {
                    Toggle("Pro 版本", isOn: $isPro)
                        .onChange(of: isPro) { _, newValue in
                            ProManager.isPro = newValue
                    }
                    
                    Picker("视图模式", selection: $viewMode) {
                        ForEach(ViewMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                } header: {
                    Text("高级")
                }
                
                // Reminders
                Section("Reminders") {
                    Button {
                        showReminderSettings = true
                    } label: {
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.orange)
                            Text("练习提醒")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .foregroundColor(.primary)
                }
                
                // Stats Summary
                Section("统计") {
                    HStack {
                        Text("总练习时间")
                        Spacer()
                        Text(userPrefs.formattedTotalTime)
                            .foregroundColor(.cyan)
                    }
                    
                    HStack {
                        Text("当前连续天数")
                        Spacer()
                        Text("\(userPrefs.streakDays) 天")
                            .foregroundColor(.orange)
                    }
                }
                
                // About
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("0.2.0")
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("Built with")
                        Spacer()
                        Text("SwiftUI + AVAudioEngine")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("设置")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                loadSettings()
            }
            .sheet(isPresented: $showReminderSettings) {
                ReminderSettingsView()
                    .presentationDetents([.height(350)])
                    .presentationDragIndicator(.visible)
            }
        }
    }
    
    private func loadSettings() {
        showNoteNames = UserDefaults.standard.object(forKey: "showNoteNames") as? Bool ?? userPrefs.showNoteNames
        showFretNumbers = UserDefaults.standard.object(forKey: "showFretNumbers") as? Bool ?? userPrefs.showFretNumbers
        hapticEnabled = userPrefs.hapticFeedbackEnabled
        dailyGoal = userPrefs.dailyGoal
        volume = Double(UserDefaults.standard.object(forKey: "audioVolume") as? Float ?? 0.8)
        crossfadeDurationBinding = UserDefaults.standard.object(forKey: "crossfadeDuration") as? Double ?? 0.15
        selectedToneMode = ToneMode(rawValue: UserDefaults.standard.string(forKey: "toneMode") ?? "clean") ?? .clean
    }
    
    private func saveChanges() {
        do {
            try modelContext.save()
        } catch {
            print("[SettingsView] Failed to save: \(error)")
        }
    }
}

// MARK: - Reminder Settings View
struct ReminderSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var reminderEnabled = false
    @State private var reminderTime = Calendar.current.date(from: DateComponents(hour: 19, minute: 0)) ?? Date()
    @State private var showTimePicker = false
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle("Enable Daily Reminder", isOn: $reminderEnabled)
                        .onChange(of: reminderEnabled) { _, newValue in
                            if newValue {
                                requestNotificationPermission()
                            }
                        }
                }
                
                if reminderEnabled {
                    Section("Reminder Time") {
                        DatePicker(
                            "Practice Time",
                            selection: $reminderTime,
                            displayedComponents: .hourAndMinute
                        )
                    }
                    
                    Section {
                        Button("Save Reminder") {
                            scheduleReminder()
                            dismiss()
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.green)
                    }
                }
            }
            .navigationTitle("Practice Reminders")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("[ReminderSettings] Permission error: \(error)")
            }
        }
    }
    
    private func scheduleReminder() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        let content = UNMutableNotificationContent()
        content.title = "Time to Practice! 🎸"
        content.body = "Keep your streak going! Open GuitarBridge for your daily ear training."
        content.sound = .default
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: reminderTime)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "dailyPracticeReminder",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("[ReminderSettings] Failed to schedule: \(error)")
            }
        }
    }
}

#Preview {
    SettingsView(audioEngine: AudioEngine())
}
