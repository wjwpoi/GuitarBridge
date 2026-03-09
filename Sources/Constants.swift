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
    }
    
    /// UI 相关
    enum UI {
        static let fretboardHeight: CGFloat = 220
        static let cornerRadius: CGFloat = 12
        static let spacing: CGFloat = 16
    }
}
