import SwiftUI
import SwiftData

public struct TaskDetailView: View {
    @Bindable var task: TaskItem
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var isShowingHistory = false
    @State private var isAdvancedExpanded = false
    
    public init(task: TaskItem) {
        self.task = task
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AuraLayout.spacingLarge) {
                
                // Header
                HStack(alignment: .top) {
                    Button(action: toggleCompletion) {
                        Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 28))
                            .foregroundColor(task.isCompleted ? AuraColors.success : AuraColors.textSecondary)
                    }
                    
                    TextField("Task Title", text: $task.title, axis: .vertical)
                        .font(AuraTypography.title1)
                        .foregroundColor(task.isCompleted ? AuraColors.textSecondary : AuraColors.textPrimary)
                        .strikethrough(task.isCompleted)
                }
                
                // Quick Metadata
                HStack(spacing: AuraLayout.spacingMedium) {
                    if let project = task.project {
                        Label(project.title, systemImage: "folder.fill")
                            .font(AuraTypography.subheadline)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(Color(hex: project.colorHex)?.opacity(0.1) ?? AuraColors.accent.opacity(0.1))
                            .foregroundColor(Color(hex: project.colorHex) ?? AuraColors.accent)
                            .clipShape(Capsule())
                    }
                    
                    if let due = task.dueDate {
                        Label(due.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                            .font(AuraTypography.subheadline)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(AuraColors.tertiaryBackground)
                            .foregroundColor(due < Date() ? AuraColors.destructive : AuraColors.textSecondary)
                            .clipShape(Capsule())
                    }
                }
                
                // Notes Section
                VStack(alignment: .leading, spacing: AuraLayout.spacingSmall) {
                    TextField("Add detailed notes here...", text: $task.notes, axis: .vertical)
                        .font(AuraTypography.body)
                        .lineLimit(5...10)
                        .padding()
                        .background(AuraColors.secondaryBackground)
                        .clipShape(RoundedRectangle(cornerRadius: AuraLayout.cornerRadiusSmall))
                }
                
                // Progressive Disclosure for Advanced Settings
                DisclosureGroup(
                    isExpanded: $isAdvancedExpanded,
                    content: {
                        VStack(spacing: AuraLayout.spacingMedium) {
                            advancedRow(icon: "flag.fill", title: "Priority", value: String(describing: task.priority), color: priorityColor)
                            advancedRow(icon: "clock", title: "Estimated", value: formatDuration(task.estimatedDuration), color: .secondary)
                            advancedRow(icon: "repeat", title: "Recurrence", value: task.recurrenceRuleRaw ?? "None", color: .secondary)
                        }
                        .padding(.top, AuraLayout.spacingSmall)
                    },
                    label: {
                        Text("Advanced Details")
                            .font(AuraTypography.headline)
                            .foregroundColor(AuraColors.textSecondary)
                    }
                )
                .padding()
                .background(AuraColors.tertiaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: AuraLayout.cornerRadiusSmall))
                
                // Actions
                VStack(spacing: AuraLayout.spacingMedium) {
                    Button(action: startFocusSession) {
                        Label(task.status == .inProgress ? "Focusing..." : "Start Focus Session", systemImage: "bolt.fill")
                    }
                    .buttonStyle(.auraPrimary)
                    .disabled(task.status == .inProgress)
                    
                    Button(action: { isShowingHistory = true }) {
                        Label("View Task Journey", systemImage: "map.fill")
                    }
                    .buttonStyle(.auraSecondary)
                }
            }
            .padding(AuraLayout.screenPadding)
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isShowingHistory) {
            TaskHistoryTimelineView(task: task)
        }
    }
    
    private func advancedRow(icon: String, title: String, value: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            Text(title)
                .foregroundColor(AuraColors.textPrimary)
            Spacer()
            Text(value)
                .foregroundColor(AuraColors.textSecondary)
        }
        .font(AuraTypography.body)
    }
    
    private var priorityColor: Color {
        switch task.priority {
        case .high: return AuraColors.destructive
        case .medium: return AuraColors.warning
        case .low: return AuraColors.success
        }
    }
    
    private func formatDuration(_ duration: TimeInterval?) -> String {
        guard let duration = duration, duration > 0 else { return "None" }
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? "None"
    }
    
    private func toggleCompletion() {
        AuraHaptics.taskCompletion()
        withAnimation {
            task.status = task.isCompleted ? .todo : .completed
            
            let event = TaskHistory(
                eventType: task.isCompleted ? .completed : .reopened,
                details: "Task marked as \(task.isCompleted ? "completed" : "todo")",
                task: task
            )
            modelContext.insert(event)
        }
    }
    
    private func startFocusSession() {
        AuraHaptics.impact(style: .heavy)
        withAnimation {
            task.status = .inProgress
            let session = FocusSession(startTime: Date(), task: task)
            modelContext.insert(session)
            
            let event = TaskHistory(eventType: .focusSessionStarted, details: "Focus session started", task: task)
            modelContext.insert(event)
        }
    }
}
