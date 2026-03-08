import SwiftUI
import SwiftData

// MARK: - 主视图：吉他练耳训练界面
struct ContentView: View {
    @StateObject private var trainingEngine = TrainingEngine()
    @StateObject private var audioEngine = AudioEngine()
    
    @State private var selectedKey = "C"
    @State private var difficulty: Difficulty = .easy
    @State private var selectedScale: ScaleType = .major
    @State private var selectedTuning: Tuning = .standard
    @State private var selectedToneMode: ToneMode = .clean
    @State private var showSettings = false
    @State private var showDegrees = false
    @State private var showScale = false
    @State private var showStats = false
    @State private var showCompletionAnimation = false
    
    @AppStorage("showNoteNames") private var showNoteNames = true
    @AppStorage("showFretNumbers") private var showFretNumbers = true
    
    private let keys = ["C", "D", "E", "F", "G", "A", "B"]
    private let difficulties = Difficulty.allCases
    private let scales = ScaleType.allCases
    private let tunings = Tuning.allCases
    private let toneModes = ToneMode.allCases
    
    private var currentTheme: Theme {
        Theme.theme(for: selectedToneMode)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    optionsSection
                    fretboardSection
                    statusSection
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .background(LinearGradient(colors: [.blue.opacity(0.1), .purple.opacity(0.1)], startPoint: .top, endPoint: .bottom))
            .toolbar {
                Button { showStats = true } label: {
                    Image(systemName: "chart.bar.fill")
                }
                Button { showSettings = true } label: {
                    Image(systemName: "gearshape.fill")
                }
            }
            .sheet(isPresented: $showStats) {
                StatsView()
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(audioEngine: audioEngine)
            }
            .onReceive(trainingEngine.$state) { newState in
                if newState == .completed {
                    showCompletionAnimation = true
                    HapticManager.notification(.success)
                }
            }
            .fullScreenCover(isPresented: $showCompletionAnimation) {
                CompletionAnimationView(
                    correctCount: trainingEngine.correctCount,
                    totalQuestions: trainingEngine.questionsPerSession,
                    streak: trainingEngine.bestStreak,
                    onDismiss: {
                        showCompletionAnimation = false
                        trainingEngine.reset()
                    }
                )
            }
            .onAppear {
                trainingEngine.configure(audioEngine: audioEngine, tuning: selectedTuning)
            }
            .onChange(of: selectedTuning) { _, newValue in
                trainingEngine.configure(audioEngine: audioEngine, tuning: newValue)
            }
            .onChange(of: selectedToneMode) { _, newValue in
                audioEngine.setToneMode(newValue.rawValue)
            }
            .onChange(of: selectedKey) { _, newValue in
                trainingEngine.currentKey = newValue
            }
            .onChange(of: selectedScale) { _, newValue in
                trainingEngine.scaleType = newValue
            }
            .onChange(of: difficulty) { _, newValue in
                trainingEngine.difficulty = newValue
            }
        }
    }
    
    private var optionsSection: some View {
        VStack(spacing: 10) {
            // 调性、音阶、调弦放同一行
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("调性")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker("调性", selection: $selectedKey) {
                        ForEach(keys, id: \.self) { Text($0) }
                    }
                    .pickerStyle(.menu)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("音阶")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker("音阶", selection: $selectedScale) {
                        ForEach(scales) { scale in
                            Text(scale.rawValue).tag(scale)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("调弦")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker("调弦", selection: $selectedTuning) {
                        ForEach(tunings) { tuning in
                            Text(tuning.rawValue).tag(tuning)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            
            // 难度、音色放同一行
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("难度")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker("难度", selection: $difficulty) {
                        ForEach(difficulties) { Text($0.rawValue) }
                    }
                    .pickerStyle(.segmented)
                    .tint(.blue)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("音色")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker("音色", selection: $selectedToneMode) {
                        ForEach(toneModes) { Text($0.rawValue) }
                    }
                    .pickerStyle(.segmented)
                    .tint(.orange)
                }
            }
            
            // 显示级数 Toggle - 单独一行
            Toggle(isOn: $showDegrees) {
                Label("显示级数", systemImage: "number")
            }
            .font(.subheadline)
            .tint(showDegrees ? .blue : .gray)
            
            // 显示音阶 Button - 单独一行
            Button {
                showScale.toggle()
            } label: {
                Label(showScale ? "隐藏音阶" : "显示音阶", systemImage: showScale ? "eye.slash.fill" : "eye.fill")
            }
            .buttonStyle(.bordered)
            .tint(showScale ? .orange : .blue)
        }
        .padding(12)
        .background(.regularMaterial)
        .cornerRadius(12)
    }
    
    private var fretboardSection: some View {
        VStack(spacing: 6) {
            // 状态指示器：显示当前播放的是锚点音还是目标音
            if trainingEngine.state != .idle {
                playbackStatusIndicator
            }
            
            FretboardView(
                tuning: selectedTuning,
                theme: currentTheme,
                onFretTapped: handleFretTap,
                isDisabled: trainingEngine.state != .awaitingAnswer,
                selectedPosition: trainingEngine.userAnswer,
                lastAnswerCorrect: trainingEngine.lastAnswerCorrect,
                showDegrees: showDegrees,
                showScale: showScale,
                currentScale: selectedScale,
                currentKey: selectedKey,
                showNoteNames: showNoteNames,
                showFretNumbers: showFretNumbers
            )
            .frame(height: 220)
            
            // 重播按钮 - 紧凑排列
            if trainingEngine.state == .awaitingAnswer || trainingEngine.state == .playingTarget || trainingEngine.state == .playingAnchor {
                HStack(spacing: 8) {
                    Button {
                        HapticManager.impact(.light)
                        trainingEngine.replayAnchorNote()
                    } label: {
                        Label("锚点", systemImage: "arrow.uturn.backward.circle.fill")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    
                    Button {
                        HapticManager.impact(.light)
                        trainingEngine.replayTargetNote()
                    } label: {
                        Label("目标", systemImage: "play.circle.fill")
                    }
                    .buttonStyle(.bordered)
                    .tint(.blue)
                    .controlSize(.small)
                }
            }
        }
    }
    
    // MARK: - 播放状态指示器
    private var playbackStatusIndicator: some View {
        HStack(spacing: 8) {
            switch trainingEngine.state {
            case .playingAnchor:
                HStack(spacing: 4) {
                    Image(systemName: "music.note")
                        .foregroundStyle(.orange)
                    Text("正在播放：锚点音")
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.orange.opacity(0.15))
                .cornerRadius(8)
                
            case .playingTarget:
                HStack(spacing: 4) {
                    Image(systemName: "music.note.list")
                        .foregroundStyle(.blue)
                    Text("正在播放：目标音")
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.blue.opacity(0.15))
                .cornerRadius(8)
                
            case .awaitingAnswer:
                HStack(spacing: 4) {
                    Image(systemName: "hand.point.up.fill")
                        .foregroundStyle(.green)
                    Text("请选择答案")
                        .font(.subheadline)
                        .foregroundStyle(.green)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.green.opacity(0.15))
                .cornerRadius(8)
                
            case .showingResult(let correct):
                if correct {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("正确!")
                            .font(.subheadline)
                            .foregroundStyle(.green)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.green.opacity(0.15))
                    .cornerRadius(8)
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red)
                        Text("错误，请重试")
                            .font(.subheadline)
                            .foregroundStyle(.red)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.red.opacity(0.15))
                    .cornerRadius(8)
                }
                
            default:
                EmptyView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: trainingEngine.state)
    }
    
    private var statusSection: some View {
        VStack(spacing: 10) {
            // Progress bar with question count
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("问题 \(trainingEngine.completedQuestions + 1)/\(trainingEngine.questionsPerSession)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ProgressView(value: Double(trainingEngine.completedQuestions), total: Double(trainingEngine.questionsPerSession))
                        .tint(.green)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("正确")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 2) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("\(trainingEngine.correctCount)/\(trainingEngine.questionsPerSession)")
                            .font(.subheadline)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("连胜")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.orange)
                        Text("\(trainingEngine.currentStreak)")
                            .font(.subheadline)
                    }
                }
            }
            
            // Show hint when answer is wrong
            if trainingEngine.lastAnswerCorrect == false, let correct = trainingEngine.targetNote {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(.yellow)
                    Text("正确位置: 第\(correct.fret)品")
                        .font(.caption)
                    Spacer()
                }
                .padding(6)
                .background(.yellow.opacity(0.2))
                .cornerRadius(6)
            }
            
            Button {
                if trainingEngine.state == .idle {
                    HapticManager.impact(.medium)
                    trainingEngine.currentKey = selectedKey
                    trainingEngine.scaleType = selectedScale
                    trainingEngine.difficulty = difficulty
                    trainingEngine.startTraining()
                } else {
                    trainingEngine.reset()
                }
            } label: {
                Label(
                    trainingEngine.state == .idle ? "开始训练" : "停止",
                    systemImage: trainingEngine.state == .idle ? "play.fill" : "stop.fill"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .scaleEffect(trainingEngine.state == .idle ? 1.0 : 1.02)
            .animation(.easeInOut(duration: 0.2), value: trainingEngine.state)
            .tint(trainingEngine.state == .idle ? .green : .red)
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.white)
                .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 2)
        }
    }
    
    private func handleFretTap(_ position: FretPosition) {
        guard trainingEngine.state == .awaitingAnswer else { return }
        HapticManager.impact(.medium)
        trainingEngine.submitAnswer(position)
    }
}
