import SwiftUI

public struct AuraPrimaryButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AuraTypography.headline)
            .foregroundColor(.white)
            .padding(.vertical, AuraLayout.spacingMedium)
            .padding(.horizontal, AuraLayout.spacingLarge)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: AuraLayout.cornerRadiusMedium, style: .continuous)
                    .fill(AuraColors.accent)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

public struct AuraSecondaryButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AuraTypography.headline)
            .foregroundColor(AuraColors.accent)
            .padding(.vertical, AuraLayout.spacingMedium)
            .padding(.horizontal, AuraLayout.spacingLarge)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: AuraLayout.cornerRadiusMedium, style: .continuous)
                    .fill(AuraColors.accent.opacity(0.1))
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

public extension ButtonStyle where Self == AuraPrimaryButtonStyle {
    static var auraPrimary: AuraPrimaryButtonStyle {
        AuraPrimaryButtonStyle()
    }
}

public extension ButtonStyle where Self == AuraSecondaryButtonStyle {
    static var auraSecondary: AuraSecondaryButtonStyle {
        AuraSecondaryButtonStyle()
    }
}
