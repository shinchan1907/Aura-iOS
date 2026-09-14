import SwiftUI
import SwiftData
import Charts

public struct ProAnalyticsHubView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(filter: #Predicate<TaskItem> { task in task.statusRaw == 2 })
    private var completedTasks: [TaskItem]
    
    @Query(filter: #Predicate<TaskItem> { task in task.statusRaw != 2 })
    private var openTasks: [TaskItem]
    
    @Query private var attendanceRecords: [AttendanceRecord]
    @Query private var focusSessions: [FocusSession]
    
    @State private var showingPaywall = false
    @State private var selectedThemeName = "Cyber Violet"
    @State private var chartData: [DailyProgress] = []
    
    private let themes = ["Cyber Violet", "Aurora Cyan", "Neon Sunset", "Emerald Glass"]
    
    public init() {}
    
    // MARK: - Productivity Score Calculation Engine (0 - 100)
    private var productivityScore: Int {
        let totalTasks = completedTasks.count + openTasks.count
        let completionRatio = totalTasks > 0 ? (Double(completedTasks.count) / Double(totalTasks)) * 40.0 : 0.0
        
        let totalFocusHours = focusSessions.reduce(0.0) { $0 + ($1.duration / 3600.0) }
        let focusScore = min(totalFocusHours * 5.0, 30.0)
        
        let validPunches = attendanceRecords.filter { $0.punchOutTime != nil }.count
        let punchScore = min(Double(validPunches) * 6.0, 30.0)
        
        let total = Int(completionRatio + focusScore + punchScore)
        return min(max(total, 10), 100)
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AuraBackgroundView()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: AuraLayout.spacingLarge) {
                        
                        // Pro Banner & Upgrade Trigger
                        proHeaderBanner
                        
                        // Productivity Score Gauge Card
                        productivityScoreGaugeCard
                        
                        // Productivity Velocity Chart
                        velocityChartCard
                        
                        // Behavioral Insights Engine
                        behavioralInsightsCard
                        
                        // Theme Customizer
                        themeCustomizerCard
                    }
                    .padding(AuraLayout.screenPadding)
                }
            }
            .navigationTitle("Aura Pro & Insights")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingPaywall) {
                ProPaywallSheet(isPresented: $showingPaywall)
            }
            .onAppear(perform: loadData)
        }
    }
    
    // MARK: - Pro Header Banner
    private var proHeaderBanner: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "crown.fill")
                        .foregroundColor(AuraColors.urgent)
                    Text("Aura Pro Subscriber")
                        .font(AuraTypography.headline)
                        .foregroundColor(AuraColors.textPrimary)
                }
                Text("Full access unlocked • $6.99/mo tier")
                    .font(AuraTypography.caption)
                    .foregroundColor(AuraColors.textSecondary)
            }
            Spacer()
            
            Button("Manage Plan") {
                showingPaywall = true
            }
            .font(AuraTypography.caption.bold())
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(AuraColors.urgent.opacity(0.15))
            .foregroundColor(AuraColors.urgent)
            .clipShape(Capsule())
        }
        .glassCard(borderColor: AuraColors.urgent.opacity(0.4), glowColor: AuraColors.urgent)
    }
    
    // MARK: - Productivity Score Gauge
    private var productivityScoreGaugeCard: some View {
        VStack(spacing: AuraLayout.spacingMedium) {
            HStack {
                Text("Productivity Index")
                    .font(AuraTypography.headline)
                    .foregroundColor(AuraColors.textSecondary)
                Spacer()
                Text("REAL-TIME")
                    .font(AuraTypography.stats)
                    .foregroundColor(AuraColors.cyanAccent)
            }
            
            ZStack {
                Circle()
                    .stroke(AuraColors.glassBorder, lineWidth: 14)
                
                Circle()
                    .trim(from: 0, to: CGFloat(productivityScore) / 100.0)
                    .stroke(
                        AuraColors.punchInGradient,
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.8, dampingFraction: 0.7), value: productivityScore)
                
                VStack(spacing: 2) {
                    Text("\(productivityScore)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(AuraColors.textPrimary)
                    Text("Out of 100")
                        .font(AuraTypography.caption)
                        .foregroundColor(AuraColors.textSecondary)
                }
            }
            .frame(width: 160, height: 160)
            .padding(.vertical, 8)
            
            HStack(spacing: AuraLayout.spacingMedium) {
                scoreSubStat(title: "Completed", value: "\(completedTasks.count)", color: AuraColors.success)
                scoreSubStat(title: "Punches", value: "\(attendanceRecords.count)", color: AuraColors.cyanAccent)
                let hours = Int(focusSessions.reduce(0.0) { $0 + $1.duration }) / 3600
                scoreSubStat(title: "Focus Time", value: "\(hours)h", color: AuraColors.projectPurple)
            }
        }
        .glassCard(borderColor: AuraColors.accent.opacity(0.3))
    }
    
    private func scoreSubStat(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(AuraTypography.title2)
                .foregroundColor(AuraColors.textPrimary)
            Text(title)
                .font(AuraTypography.caption)
                .foregroundColor(AuraColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: AuraLayout.cornerRadiusSmall))
    }
    
    // MARK: - Velocity Chart Card
    private var velocityChartCard: some View {
        VStack(alignment: .leading, spacing: AuraLayout.spacingMedium) {
            Text("Execution Velocity (7 Days)")
                .font(AuraTypography.headline)
                .foregroundColor(AuraColors.textPrimary)
            
            Chart {
                ForEach(chartData) { data in
                    BarMark(
                        x: .value("Day", data.day),
                        y: .value("Completed", data.completed)
                    )
                    .foregroundStyle(AuraColors.punchInGradient)
                    .cornerRadius(6)
                    
                    LineMark(
                        x: .value("Day", data.day),
                        y: .value("Created", data.created)
                    )
                    .foregroundStyle(AuraColors.warning)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [4]))
                }
            }
            .frame(height: 180)
            
            HStack(spacing: AuraLayout.spacingMedium) {
                Label("Completed Tasks", systemImage: "square.fill")
                    .foregroundColor(AuraColors.cyanAccent)
                Label("Created Tasks", systemImage: "circle")
                    .foregroundColor(AuraColors.warning)
            }
            .font(AuraTypography.caption)
        }
        .glassCard()
    }
    
    // MARK: - Behavioral Insights
    private var behavioralInsightsCard: some View {
        VStack(alignment: .leading, spacing: AuraLayout.spacingMedium) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(AuraColors.projectPurple)
                    .font(.title3)
                Text("Behavioral AI Insights")
                    .font(AuraTypography.headline)
                    .foregroundColor(AuraColors.textPrimary)
            }
            
            VStack(spacing: AuraLayout.spacingSmall) {
                if productivityScore >= 75 {
                    insightTile(icon: "star.fill", text: "Exceptional discipline! You are executing in the top 5% of productivity tiers.", color: AuraColors.success)
                } else if productivityScore >= 45 {
                    insightTile(icon: "chart.line.uptrend.xyaxis", text: "Steady velocity. Try scheduling 1 extra Focus Session tomorrow.", color: AuraColors.accent)
                } else {
                    insightTile(icon: "lightbulb.fill", text: "Low punch or focus hours detected. Try breaking down tasks into smaller subtasks.", color: AuraColors.warning)
                }
            }
        }
        .glassCard()
    }
    
    private func insightTile(icon: String, text: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: AuraLayout.spacingMedium) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.headline)
            Text(text)
                .font(AuraTypography.subheadline)
                .foregroundColor(AuraColors.textSecondary)
            Spacer()
        }
        .padding(10)
        .background(color.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: AuraLayout.cornerRadiusSmall))
    }
    
    // MARK: - Theme Customizer
    private var themeCustomizerCard: some View {
        VStack(alignment: .leading, spacing: AuraLayout.spacingMedium) {
            Text("Glass Theme Palette")
                .font(AuraTypography.headline)
                .foregroundColor(AuraColors.textPrimary)
            
            HStack(spacing: AuraLayout.spacingSmall) {
                ForEach(themes, id: \.self) { theme in
                    let isSelected = selectedThemeName == theme
                    Button(action: {
                        withAnimation { selectedThemeName = theme }
                        AuraHaptics.selection()
                    }) {
                        Text(theme)
                            .font(AuraTypography.caption.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(isSelected ? AuraColors.accent.opacity(0.25) : AuraColors.glassSurface)
                            .foregroundColor(isSelected ? AuraColors.accent : AuraColors.textSecondary)
                            .overlay(Capsule().stroke(isSelected ? AuraColors.accent : AuraColors.glassBorder, lineWidth: 1))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .glassCard()
    }
    
    private func loadData() {
        chartData = AnalyticsService.shared.getDailyProgress(for: -7, modelContext: modelContext)
    }
}
