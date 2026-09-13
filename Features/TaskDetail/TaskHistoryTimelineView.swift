import SwiftUI
import SwiftData

public struct TaskHistoryTimelineView: View {
    let task: TaskItem
    @Environment(\.dismiss) private var dismiss
    
    // Sort events earliest first for a chronological journey
    private var sortedEvents: [TaskHistory] {
        task.historyEvents.sorted { $0.timestamp < $1.timestamp }
    }
    
    private var totalFocusTime: TimeInterval {
        task.focusSessions.reduce(0) { $0 + $1.duration }
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AuraColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: AuraLayout.spacingLarge) {
                        
                        // Journey Summary Header
                        journeySummary
                        
                        // The Timeline
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(Array(sortedEvents.enumerated()), id: \.element.id) { index, event in
                                HStack(alignment: .top, spacing: AuraLayout.spacingMedium) {
                                    
                                    // Timeline Graphic
                                    VStack(spacing: 0) {
                                        Circle()
                                            .fill(colorForEvent(event.eventType))
                                            .frame(width: 14, height: 14)
                                            .overlay(
                                                Circle()
                                                    .stroke(AuraColors.background, lineWidth: 3)
                                            )
                                        
                                        if index != sortedEvents.count - 1 {
                                            Rectangle()
                                                .fill(AuraColors.tertiaryBackground)
                                                .frame(width: 2)
                                        }
                                    }
                                    
                                    // Event Content
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack(alignment: .firstTextBaseline) {
                                            Text(titleForEvent(event.eventType))
                                                .font(AuraTypography.headline)
                                                .foregroundColor(AuraColors.textPrimary)
                                            Spacer()
                                            Text(event.timestamp.formatted(date: .omitted, time: .shortened))
                                                .font(AuraTypography.caption)
                                                .foregroundColor(AuraColors.textTertiary)
                                        }
                                        
                                        if !event.details.isEmpty {
                                            Text(event.details)
                                                .font(AuraTypography.subheadline)
                                                .foregroundColor(AuraColors.textSecondary)
                                        }
                                        
                                        // Contextual Date headers for day boundaries
                                        if index == 0 || !Calendar.current.isDate(sortedEvents[index].timestamp, inSameDayAs: sortedEvents[index-1].timestamp) {
                                            Text(event.timestamp.formatted(date: .abbreviated, time: .omitted))
                                                .font(AuraTypography.stats)
                                                .foregroundColor(AuraColors.accent)
                                                .padding(.top, 4)
                                        }
                                    }
                                    .padding(.bottom, AuraLayout.spacingLarge)
                                }
                            }
                        }
                    }
                    .padding(AuraLayout.screenPadding)
                }
            }
            .navigationTitle("Task Journey")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(AuraTypography.headline)
                        .foregroundColor(AuraColors.accent)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    private var journeySummary: some View {
        HStack {
            journeyStat(title: "Lifetime", value: lifetimeString)
            Divider().frame(height: 40)
            journeyStat(title: "Focus Time", value: formatDuration(totalFocusTime))
            Divider().frame(height: 40)
            journeyStat(title: "Reschedules", value: "\(rescheduleCount)")
        }
        .padding(AuraLayout.spacingMedium)
        .frame(maxWidth: .infinity)
        .background(AuraColors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: AuraLayout.cornerRadiusMedium))
    }
    
    private func journeyStat(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(AuraTypography.title2)
                .foregroundColor(AuraColors.textPrimary)
            Text(title)
                .font(AuraTypography.caption)
                .foregroundColor(AuraColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var lifetimeString: String {
        let created = task.createdAt
        let end = task.isCompleted ? (sortedEvents.last(where: { $0.eventType == .completed })?.timestamp ?? Date()) : Date()
        let days = Calendar.current.dateComponents([.day], from: created, to: end).day ?? 0
        return "\(days)d"
    }
    
    private var rescheduleCount: Int {
        sortedEvents.filter { $0.eventType == .rescheduled || $0.eventType == .dueDateChanged }.count
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        guard duration > 0 else { return "0m" }
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? "0m"
    }
    
    private func colorForEvent(_ type: TaskHistory.EventType) -> Color {
        switch type {
        case .created: return AuraColors.projectBlue
        case .completed, .subtaskCompleted: return AuraColors.success
        case .snoozed, .rescheduled, .dueDateChanged: return AuraColors.warning
        case .focusSessionStarted, .started: return AuraColors.projectPurple
        case .focusSessionCompleted: return AuraColors.projectGreen
        case .priorityChanged: return AuraColors.destructive
        default: return AuraColors.textSecondary
        }
    }
    
    private func titleForEvent(_ type: TaskHistory.EventType) -> String {
        switch type {
        case .created: return "Captured"
        case .started: return "Started"
        case .paused: return "Paused"
        case .completed: return "Completed"
        case .reopened: return "Reopened"
        case .snoozed: return "Snoozed"
        case .rescheduled: return "Rescheduled"
        case .priorityChanged: return "Priority Changed"
        case .progressChanged: return "Progress Updated"
        case .dueDateChanged: return "Due Date Changed"
        case .reminderCreated: return "Reminder Scheduled"
        case .reminderTriggered: return "Reminder Alert"
        case .reminderDismissed: return "Reminder Dismissed"
        case .focusSessionStarted: return "Deep Work Started"
        case .focusSessionCompleted: return "Deep Work Ended"
        case .subtaskCompleted: return "Subtask Done"
        case .projectChanged: return "Moved Project"
        }
    }
}
