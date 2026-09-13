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
}
