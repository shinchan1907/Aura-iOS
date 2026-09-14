import SwiftUI

public struct GlassmorphicCardModifier: ViewModifier {
    var cornerRadius: CGFloat = AuraLayout.cornerRadiusMedium
    var padding: CGFloat = AuraLayout.cardPadding
    var borderColor: Color = AuraColors.glassBorder
    var glowColor: Color = Color.clear

    public func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                    
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(AuraColors.glassSurface)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                borderColor,
                                borderColor.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: glowColor != .clear ? glowColor.opacity(0.25) : AuraLayout.Shadow.subtle.color,
                radius: glowColor != .clear ? 12 : AuraLayout.Shadow.subtle.radius,
                x: 0,
                y: glowColor != .clear ? 4 : AuraLayout.Shadow.subtle.y
            )
    }
}

public extension View {
    func glassCard(
        cornerRadius: CGFloat = AuraLayout.cornerRadiusMedium,
        padding: CGFloat = AuraLayout.cardPadding,
        borderColor: Color = AuraColors.glassBorder,
        glowColor: Color = Color.clear
    ) -> some View {
        self.modifier(GlassmorphicCardModifier(
            cornerRadius: cornerRadius,
            padding: padding,
            borderColor: borderColor,
            glowColor: glowColor
        ))
    }
}
