import SwiftUI

// MARK: - Fretboard Section View
/// 指板区域视图，包含 FretboardView 和播放控制按钮
struct FretboardSectionView: View {
    // MARK: - Observed Objects
    @ObservedObject var trainingEngine: TrainingEngine
    @ObservedObject var audioEngine: AudioEngine
    
    // MARK: - Bindings
    @Binding var selectedTuning: Tuning
    @Binding var selectedScale: ScaleType
    @Binding var selectedKey: String
    @Binding var showDegrees: Bool
    @Binding var showScale: Bool
    @Binding var showNoteNames: Bool
    @Binding var showFretNumbers: Bool
    
    // MARK: - Properties
    let theme: Theme
    let onFretTapped: (FretPosition) -> Void
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 12) {
            // 状态指示器
            if trainingEngine.state != .idle {
                statusIndicator
            }
            
            // 指板视图
            FretboardView(
                tuning: selectedTuning,
                theme: theme,
                onFretTapped: onFretTapped,
                isDisabled: trainingEngine.state != .awaitingAnswer,
                selectedPosition: trainingEngine.userAnswer,
                lastAnswerCorrect: trainingEngine.lastAnswerCorrect,
                anchorPosition: trainingEngine.anchorNote,
                targetPosition: trainingEngine.targetNote,
                showDegrees: showDegrees,
                showScale: showScale,
                currentScale: selectedScale,
                currentKey: selectedKey,
                showNoteNames: showNoteNames,
                showFretNumbers: showFretNumbers
            )
            .frame(height: 220)
            
            // 重播按钮
            if showReplayButtons {
                replayButtons
            }
        }
    }
    
    // MARK: - Computed Properties
    private var showReplayButtons: Bool {
        trainingEngine.state == .awaitingAnswer || 
        trainingEngine.state == .playingTarget || 
        trainingEngine.state == .playingAnchor
    }
    
    // MARK: - Status Indicator
    @ViewBuilder
    private var statusIndicator: some View {
        switch trainingEngine.state {
        case .playingAnchor:
            statusBadge(icon: "music.note", text: "正在播放：锚点音", color: .orange)
        case .playingTarget:
            statusBadge(icon: "music.note.list", text: "正在播放：目标音", color: .blue)
        case .awaitingAnswer:
            statusBadge(icon: "hand.point.up.fill", text: "请选择答案", color: .green)
        case .showingResult(let correct):
            if correct {
                statusBadge(icon: "checkmark.circle.fill", text: "正确!", color: .green)
            } else {
                statusBadge(icon: "xmark.circle.fill", text: "错误，请重试", color: .red)
            }
        default:
            EmptyView()
        }
    }
    
    private func statusBadge(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(color)
        }
        .padding(.horizontal, UIConstants.paddingLarge)
        .padding(.vertical, UIConstants.paddingSmall)
        .background(color.opacity(0.15))
        .cornerRadius(UIConstants.cornerRadiusMedium)
    }
    
    // MARK: - Replay Buttons
    private var replayButtons: some View {
        HStack(spacing: 16) {
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
