import SwiftUI

// MARK: - Tone Mode
enum ToneMode: String, CaseIterable, Identifiable {
    case clean = "Clean"
    case distortion = "Distortion"
    case telecaster = "Telecaster"

    var id: String { rawValue }
}

// MARK: - View Mode
enum ViewMode: String, CaseIterable, Identifiable {
    case normal = "Normal"
    case stage = "Stage"

    var id: String { rawValue }
}

// MARK: - Theme
struct Theme {
    // Background colors
    let backgroundGradient: LinearGradient
    let fretboardBackground: LinearGradient
    
    // Fret colors
    let fretGradient: LinearGradient
    let fretWireColor: Color
    
    // String colors
    let stringColor: Color
    let stringShadowColor: Color
    
    // Accent
    let accentGlowColor: Color
    let accentGlowIntensity: Double
    
    // Inlay color
    let inlayColor: Color
    
    static let clean = Theme(
        backgroundGradient: LinearGradient(
            colors: [Color(hex: "1a1a2e"), Color(hex: "16213e")],
            startPoint: .top,
            endPoint: .bottom
        ),
        fretboardBackground: LinearGradient(
            colors: [Color(hex: "2d1b0e"), Color(hex: "1a0f07")],
            startPoint: .top,
            endPoint: .bottom
        ),
        fretGradient: LinearGradient(
            colors: [Color(hex: "888888"), Color(hex: "cccccc"), Color(hex: "888888")],
            startPoint: .top,
            endPoint: .bottom
        ),
        fretWireColor: Color(hex: "666666"),
        stringColor: Color(hex: "e8e8e8"),
        stringShadowColor: Color.black.opacity(0.5),
        accentGlowColor: Color.cyan,
        accentGlowIntensity: 0.5,
        inlayColor: Color(hex: "f5f5f5")
    )

    static let distortion = Theme(
        backgroundGradient: LinearGradient(
            colors: [Color(hex: "0d0d0d"), Color(hex: "1a1a1a")],
            startPoint: .top,
            endPoint: .bottom
        ),
        fretboardBackground: LinearGradient(
            colors: [Color(hex: "1a1a1a"), Color(hex: "0a0a0a")],
            startPoint: .top,
            endPoint: .bottom
        ),
        fretGradient: LinearGradient(
            colors: [Color(hex: "444444"), Color(hex: "777777"), Color(hex: "444444")],
            startPoint: .top,
            endPoint: .bottom
        ),
        fretWireColor: Color(hex: "333333"),
        stringColor: Color(hex: "cccccc"),
        stringShadowColor: Color(hex: "ff6600").opacity(0.3),
        accentGlowColor: Color(hex: "ff6600"),
        accentGlowIntensity: 0.6,
        inlayColor: Color(hex: "ff6600")
    )

    static func theme(for mode: ToneMode) -> Theme {
        switch mode {
        case .clean: return .clean
        case .distortion: return .distortion
        case .telecaster: return .telecaster
        }
    }
    
    // Telecaster Theme - Bright and twangy
    static let telecaster = Theme(
        backgroundGradient: LinearGradient(
            colors: [Color(hex: "1e3a5f"), Color(hex: "2d5a87")],
            startPoint: .top,
            endPoint: .bottom
        ),
        fretboardBackground: LinearGradient(
            colors: [Color(hex: "4a2c2a"), Color(hex: "2d1a18")],
            startPoint: .top,
            endPoint: .bottom
        ),
        fretGradient: LinearGradient(
            colors: [Color(hex: "999999"), Color(hex: "dddddd"), Color(hex: "999999")],
            startPoint: .top,
            endPoint: .bottom
        ),
        fretWireColor: Color(hex: "888888"),
        stringColor: Color(hex: "fffacd"),
        stringShadowColor: Color.black.opacity(0.4),
        accentGlowColor: Color(hex: "ff8c00"),
        accentGlowIntensity: 0.55,
        inlayColor: Color(hex: "ffefd5")
    )
    
    // Stage Mode Theme - Neon/Cyberpunk style
    static let stage = Theme(
        backgroundGradient: LinearGradient(
            colors: [Color(hex: "0f0c29"), Color(hex: "302b63"), Color(hex: "24243e")],
            startPoint: .top,
            endPoint: .bottom
        ),
        fretboardBackground: LinearGradient(
            colors: [Color(hex: "1a1a2e"), Color(hex: "0f0f1a")],
            startPoint: .top,
            endPoint: .bottom
        ),
        fretGradient: LinearGradient(
            colors: [Color(hex: "666666"), Color(hex: "aaaaaa"), Color(hex: "666666")],
            startPoint: .top,
            endPoint: .bottom
        ),
        fretWireColor: Color(hex: "888888"),
        stringColor: Color(hex: "00ffff"),
        stringShadowColor: Color.cyan.opacity(0.8),
        accentGlowColor: Color.purple,
        accentGlowIntensity: 1.0,
        inlayColor: Color.purple
    )
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
