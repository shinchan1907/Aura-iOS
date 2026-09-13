import SwiftUI

public struct AuraCardModifier: ViewModifier {
    var backgroundColor: Color = AuraColors.secondaryBackground
    var padding: CGFloat = AuraLayout.cardPadding
    
    public func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: AuraLayout.cornerRadiusMedium, style: .continuous))
            .shadow(
                color: AuraLayout.Shadow.subtle.color,
                radius: AuraLayout.Shadow.subtle.radius,
                x: AuraLayout.Shadow.subtle.x,
                y: AuraLayout.Shadow.subtle.y
            )
    }
}

public extension View {
    func auraCard(backgroundColor: Color = AuraColors.secondaryBackground, padding: CGFloat = AuraLayout.cardPadding) -> some View {
        self.modifier(AuraCardModifier(backgroundColor: backgroundColor, padding: padding))
    }
}
