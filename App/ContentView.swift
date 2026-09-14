import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "sun.max.fill")
                }
                .tag(0)
            
            InboxView()
                .tabItem {
                    Label("Inbox", systemImage: "tray.fill")
                }
                .tag(1)
            
            AttendanceView()
                .tabItem {
                    Label("Attendance", systemImage: "building.2.crop.circle.fill")
                }
                .tag(2)
            
            KanbanBoardView()
                .tabItem {
                    Label("Kanban", systemImage: "rectangle.3.group.fill")
                }
                .tag(3)
            
            ProjectListView()
                .tabItem {
                    Label("Projects", systemImage: "folder.fill")
                }
                .tag(4)
            
            CalendarTimelineView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
                .tag(5)
            
            AnalyticsDashboardView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.bar.fill")
                }
                .tag(6)
        }
        .tint(AuraColors.accent)
    }
}
