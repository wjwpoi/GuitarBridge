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
    
    // 从 AudioEngine 当前模式获取 ToneMode
    private var currentToneMode: ToneMode {
        ToneMode(rawValue: audioEngine.currentMode.capitalized) ?? .clean
    }
    
    private var currentTheme: Theme {
        Theme.theme(for: currentToneMode)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    optionsSection
                    FretboardSectionView(
                        trainingEngine: trainingEngine,
                        audioEngine: audioEngine,
                        selectedTuning: $selectedTuning,
                        selectedScale: $selectedScale,
                        selectedKey: $selectedKey,
                        showDegrees: $showDegrees,
                        showScale: $showScale,
                        showNoteNames: $showNoteNames,
                        showFretNumbers: $showFretNumbers,
                        theme: currentTheme,
                        onFretTapped: handleFretTap
                    )
                    statusSection
                }
                .padding(.horizontal)
                .padding(.top, 20)
                .padding(.bottom, 40)  // 增加底部间距
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
        VStack(spacing: 12) {
            // 第一行：调性、音阶、调弦 - 居中排列
            HStack(spacing: 12) {
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
            .frame(maxWidth: .infinity)
            
            // 显示选项 - 居中
            HStack(spacing: 16) {
                Toggle(isOn: $showDegrees) {
                    Label("级数", systemImage: "number")
                }
                .font(.subheadline)
                .tint(showDegrees ? .blue : .gray)
                
                Button {
                    showScale.toggle()
                } label: {
                    Label(showScale ? "隐藏" : "显示", systemImage: showScale ? "eye.slash.fill" : "eye.fill")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(showScale ? .orange : .blue)
                
                Spacer()
                
                // 音色设置按钮 - 跳转到设置页面
                Button {
                    showSettings = true
                } label: {
                    Label("音色", systemImage: "speaker.wave.3.fill")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(.orange)
            }
        }
        .padding(12)
        .background(.regularMaterial)
        .cornerRadius(12)
    }
    
    private var fretboardSection: some View {
        VStack(spacing: 8) {
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
                StatusBadge(
                    icon: "music.note",
                    iconColor: .orange,
                    text: "正在播放：锚点音",
                    textColor: .orange
                )
                
            case .playingTarget:
                StatusBadge(
                    icon: "music.note.list",
                    iconColor: .blue,
                    text: "正在播放：目标音",
                    textColor: .blue
                )
                
            case .awaitingAnswer:
                StatusBadge(
                    icon: "hand.point.up.fill",
                    iconColor: .green,
                    text: "请选择答案",
                    textColor: .green
                )
                
            case .showingResult(let correct):
                if correct {
                    StatusBadge(
                        icon: "checkmark.circle.fill",
                        iconColor: .green,
                        text: "正确!",
                        textColor: .green
                    )
                } else {
                    StatusBadge(
                        icon: "xmark.circle.fill",
                        iconColor: .red,
                        text: "错误，请重试",
                        textColor: .red
                    )
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
        // 无论是否在训练中，点击都播放声音
        let midiNote = GuitarMath.midiNote(for: position.string, fret: position.fret, tuning: selectedTuning)
        audioEngine.play(midiNote: midiNote)
        HapticManager.impact(.light)
        
        // 只有在训练状态才提交答案
        guard trainingEngine.state == .awaitingAnswer else { return }
        HapticManager.impact(.medium)
        trainingEngine.submitAnswer(position)
    }
}
