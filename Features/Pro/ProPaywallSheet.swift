import SwiftUI

public struct ProPaywallSheet: View {
    @Binding var isPresented: Bool
    @State private var selectedPlan: SubscriptionPlan = .monthly
    @State private var isSubscribed = false
    
    enum SubscriptionPlan {
        case monthly, yearly
    }
    
    public init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }
    
    public var body: some View {
        ZStack {
            AuraBackgroundView()
            
            ScrollView {
                VStack(spacing: AuraLayout.spacingLarge) {
                    
                    // Close Button Header
                    HStack {
                        Spacer()
                        Button(action: { isPresented = false }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(AuraColors.textSecondary)
                        }
                    }
                    
                    // Hero Crown Header
                    VStack(spacing: AuraLayout.spacingSmall) {
                        ZStack {
                            Circle()
                                .fill(AuraColors.urgent.opacity(0.2))
                                .frame(width: 80, height: 80)
                            Image(systemName: "crown.fill")
                                .font(.system(size: 38))
                                .foregroundColor(AuraColors.urgent)
                        }
                        
                        Text("Aura Pro Workspace")
                            .font(AuraTypography.heroTitle)
                            .foregroundColor(AuraColors.textPrimary)
                        
                        Text("Supercharge your daily execution, office discipline, and deep work productivity.")
                            .font(AuraTypography.body)
                            .foregroundColor(AuraColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // Value Proposition Checklist
                    VStack(alignment: .leading, spacing: AuraLayout.spacingMedium) {
                        featureRow(icon: "bolt.shield.fill", title: "Unlimited Dynamic Island", subtitle: "Real-time Live Activity shift timers & deep work counters", color: AuraColors.accent)
                        featureRow(icon: "building.2.crop.circle.fill", title: "Automated GPS Geofencing", subtitle: "Auto-remind & punch in when stepping into office boundaries", color: AuraColors.cyanAccent)
                        featureRow(icon: "brain.head.profile", title: "Behavioral AI Score Engine", subtitle: "0–100 daily productivity index & velocity metrics", color: AuraColors.projectPurple)
                        featureRow(icon: "folder.fill.badge.plus", title: "Unlimited Workspaces", subtitle: "Create unlimited projects, milestones, and Kanban boards", color: AuraColors.success)
                        featureRow(icon: "paintpalette.fill", title: "Custom Glass Themes", subtitle: "Cyber Violet, Aurora Cyan, Neon Sunset, Emerald Glass", color: AuraColors.warning)
                    }
                    .glassCard()
                    
                    // Pricing Selector Cards
                    HStack(spacing: AuraLayout.spacingMedium) {
                        planCard(
                            plan: .monthly,
                            title: "Monthly",
                            price: "$6.99",
                            subtitle: "Billed monthly",
                            badge: nil
                        )
                        planCard(
                            plan: .yearly,
                            title: "Annual",
                            price: "$4.99/mo",
                            subtitle: "$59.99 billed yearly",
                            badge: "SAVE 30%"
                        )
                    }
                    
                    // Primary Subscribe CTA
                    if isSubscribed {
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.largeTitle)
                                .foregroundColor(AuraColors.success)
                            Text("Aura Pro Active!")
                                .font(AuraTypography.title2)
                                .foregroundColor(AuraColors.textPrimary)
                        }
                        .glassCard()
                    } else {
                        AuraGlassButton(
                            title: "Start 7-Day Free Trial",
                            iconName: "sparkles",
                            gradient: AuraColors.punchInGradient
                        ) {
                            subscribe()
                        }
                    }
                    
                    // Footer Terms & Restore
                    HStack(spacing: AuraLayout.spacingLarge) {
                        Button("Restore Purchases") {}
                        Text("•")
                        Button("Terms of Use") {}
                        Text("•")
                        Button("Privacy Policy") {}
                    }
                    .font(AuraTypography.caption)
                    .foregroundColor(AuraColors.textSecondary)
                    .padding(.top, AuraLayout.spacingSmall)
                }
                .padding(AuraLayout.screenPadding)
            }
        }
    }
    
    private func featureRow(icon: String, title: String, subtitle: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: AuraLayout.spacingMedium) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AuraTypography.headline)
                    .foregroundColor(AuraColors.textPrimary)
                Text(subtitle)
                    .font(AuraTypography.caption)
                    .foregroundColor(AuraColors.textSecondary)
            }
            Spacer()
        }
    }
    
    private func planCard(plan: SubscriptionPlan, title: String, price: String, subtitle: String, badge: String?) -> some View {
        let isSelected = selectedPlan == plan
        
        return Button(action: {
            withAnimation { selectedPlan = plan }
            AuraHaptics.selection()
        }) {
            VStack(spacing: 6) {
                if let badgeText = badge {
                    Text(badgeText)
                        .font(AuraTypography.stats)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(AuraColors.urgent)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
                
                Text(title)
                    .font(AuraTypography.headline)
                    .foregroundColor(AuraColors.textPrimary)
                Text(price)
                    .font(AuraTypography.title1)
                    .foregroundColor(isSelected ? AuraColors.cyanAccent : AuraColors.textPrimary)
                Text(subtitle)
                    .font(AuraTypography.caption)
                    .foregroundColor(AuraColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .glassCard(borderColor: isSelected ? AuraColors.cyanAccent : AuraColors.glassBorder)
        }
        .buttonStyle(.plain)
    }
    
    private func subscribe() {
        withAnimation {
            isSubscribed = true
            AuraHaptics.taskCompletion()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isPresented = false
        }
    }
}
