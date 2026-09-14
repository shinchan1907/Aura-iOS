import SwiftUI
import SwiftData

public struct TaskRowView: View {
    let task: TaskItem
    var onToggle: (() -> Void)? = nil
    
    @State private var isPressed = false
    
    public init(task: TaskItem, onToggle: (() -> Void)? = nil) {
        self.task = task
        self.onToggle = onToggle
    }
    
    public var body: some View {
        HStack(alignment: .center, spacing: AuraLayout.spacingMedium) {
            // Interactive Checkmark Icon with Spring Animation
            Button(action: {
                AuraHaptics.taskCompletion()
                onToggle?()
            }) {
                ZStack {
                    Circle()
                        .stroke(colorForStatus(task.status), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if task.isCompleted {
                        Circle()
                            .fill(AuraColors.success)
                            .frame(width: 24, height: 24)
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 4) {
                // Title
                Text(task.title)
                    .font(AuraTypography.headline)
                    .foregroundColor(task.isCompleted ? AuraColors.textSecondary : AuraColors.textPrimary)
                    .strikethrough(task.isCompleted, color: AuraColors.textSecondary.opacity(0.6))
                    .animation(.easeInOut(duration: 0.2), value: task.isCompleted)
                
                // Badges & Metadata Pill Row
                HStack(spacing: AuraLayout.spacingSmall) {
                    // Priority Pill
                    if task.priority == .urgent {
                        Text("URGENT")
                            .font(AuraTypography.stats)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AuraColors.urgent.opacity(0.2))
                            .foregroundColor(AuraColors.urgent)
                            .clipShape(Capsule())
                    } else if task.priority == .high {
                        Text("HIGH")
                            .font(AuraTypography.stats)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AuraColors.warning.opacity(0.18))
                            .foregroundColor(AuraColors.warning)
                            .clipShape(Capsule())
                    }
                    
                    // Project Badge
                    if let project = task.project {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color(hex: project.colorHex) ?? AuraColors.accent)
                                .frame(width: 6, height: 6)
                            Text(project.title)
                                .font(AuraTypography.caption)
                                .foregroundColor(AuraColors.textSecondary)
                        }
                    }
                    
                    // Due Date Badge
                    if let dueDate = task.dueDate {
                        let isOverdue = dueDate < Date() && !task.isCompleted
                        HStack(spacing: 4) {
                            Image(systemName: isOverdue ? "exclamationmark.clock.fill" : "calendar")
                            Text(dueDate.formatted(date: .abbreviated, time: .shortened))
                        }
                        .font(AuraTypography.caption)
                        .foregroundColor(isOverdue ? AuraColors.destructive : AuraColors.accent)
                    }
                    
                    // Subtask Progress Pill
                    if !task.subtasks.isEmpty {
                        let completedCount = task.subtasks.filter { $0.isCompleted }.count
                        HStack(spacing: 3) {
                            Image(systemName: "checklist")
                            Text("\(completedCount)/\(task.subtasks.count)")
                        }
                        .font(AuraTypography.stats)
                        .foregroundColor(AuraColors.textSecondary)
                    }
                    
                    // Alarm Icon
                    if task.followUpDate != nil {
                        Image(systemName: "bell.fill")
                            .font(AuraTypography.caption)
                            .foregroundColor(AuraColors.warning)
                    }
                }
            }
            Spacer()
            
            // Chevron indicator for navigation detail
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AuraColors.textTertiary)
        }
        .glassCard(
            padding: 14,
            borderColor: task.priority == .urgent ? AuraColors.urgent.opacity(0.5) : (task.priority == .high ? AuraColors.warning.opacity(0.35) : AuraColors.glassBorder),
            glowColor: task.priority == .urgent ? AuraColors.urgent : Color.clear
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isPressed)
    }
    
    private func colorForStatus(_ status: TaskItem.Status) -> Color {
        switch status {
        case .todo: return AuraColors.textSecondary.opacity(0.6)
        case .inProgress: return AuraColors.warning
        case .completed: return AuraColors.success
        case .archived: return AuraColors.projectPurple
        }
    }
}
