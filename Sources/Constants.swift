import Foundation

// MARK: - 常量定义

/// 调性列表
let musicKeys = ["C", "D", "E", "F", "G", "A", "B"]

// MARK: - 练习相关常量
enum PracticeConstants {
    /// 默认问题数量
    static let defaultQuestionCount = 10
    
    /// 简单难度问题数
    static let easyQuestionCount = 5
    
    /// 中等难度问题数
    static let mediumQuestionCount = 10
    
    /// 困难难度问题数
    static let hardQuestionCount = 15
    
    /// 音频相关
    enum Audio {
        static let defaultVolume: Float = 0.8
        static let crossfadeDuration: Double = 0.15
        static let samplePlaybackDuration: UInt64 = 1_500_000_000  // 1.5秒采样播放
        static let noteHoldDuration: UInt64 = 1_500_000_000  // 1.5秒音符保持
        static let anchorNoteDelay: UInt64 = 800_000_000  // 800ms锚点音重复间隔
        static let anchorToTargetDelay: UInt64 = 800_000_000  // 800ms锚点到目标音间隔
        static let targetToAnswerDelay: UInt64 = 800_000_000  // 800ms目标音到答题间隔
        static let correctAnswerDelay: UInt64 = 1_500_000_000  // 1.5秒正确答案停留
        static let wrongAnswerDelay: UInt64 = 1_500_000_000  // 1.5秒错误答案停留
    }
    
    /// UI 相关
    enum UI {
        static let fretboardHeight: CGFloat = 220
        static let cornerRadius: CGFloat = 12
        static let spacing: CGFloat = 16
    }
}
