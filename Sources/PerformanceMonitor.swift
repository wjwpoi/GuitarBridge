import Foundation
import os.log

// MARK: - 性能监控
/// 简单的性能监控工具
@MainActor
final class PerformanceMonitor {
    static let shared = PerformanceMonitor()
    
    private let logger = Logger(subsystem: "com.guitarbridge", category: "Performance")
    private var measurements: [String: CFAbsoluteTime] = [:]
    
    private init() {}
    
    /// 开始计时
    func start(_ label: String) {
        measurements[label] = CFAbsoluteTimeGetCurrent()
    }
    
    /// 结束计时并记录
    func end(_ label: String) {
        guard let startTime = measurements[label] else { return }
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        #if DEBUG
        logger.debug("\(label): \(duration * 1000, format: .fixed(precision: 2))ms")
        #endif
        measurements.removeValue(forKey: label)
    }
    
    /// 测量闭包执行时间
    func measure<T>(_ label: String, block: () -> T) -> T {
        start(label)
        let result = block()
        end(label)
        return result
    }
}
