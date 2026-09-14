import SwiftUI
import SwiftData

public struct TaskDetailView: View {
    @Bindable var task: TaskItem
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var isShowingHistory = false
    @State private var isAdvancedExpanded = false
    @State private var newSubtaskTitle = ""
    @State private var showingFollowUpPicker = false
    @State private var followUpDate = Date()
    
    public init(task: TaskItem) {
        self.task = task
    }
    
    public var body: some View {
        ZStack {
            AuraColors.background.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: AuraLayout.spacingLarge) {
                    
                    // Header & Title
                    HStack(alignment: .top, spacing: AuraLayout.spacingMedium) {
                        Button(action: toggleCompletion) {
                            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 32))
                                .foregroundColor(task.isCompleted ? AuraColors.success : AuraColors.textSecondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            TextField("Task Title", text: $task.title, axis: .vertical)
                                .font(AuraTypography.title1)
                                .foregroundColor(task.isCompleted ? AuraColors.textSecondary : AuraColors.textPrimary)
                                .strikethrough(task.isCompleted)
                        }
                    }
                    
                    // Metadata & Badges Row
                    HStack(spacing: AuraLayout.spacingSmall) {
                        // Priority Badge
                        Menu {
                            ForEach(TaskItem.Priority.allCases, id: \.self) { p in
                                Button(p.label) {
                                    task.priority = p
                                    AuraHaptics.selection()
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "flag.fill")
                                Text(task.priority.label)
                            }
                            .font(AuraTypography.caption.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(priorityColor.opacity(0.18))
                            .foregroundColor(priorityColor)
                            .clipShape(Capsule())
                        }
                        
                        if let project = task.project {
                            Label(project.title, systemImage: "folder.fill")
                                .font(AuraTypography.caption)
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(Color(hex: project.colorHex)?.opacity(0.15) ?? AuraColors.accent.opacity(0.15))
                                .foregroundColor(Color(hex: project.colorHex) ?? AuraColors.accent)
                                .clipShape(Capsule())
                        }
                        
                        if task.isArchived {
                            Label("Archived", systemImage: "archivebox.fill")
                                .font(AuraTypography.caption)
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(AuraColors.projectPurple.opacity(0.15))
                                .foregroundColor(AuraColors.projectPurple)
                                .clipShape(Capsule())
                        }
                    }
                    
                    // Notes Section
                    VStack(alignment: .leading, spacing: AuraLayout.spacingSmall) {
                        Text("Notes")
                            .font(AuraTypography.subheadline.bold())
                            .foregroundColor(AuraColors.textSecondary)
                        TextField("Add detailed notes here...", text: $task.notes, axis: .vertical)
                            .font(AuraTypography.body)
                            .lineLimit(4...8)
                    }
                    .glassCard()
                    
                    // Subtasks Section
                    subtasksSection
                    
                    // Follow-Up & Reminder Section
                    followUpSection
                    
                    // Progressive Disclosure for Advanced Settings
                    DisclosureGroup(
                        isExpanded: $isAdvancedExpanded,
                        content: {
                            VStack(spacing: AuraLayout.spacingMedium) {
                                advancedRow(icon: "clock", title: "Estimated Time", value: formatDuration(task.estimatedDuration), color: .secondary)
                                advancedRow(icon: "repeat", title: "Recurrence", value: task.recurrenceRuleRaw ?? "None", color: .secondary)
                                if let created = task.createdAt as Date? {
                                    advancedRow(icon: "calendar", title: "Created On", value: created.formatted(date: .abbreviated, time: .shortened), color: .secondary)
                                }
                            }
                            .padding(.top, AuraLayout.spacingSmall)
                        },
                        label: {
                            Text("Advanced Details")
                                .font(AuraTypography.headline)
                                .foregroundColor(AuraColors.textSecondary)
                        }
                    )
                    .glassCard()
                    
                    // Primary Actions
                    VStack(spacing: AuraLayout.spacingMedium) {
                        Button(action: startFocusSession) {
                            HStack {
                                Image(systemName: "bolt.fill")
                                Text(task.status == .inProgress ? "Focusing..." : "Start Focus Session")
                            }
                        }
                        .buttonStyle(.auraPrimary)
                        .disabled(task.status == .inProgress)
                        
                        HStack(spacing: AuraLayout.spacingMedium) {
                            Button(action: toggleArchive) {
                                Label(task.isArchived ? "Unarchive" : "Archive", systemImage: task.isArchived ? "tray.and.arrow.up" : "archivebox")
                            }
                            .buttonStyle(.auraSecondary)
                            
                            Button(action: { isShowingHistory = true }) {
                                Label("Journey", systemImage: "map.fill")
                            }
                            .buttonStyle(.auraSecondary)
                        }
                    }
                }
                .padding(AuraLayout.screenPadding)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive, action: deleteTask) {
                    Image(systemName: "trash")
                        .foregroundColor(AuraColors.destructive)
                }
            }
        }
        .sheet(isPresented: $isShowingHistory) {
            TaskHistoryTimelineView(task: task)
        }
    }
    
    // MARK: - Subtasks Section
    private var subtasksSection: some View {
        VStack(alignment: .leading, spacing: AuraLayout.spacingMedium) {
            HStack {
                Text("Subtasks (\(task.subtasks.count))")
                    .font(AuraTypography.headline)
                    .foregroundColor(AuraColors.textPrimary)
                Spacer()
                Text("\(Int(task.derivedProgress * 100))%")
                    .font(AuraTypography.stats)
                    .foregroundColor(AuraColors.accent)
            }
            
            ForEach(task.subtasks) { subtask in
                HStack {
                    Button(action: {
                        withAnimation {
                            subtask.status = subtask.isCompleted ? .todo : .completed
                            subtask.progress = subtask.isCompleted ? 1.0 : 0.0
                        }
                        AuraHaptics.taskCompletion()
                    }) {
                        Image(systemName: subtask.isCompleted ? "checkmark.square.fill" : "square")
                            .font(.title3)
                            .foregroundColor(subtask.isCompleted ? AuraColors.success : AuraColors.textSecondary)
                    }
                    
                    Text(subtask.title)
                        .font(AuraTypography.body)
                        .foregroundColor(subtask.isCompleted ? AuraColors.textSecondary : AuraColors.textPrimary)
                        .strikethrough(subtask.isCompleted)
                    Spacer()
                }
            }
            
            HStack {
                TextField("Add subtask...", text: $newSubtaskTitle)
                    .font(AuraTypography.subheadline)
                    .onSubmit(addSubtask)
                
                if !newSubtaskTitle.isEmpty {
                    Button(action: addSubtask) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(AuraColors.accent)
                    }
                }
            }
        }
        .glassCard()
    }
    
    // MARK: - Follow-Up Section
    private var followUpSection: some View {
        VStack(alignment: .leading, spacing: AuraLayout.spacingSmall) {
            HStack {
                Image(systemName: "bell.badge.fill")
                    .foregroundColor(AuraColors.warning)
                Text("Follow-Up Alarm")
                    .font(AuraTypography.headline)
                    .foregroundColor(AuraColors.textPrimary)
                Spacer()
                
                if task.followUpDate != nil {
                    Button("Clear") {
                        task.followUpDate = nil
                        task.isAlarmActive = false
                        NotificationManager.shared.removeReminders(for: task)
                    }
                    .font(AuraTypography.caption)
                    .foregroundColor(AuraColors.destructive)
                }
            }
            
            if let followUp = task.followUpDate {
                HStack {
                    Text("Scheduled for \(followUp.formatted(date: .abbreviated, time: .shortened))")
                        .font(AuraTypography.subheadline)
                        .foregroundColor(AuraColors.textSecondary)
                    Spacer()
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(AuraColors.success)
                }
            } else {
                DatePicker("Schedule Follow-Up", selection: $followUpDate, in: Date()...)
                    .font(AuraTypography.subheadline)
                    .onChange(of: followUpDate) { _, newDate in
                        task.followUpDate = newDate
                        task.isAlarmActive = true
                        NotificationManager.shared.scheduleFollowUpAlarm(for: task, at: newDate)
                        AuraHaptics.success()
                    }
            }
        }
        .glassCard()
    }
    
    private func addSubtask() {
        let trimmed = newSubtaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let sub = TaskItem(title: trimmed, parentTask: task)
        modelContext.insert(sub)
        newSubtaskTitle = ""
        AuraHaptics.success()
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
        case .low: return AuraColors.success
        case .medium: return AuraColors.warning
        case .high: return AuraColors.destructive
        case .urgent: return AuraColors.urgent
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
    
    private func toggleArchive() {
        withAnimation {
            task.isArchived.toggle()
            if task.isArchived {
                task.status = .archived
            } else {
                task.status = .todo
            }
            AuraHaptics.warning()
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
        FocusActivityManager.shared.startFocusActivity(taskTitle: task.title, estimatedSeconds: Int(task.estimatedDuration ?? 1500))
    }
    
    private func deleteTask() {
        withAnimation {
            modelContext.delete(task)
            AuraHaptics.error()
            dismiss()
        }
    }
}
