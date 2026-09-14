import SwiftUI

public enum AuraColors {
    // Backgrounds & Glass
    public static let background = Color(UIColor.systemBackground)
    public static let secondaryBackground = Color(UIColor.secondarySystemBackground)
    public static let tertiaryBackground = Color(UIColor.tertiarySystemBackground)
    public static let glassSurface = Color.white.opacity(0.09)
    public static let glassBorder = Color.white.opacity(0.22)
    public static let glassHighlight = Color.white.opacity(0.35)
    
    // Text
    public static let textPrimary = Color.primary
    public static let textSecondary = Color.secondary
    public static let textTertiary = Color(uiColor: .tertiaryLabel)
    
    // Accents & State
    public static let accent = Color(red: 0.38, green: 0.35, blue: 0.98) // Cyber Violet
    public static let cyanAccent = Color(red: 0.12, green: 0.78, blue: 0.95) // Aurora Cyan
    public static let success = Color(red: 0.15, green: 0.85, blue: 0.55) // Emerald Neon
    public static let warning = Color(red: 1.00, green: 0.62, blue: 0.10) // Amber Glow
    public static let destructive = Color(red: 0.98, green: 0.26, blue: 0.35) // Crimson Red
    public static let urgent = Color(red: 1.00, green: 0.18, blue: 0.57) // Neon Rose
    
    // Category Colors (for Projects/Tags/Attendance)
    public static let projectBlue = Color(red: 0.20, green: 0.50, blue: 1.00)
    public static let projectPurple = Color(red: 0.65, green: 0.35, blue: 0.95)
    public static let projectPink = Color(red: 0.95, green: 0.35, blue: 0.70)
    public static let projectGreen = Color(red: 0.20, green: 0.80, blue: 0.45)
    public static let projectYellow = Color(red: 1.00, green: 0.75, blue: 0.15)
    
    // Gradients
    public static let premiumGradient = LinearGradient(
        colors: [Color(red: 0.38, green: 0.35, blue: 0.98), Color(red: 0.65, green: 0.35, blue: 0.95)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    public static let auroraBorealis = LinearGradient(
        colors: [Color(red: 0.12, green: 0.78, blue: 0.95), Color(red: 0.38, green: 0.35, blue: 0.98), Color(red: 0.95, green: 0.35, blue: 0.70)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    public static let cyberGlow = LinearGradient(
        colors: [Color(red: 0.38, green: 0.35, blue: 0.98).opacity(0.8), Color(red: 0.12, green: 0.78, blue: 0.95).opacity(0.8)],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    public static let glassGlowGradient = LinearGradient(
        colors: [Color.white.opacity(0.35), Color.white.opacity(0.08)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    public static let glassBorderSheen = LinearGradient(
        colors: [Color.white.opacity(0.40), Color.white.opacity(0.10)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    public static let punchInGradient = LinearGradient(
        colors: [Color(red: 0.12, green: 0.78, blue: 0.95), Color(red: 0.38, green: 0.35, blue: 0.98)],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    public static let punchOutGradient = LinearGradient(
        colors: [Color(red: 1.00, green: 0.35, blue: 0.45), Color(red: 0.95, green: 0.20, blue: 0.60)],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    public static let focusGradient = LinearGradient(
        colors: [Color(red: 1.00, green: 0.62, blue: 0.10), Color(red: 1.00, green: 0.18, blue: 0.57)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

extension Color {
    static var auraBackground: Color {
        Color(UIColor.systemBackground)
    }
    static var auraSecondaryBackground: Color {
        Color(UIColor.secondarySystemBackground)
    }
    static var auraTertiaryBackground: Color {
        Color(UIColor.tertiarySystemBackground)
    }
    
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let length = hexSanitized.count
        let r, g, b, a: Double
        if length == 6 {
            r = Double((rgb & 0xFF0000) >> 16) / 255.0
            g = Double((rgb & 0x00FF00) >> 8) / 255.0
            b = Double(rgb & 0x0000FF) / 255.0
            a = 1.0
        } else if length == 8 {
            r = Double((rgb & 0xFF000000) >> 24) / 255.0
            g = Double((rgb & 0x00FF0000) >> 16) / 255.0
            b = Double((rgb & 0x0000FF00) >> 8) / 255.0
            a = Double(rgb & 0x000000FF) / 255.0
        } else {
            return nil
        }

        self.init(red: r, green: g, blue: b, opacity: a)
    }
}
