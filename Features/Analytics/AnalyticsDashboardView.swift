import SwiftUI
import Charts
import SwiftData

public struct AnalyticsDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var timeRange: TimeRange = .sevenDays
    
    // In a real app, these would be populated from AnalyticsService.
    // We'll mock the chart data to show the intended design.
    @State private var chartData: [DailyProgress] = []
    @State private var analytics: AnalyticsService.AnalyticsData = AnalyticsService.AnalyticsData(tasksCompleted: 0, tasksCreated: 0, overdueTasks: 0, totalFocusTime: 0, completionRate: 0)
    
    enum TimeRange: String, CaseIterable, Identifiable {
        case today = "Today"
        case sevenDays = "7 Days"
        case thirtyDays = "30 Days"
        var id: String { self.rawValue }
    }
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AuraColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: AuraLayout.spacingLarge) {
                        
                        Picker("Time Range", selection: $timeRange) {
                            ForEach(TimeRange.allCases) { range in
                                Text(range.rawValue).tag(range)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.bottom, AuraLayout.spacingMedium)
                        .onChange(of: timeRange) { _, _ in
                            loadAnalytics()
                        }
                        
                        // Summary Cards
                        HStack(spacing: AuraLayout.spacingMedium) {
                            statCard(title: "Completed", value: "\(analytics.tasksCompleted)", icon: "checkmark.circle.fill", color: AuraColors.success)
                            let hours = Int(analytics.totalFocusTime) / 3600
                            statCard(title: "Focus Time", value: "\(hours)h", icon: "bolt.fill", color: AuraColors.projectPurple)
                        }
                        
                        // Main Chart
                        VStack(alignment: .leading, spacing: AuraLayout.spacingMedium) {
                            Text("Completion Trend")
                                .font(AuraTypography.title2)
                                .foregroundColor(AuraColors.textPrimary)
                            
                            Chart {
                                ForEach(chartData) { data in
                                    BarMark(
                                        x: .value("Day", data.day),
                                        y: .value("Completed", data.completed)
                                    )
                                    .foregroundStyle(AuraColors.accent)
                                    .cornerRadius(4)
                                    
                                    LineMark(
                                        x: .value("Day", data.day),
                                        y: .value("Created", data.created)
                                    )
                                    .foregroundStyle(AuraColors.warning)
                                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                                    .symbol(Circle().strokeBorder(lineWidth: 2))
                                }
                            }
                            .frame(height: 200)
                            .chartYAxis {
                                AxisMarks(position: .leading)
                            }
                            
                            HStack {
                                Label("Completed", systemImage: "square.fill").foregroundColor(AuraColors.accent)
                                Label("Created", systemImage: "circle").foregroundColor(AuraColors.warning)
                            }
                            .font(AuraTypography.caption)
                        }
                        .glassCard()
                        
                        // Behavioral Insights Engine
                        VStack(alignment: .leading, spacing: AuraLayout.spacingMedium) {
                            HStack {
                                Image(systemName: "brain.head.profile")
                                    .foregroundColor(AuraColors.projectPurple)
                                Text("Behavioral Insights")
                                    .font(AuraTypography.title2)
                                    .foregroundColor(AuraColors.textPrimary)
                            }
                            
                            VStack(spacing: AuraLayout.spacingSmall) {
                                if analytics.completionRate > 0.8 {
                                    insightRow(icon: "star.fill", text: "Incredible completion rate!", type: .positive)
                                } else if analytics.completionRate < 0.3 {
                                    insightRow(icon: "arrow.uturn.right", text: "Try breaking down your tasks.", type: .warning)
                                } else {
                                    insightRow(icon: "chart.line.uptrend.xyaxis", text: "You're on track.", type: .neutral)
                                }
                            }
                        }
                        .glassCard()
                        
                    }
                    .padding(AuraLayout.screenPadding)
                }
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.large)
            .onAppear(perform: loadAnalytics)
        }
    }
    
    private func loadAnalytics() {
        let daysOffset = timeRange == .sevenDays ? -7 : (timeRange == .thirtyDays ? -30 : -1)
        if timeRange == .sevenDays {
            analytics = AnalyticsService.shared.getLast7DaysAnalytics(modelContext: modelContext)
        } else {
            analytics = AnalyticsService.shared.getLast30DaysAnalytics(modelContext: modelContext)
        }
        chartData = AnalyticsService.shared.getDailyProgress(for: daysOffset, modelContext: modelContext)
    }
    
    private func insightRow(icon: String, text: String, type: InsightType) -> some View {
        HStack(alignment: .top, spacing: AuraLayout.spacingMedium) {
            Image(systemName: icon)
                .foregroundColor(colorForInsight(type))
                .font(.title3)
            Text(text)
                .font(AuraTypography.body)
                .foregroundColor(AuraColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(AuraLayout.spacingMedium)
        .background(AuraColors.glassSurface)
        .clipShape(RoundedRectangle(cornerRadius: AuraLayout.cornerRadiusSmall))
    }
    
    private enum InsightType {
        case positive, neutral, warning
    }
    
    private func colorForInsight(_ type: InsightType) -> Color {
        switch type {
        case .positive: return AuraColors.success
        case .neutral: return AuraColors.accent
        case .warning: return AuraColors.warning
        }
    }
    
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: AuraLayout.spacingSmall) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            Text(value)
                .font(AuraTypography.heroTitle)
                .foregroundColor(AuraColors.textPrimary)
            Text(title)
                .font(AuraTypography.subheadline)
                .foregroundColor(AuraColors.textSecondary)
        }
        .glassCard()
    }
}
