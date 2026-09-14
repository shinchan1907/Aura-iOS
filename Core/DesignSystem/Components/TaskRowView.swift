import SwiftUI
import SwiftData

public struct TaskRowView: View {
    let task: TaskItem
    
    public init(task: TaskItem) {
        self.task = task
    }
    
    public var body: some View {
        HStack(alignment: .center, spacing: AuraLayout.spacingMedium) {
            // Status Indicator Indicator
            Circle()
                .stroke(colorForStatus(task.status), lineWidth: 2)
                .background(task.isCompleted ? colorForStatus(task.status) : Color.clear)
                .frame(width: 22, height: 22)
            
            VStack(alignment: .leading, spacing: 4) {
                // Title
                Text(task.title)
                    .font(AuraTypography.headline)
                    .foregroundColor(task.isCompleted ? AuraColors.textSecondary : AuraColors.textPrimary)
                    .strikethrough(task.isCompleted)
                
                // Metadata Row
                HStack(spacing: AuraLayout.spacingSmall) {
                    if task.priority == .urgent {
                        Text("URGENT")
                            .font(AuraTypography.stats)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(AuraColors.urgent.opacity(0.2))
                            .foregroundColor(AuraColors.urgent)
                            .clipShape(Capsule())
                    }
                    
                    if let project = task.project {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color(hex: project.colorHex) ?? AuraColors.accent)
                                .frame(width: 6, height: 6)
                            Text(project.title)
                                .font(AuraTypography.caption)
                                .foregroundColor(AuraColors.textSecondary)
                        }
                    } else {
                        Text("Standalone")
                            .font(AuraTypography.caption)
                            .foregroundColor(AuraColors.textSecondary)
                    }
                    
                    if let dueDate = task.dueDate {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                            Text(dueDate.formatted(date: .abbreviated, time: .shortened))
                        }
                        .font(AuraTypography.caption)
                        .foregroundColor(dueDate < Date() && !task.isCompleted ? AuraColors.destructive : AuraColors.accent)
                    }
                    
                    if task.followUpDate != nil {
                        Image(systemName: "bell.fill")
                            .font(AuraTypography.caption)
                            .foregroundColor(AuraColors.warning)
                    }
                }
            }
            Spacer()
        }
        .glassCard(padding: 12, borderColor: task.priority == .urgent ? AuraColors.urgent.opacity(0.4) : AuraColors.glassBorder)
    }
    
    private func colorForStatus(_ status: TaskItem.Status) -> Color {
        switch status {
        case .todo: return AuraColors.textSecondary
        case .inProgress: return AuraColors.warning
        case .completed: return AuraColors.success
        case .archived: return AuraColors.projectPurple
        }
    }
}
