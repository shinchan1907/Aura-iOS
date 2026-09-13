import SwiftUI
import SwiftData

public struct TaskRowView: View {
    let task: TaskItem
    
    public init(task: TaskItem) {
        self.task = task
    }
    
    public var body: some View {
        HStack(alignment: .top, spacing: AuraLayout.spacingMedium) {
            // Status Indicator
            Circle()
                .stroke(colorForStatus(task.status), lineWidth: 2)
                .background(task.isCompleted ? colorForStatus(task.status) : Color.clear)
                .frame(width: 20, height: 20)
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 4) {
                // Title
                Text(task.title)
                    .font(AuraTypography.headline)
                    .foregroundColor(task.isCompleted ? AuraColors.textSecondary : AuraColors.textPrimary)
                    .strikethrough(task.isCompleted)
                
                // Metadata Row
                HStack(spacing: AuraLayout.spacingMedium) {
                    if let project = task.project {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color(hex: project.colorHex) ?? AuraColors.accent)
                                .frame(width: 8, height: 8)
                            Text(project.title)
                                .font(AuraTypography.caption)
                                .foregroundColor(AuraColors.textSecondary)
                        }
                    }
                    
                    if let dueDate = task.dueDate {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                            Text(dueDate.formatted(date: .abbreviated, time: .shortened))
                        }
                        .font(AuraTypography.caption)
                        .foregroundColor(AuraColors.accent)
                    }
                }
            }
            Spacer()
        }
        .padding(AuraLayout.spacingMedium)
        .background(AuraColors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: AuraLayout.cornerRadiusMedium, style: .continuous))
    }
    
    private func colorForStatus(_ status: TaskItem.Status) -> Color {
        switch status {
        case .todo: return AuraColors.textSecondary
        case .inProgress: return AuraColors.warning
        case .completed: return AuraColors.success
        }
    }
}
