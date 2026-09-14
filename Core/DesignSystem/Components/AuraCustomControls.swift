import SwiftUI

// MARK: - Custom Glass Text Field
public struct AuraGlassTextField: View {
    var placeholder: String
    @Binding var text: String
    var iconName: String? = nil
    var isSecure: Bool = false
    
    public init(placeholder: String, text: Binding<String>, iconName: String? = nil, isSecure: Bool = false) {
        self.placeholder = placeholder
        self._text = text
        self.iconName = iconName
        self.isSecure = isSecure
    }
    
    public var body: some View {
        HStack(spacing: AuraLayout.spacingSmall) {
            if let icon = iconName {
                Image(systemName: icon)
                    .foregroundColor(AuraColors.accent)
                    .font(.headline)
            }
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .font(AuraTypography.body)
                    .foregroundColor(AuraColors.textPrimary)
            } else {
                TextField(placeholder, text: $text)
                    .font(AuraTypography.body)
                    .foregroundColor(AuraColors.textPrimary)
            }
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AuraColors.textSecondary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .glassCard(padding: 0)
    }
}

// MARK: - Custom Glass Segmented Picker
public struct AuraGlassSegmentedPicker<T: Hashable>: View {
    let items: [T]
    @Binding var selection: T
    var titleKeyPath: KeyPath<T, String>
    
    public init(items: [T], selection: Binding<T>, titleKeyPath: KeyPath<T, String>) {
        self.items = items
        self._selection = selection
        self.titleKeyPath = titleKeyPath
    }
    
    public var body: some View {
        HStack(spacing: 4) {
            ForEach(items, id: \.self) { item in
                let isSelected = selection == item
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selection = item
                        AuraHaptics.selection()
                    }
                }) {
                    Text(item[keyPath: titleKeyPath])
                        .font(AuraTypography.subheadline.weight(isSelected ? .bold : .regular))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(isSelected ? AuraColors.accent.opacity(0.25) : Color.clear)
                        .foregroundColor(isSelected ? AuraColors.accent : AuraColors.textSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: AuraLayout.cornerRadiusSmall))
                        .overlay(
                            RoundedRectangle(cornerRadius: AuraLayout.cornerRadiusSmall)
                                .stroke(isSelected ? AuraColors.accent : Color.clear, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .glassCard(padding: 0)
    }
}

// MARK: - Custom Glass Toggle Switch
public struct AuraGlassToggle: View {
    var title: String
    var iconName: String? = nil
    @Binding var isOn: Bool
    
    public init(title: String, iconName: String? = nil, isOn: Binding<Bool>) {
        self.title = title
        self.iconName = iconName
        self._isOn = isOn
    }
    
    public var body: some View {
        HStack {
            if let icon = iconName {
                Image(systemName: icon)
                    .foregroundColor(isOn ? AuraColors.success : AuraColors.textSecondary)
                    .font(.headline)
            }
            Text(title)
                .font(AuraTypography.body)
                .foregroundColor(AuraColors.textPrimary)
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(AuraColors.accent)
        }
        .glassCard(padding: 12)
    }
}

// MARK: - Custom Glass Action Button
public struct AuraGlassButton: View {
    var title: String
    var iconName: String? = nil
    var gradient: LinearGradient = AuraColors.premiumGradient
    var action: () -> Void
    
    public init(title: String, iconName: String? = nil, gradient: LinearGradient = AuraColors.premiumGradient, action: @escaping () -> Void) {
        self.title = title
        self.iconName = iconName
        self.gradient = gradient
        self.action = action
    }
    
    public var body: some View {
        Button(action: {
            AuraHaptics.impact(style: .medium)
            action()
        }) {
            HStack(spacing: AuraLayout.spacingSmall) {
                if let icon = iconName {
                    Image(systemName: icon)
                        .font(.headline)
                }
                Text(title)
                    .font(AuraTypography.headline.bold())
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(gradient)
            .clipShape(RoundedRectangle(cornerRadius: AuraLayout.cornerRadiusMedium))
            .shadow(color: AuraColors.accent.opacity(0.3), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
    }
}
