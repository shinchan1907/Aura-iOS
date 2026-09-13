import SwiftUI

public enum AuraColors {
    // Backgrounds
    public static let background = Color("Background") // Define in Assets or use system
    public static let secondaryBackground = Color("SecondaryBackground")
    public static let tertiaryBackground = Color("TertiaryBackground")
    
    // Text
    public static let textPrimary = Color.primary
    public static let textSecondary = Color.secondary
    public static let textTertiary = Color(uiColor: .tertiaryLabel)
    
    // Accents & State
    public static let accent = Color.indigo
    public static let success = Color.mint
    public static let warning = Color.orange
    public static let destructive = Color.red
    
    // Category Colors (for Projects/Tags)
    public static let projectBlue = Color.blue
    public static let projectPurple = Color.purple
    public static let projectPink = Color.pink
    public static let projectGreen = Color.green
    public static let projectYellow = Color.yellow
    
    // Gradients
    public static let premiumGradient = LinearGradient(
        colors: [Color.indigo.opacity(0.8), Color.purple.opacity(0.8)],
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
