import SwiftUI
import Charts
import SwiftData

public struct AnalyticsDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var timeRange: TimeRange = .sevenDays
    
    // In a real app, these would be populated from AnalyticsService.
    // We'll mock the chart data to show the intended design.
    private let chartData: [DailyProgress] = [
        DailyProgress(day: "Mon", completed: 3, created: 5),
        DailyProgress(day: "Tue", completed: 5, created: 4),
        DailyProgress(day: "Wed", completed: 2, created: 2),
        DailyProgress(day: "Thu", completed: 8, created: 7),
        DailyProgress(day: "Fri", completed: 6, created: 6),
        DailyProgress(day: "Sat", completed: 1, created: 0),
        DailyProgress(day: "Sun", completed: 4, created: 3)
    ]
    
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
                        
                        // Summary Cards
                        HStack(spacing: AuraLayout.spacingMedium) {
                            statCard(title: "Completed", value: "29", icon: "checkmark.circle.fill", color: AuraColors.success)
                            statCard(title: "Focus Time", value: "14h", icon: "bolt.fill", color: AuraColors.projectPurple)
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
                        .auraCard()
                        
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
                                insightRow(icon: "calendar.badge.clock", text: "You are most productive on Thursdays.", type: .positive)
                                insightRow(icon: "arrow.uturn.right", text: "Tasks are rescheduled 1.5 times on average.", type: .neutral)
                                insightRow(icon: "clock.badge.exclamationmark", text: "Estimates are consistently 20% too optimistic.", type: .warning)
                            }
                        }
                        .auraCard()
                        
                    }
                    .padding(AuraLayout.screenPadding)
                }
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.large)
        }
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
        .background(AuraColors.tertiaryBackground)
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
        .auraCard()
    }
}

struct DailyProgress: Identifiable {
    let id = UUID()
    let day: String
    let completed: Int
    let created: Int
}
