import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab Content
            Group {
                switch selectedTab {
                case 0:
                    TodayView()
                case 1:
                    InboxView()
                case 2:
                    AttendanceView()
                case 3:
                    KanbanBoardView()
                case 4:
                    ProjectListView()
                case 5:
                    ProAnalyticsHubView()
                default:
                    TodayView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Custom Floating Glass Tab Bar
            floatingGlassTabBar
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
    
    private var floatingGlassTabBar: some View {
        HStack(spacing: 0) {
            tabItem(index: 0, title: "Today", icon: "bolt.fill")
            tabItem(index: 1, title: "Inbox", icon: "tray.fill")
            tabItem(index: 2, title: "Punch", icon: "building.2.crop.circle.fill")
            tabItem(index: 3, title: "Kanban", icon: "rectangle.3.group.fill")
            tabItem(index: 4, title: "Projects", icon: "folder.fill")
            tabItem(index: 5, title: "Pro", icon: "crown.fill", isPro: true)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(AuraColors.glassSurface)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [AuraColors.glassBorder, AuraColors.glassBorder.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.2), radius: 16, x: 0, y: 8)
        .padding(.horizontal, AuraLayout.screenPadding)
        .padding(.bottom, 12)
    }
    
    private func tabItem(index: Int, title: String, icon: String, isPro: Bool = false) -> some View {
        let isSelected = selectedTab == index
        let color = isPro ? AuraColors.urgent : AuraColors.accent
        
        return Button(action: {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                selectedTab = index
                AuraHaptics.selection()
            }
        }) {
            VStack(spacing: 4) {
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(color.opacity(0.2))
                            .frame(width: 28, height: 28)
                            .transition(.scale.combined(with: .opacity))
                    }
                    
                    Image(systemName: icon)
                        .font(.system(size: isSelected ? 18 : 16, weight: isSelected ? .bold : .medium))
                        .foregroundColor(isSelected ? color : AuraColors.textSecondary)
                }
                
                Text(title)
                    .font(AuraTypography.stats)
                    .foregroundColor(isSelected ? color : AuraColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}
