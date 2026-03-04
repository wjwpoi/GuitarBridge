import Foundation

#if canImport(UIKit)
import UIKit
#endif

struct HapticManager {
    #if canImport(UIKit)
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    #else
    // Fallback for platforms without UIKit haptics
    static func impact(_ style: ImpactStyle) {
        // No-op on unsupported platforms
    }
    
    static func notification(_ type: NotificationType) {
        // No-op on unsupported platforms
    }
    
    enum ImpactStyle {
        case light
        case medium
        case heavy
    }
    
    enum NotificationType {
        case success
        case warning
        case error
    }
    #endif
}
