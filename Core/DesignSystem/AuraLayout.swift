import SwiftUI

public enum AuraLayout {
    // Spacing
    public static let spacingTight: CGFloat = 4
    public static let spacingSmall: CGFloat = 8
    public static let spacingMedium: CGFloat = 16
    public static let spacingLarge: CGFloat = 24
    public static let spacingXLarge: CGFloat = 32
    
    // Corner Radii
    public static let cornerRadiusSmall: CGFloat = 8
    public static let cornerRadiusMedium: CGFloat = 16
    public static let cornerRadiusLarge: CGFloat = 24
    public static let cornerRadiusXLarge: CGFloat = 32
    
    // Padding
    public static let screenPadding: CGFloat = 20
    public static let cardPadding: CGFloat = 16
    
    // Shadows
    public struct Shadow {
        public static let subtle = (color: Color.black.opacity(0.05), radius: CGFloat(4), x: CGFloat(0), y: CGFloat(2))
        public static let medium = (color: Color.black.opacity(0.08), radius: CGFloat(10), x: CGFloat(0), y: CGFloat(4))
        public static let floating = (color: Color.black.opacity(0.12), radius: CGFloat(20), x: CGFloat(0), y: CGFloat(8))
    }
}
