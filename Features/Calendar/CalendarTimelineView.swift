import SwiftUI
import SwiftData

public struct CalendarTimelineView: View {
    @Query(sort: \TaskItem.dueDate) private var tasks: [TaskItem]
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AuraColors.background.ignoresSafeArea()
                
                VStack(spacing: AuraLayout.spacingMedium) {
                    // Simple Calendar Header Placeholder
                    HStack {
                        ForEach(0..<7) { dayOffset in
                            VStack {
                                Text("Day \(dayOffset + 1)")
                                    .font(AuraTypography.caption)
                                    .foregroundColor(dayOffset == 0 ? AuraColors.accent : AuraColors.textSecondary)
                                Circle()
                                    .fill(dayOffset == 0 ? AuraColors.accent : Color.clear)
                                    .frame(width: 8, height: 8)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding()
                    .background(AuraColors.secondaryBackground)
                    
                    if tasks.filter({ $0.dueDate != nil }).isEmpty {
                        Spacer()
                        VStack(spacing: AuraLayout.spacingMedium) {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .font(.system(size: 48))
                                .foregroundColor(AuraColors.accent.opacity(0.5))
                            Text("No Scheduled Tasks")
                                .font(AuraTypography.title2)
                                .foregroundColor(AuraColors.textPrimary)
                        }
                        Spacer()
                    } else {
                        List {
                            ForEach(tasks.filter { $0.dueDate != nil }) { task in
                                TaskRowView(task: task)
                                    .listRowInsets(EdgeInsets())
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .padding(.horizontal)
                                    .padding(.vertical, AuraLayout.spacingTight)
                            }
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .navigationTitle("Timeline")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
