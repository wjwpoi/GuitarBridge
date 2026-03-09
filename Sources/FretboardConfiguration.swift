import SwiftUI

// MARK: - Fretboard Configuration
/// FretboardView 的配置封装
struct FretboardConfiguration {
    var tuning: Tuning
    var theme: Theme
    var isDisabled: Bool
    var selectedPosition: FretPosition?
    var lastAnswerCorrect: Bool?
    var showDegrees: Bool
    var showScale: Bool
    var currentScale: ScaleType
    var currentKey: String
    var showNoteNames: Bool
    var showFretNumbers: Bool
    
    /// 从 ContentView 的状态创建配置
    static func from(
        tuning: Tuning,
        theme: Theme,
        trainingState: TrainingState,
        userAnswer: FretPosition?,
        lastAnswerCorrect: Bool?,
        showDegrees: Bool,
        showScale: Bool,
        currentScale: ScaleType,
        currentKey: String,
        showNoteNames: Bool,
        showFretNumbers: Bool
    ) -> FretboardConfiguration {
        FretboardConfiguration(
            tuning: tuning,
            theme: theme,
            isDisabled: trainingState != .awaitingAnswer,
            selectedPosition: userAnswer,
            lastAnswerCorrect: lastAnswerCorrect,
            showDegrees: showDegrees,
            showScale: showScale,
            currentScale: currentScale,
            currentKey: currentKey,
            showNoteNames: showNoteNames,
            showFretNumbers: showFretNumbers
        )
    }
}

// MARK: - Fretboard View Modifier
/// 简化 FretboardView 使用的 ViewModifier
struct FretboardModifier: ViewModifier {
    let configuration: FretboardConfiguration
    let onFretTapped: (FretPosition) -> Void
    
    func body(content: Content) -> some View {
        content
            .frame(height: 220)
    }
}

extension View {
    func fretboard(
        _ configuration: FretboardConfiguration,
        onFretTapped: @escaping (FretPosition) -> Void
    ) -> some View {
        modifier(FretboardModifier(
            configuration: configuration,
            onFretTapped: onFretTapped
        ))
    }
}
