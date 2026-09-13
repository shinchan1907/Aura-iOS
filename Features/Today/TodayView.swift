import SwiftUI
import SwiftData

public struct TodayView: View {
    @Query(filter: #Predicate<TaskItem> { task in
        task.statusRaw != 2 // 2 is completed
    }, sort: \TaskItem.dueDate) 
    private var allIncompleteTasks: [TaskItem]
    
    @Query(filter: #Predicate<TaskItem> { task in
        task.statusRaw == 2
    }) 
    private var allCompletedTasks: [TaskItem]
    
    @Environment(\.modelContext) private var modelContext
    @State private var showingCreateTask = false
    
    public init() {}
    
    private var focusNowTask: TaskItem? {
        // Simple heuristic: InProgress > Highest Priority > Nearest Due Date
        allIncompleteTasks.sorted { (t1, t2) in
            if t1.status == .inProgress && t2.status != .inProgress { return true }
            if t2.status == .inProgress && t1.status != .inProgress { return false }
            if t1.priorityRaw > t2.priorityRaw { return true }
            if t1.priorityRaw < t2.priorityRaw { return false }
            return (t1.dueDate ?? Date.distantFuture) < (t2.dueDate ?? Date.distantFuture)
        }.first
    }
    
    private var todayProgress: Double {
        let total = allIncompleteTasks.count + allCompletedTasks.count
        guard total > 0 else { return 0 }
        return Double(allCompletedTasks.count) / Double(total)
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AuraColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: AuraLayout.spacingLarge) {
                        headerSection
                        
                        if let focusTask = focusNowTask {
                            focusNowSection(task: focusTask)
                        }
                        
                        tasksListSection
                    }
                    .padding(AuraLayout.screenPadding)
                }
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingCreateTask = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(AuraColors.accent)
                    }
                }
            }
            .sheet(isPresented: $showingCreateTask) {
                // In a real app, this would be a full task creation sheet
                Text("Quick Capture Sheet")
                    .presentationDetents([.medium])
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AuraLayout.spacingTight) {
            Text(Date.now.formatted(date: .complete, time: .omitted))
                .font(AuraTypography.subheadline)
                .foregroundColor(AuraColors.textSecondary)
                .textCase(.uppercase)
            
            Text("Good Morning,")
                .font(AuraTypography.heroTitle)
                .foregroundColor(AuraColors.textPrimary)
            
            HStack {
                Text("You have \(allIncompleteTasks.count) tasks left.")
                    .font(AuraTypography.title2)
                    .foregroundColor(AuraColors.textSecondary)
                
                Spacer()
                
                // Minimal circular progress
                ZStack {
                    Circle()
                        .stroke(AuraColors.accent.opacity(0.2), lineWidth: 4)
                    Circle()
                        .trim(from: 0, to: todayProgress)
                        .stroke(AuraColors.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: todayProgress)
                }
                .frame(width: 24, height: 24)
            }
        }
        .padding(.top, AuraLayout.spacingMedium)
    }
    
    private func focusNowSection(task: TaskItem) -> some View {
        VStack(alignment: .leading, spacing: AuraLayout.spacingMedium) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(AuraColors.warning)
                Text("Focus Now")
                    .font(AuraTypography.headline)
                    .foregroundColor(AuraColors.textSecondary)
            }
            
            NavigationLink(destination: TaskDetailView(task: task)) {
                VStack(alignment: .leading, spacing: AuraLayout.spacingMedium) {
                    Text(task.title)
                        .font(AuraTypography.title2)
                        .foregroundColor(AuraColors.textPrimary)
                        .multilineTextAlignment(.leading)
                    
                    HStack {
                        if let project = task.project {
                            Label(project.title, systemImage: "folder.fill")
                                .font(AuraTypography.caption)
                                .foregroundColor(Color(hex: project.colorHex) ?? AuraColors.accent)
                        }
                        Spacer()
                        Button(action: { startFocus(for: task) }) {
                            Text("Start Session")
                                .font(AuraTypography.subheadline.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(AuraColors.accent))
                        }
                    }
                }
                .auraCard(backgroundColor: AuraColors.accent.opacity(0.05))
            }
            .buttonStyle(.plain)
        }
    }
    
    private var tasksListSection: some View {
        VStack(alignment: .leading, spacing: AuraLayout.spacingMedium) {
            Text("Up Next")
                .font(AuraTypography.title2)
                .foregroundColor(AuraColors.textPrimary)
            
            let upNextTasks = allIncompleteTasks.filter { $0.id != focusNowTask?.id }
            
            if upNextTasks.isEmpty && focusNowTask == nil {
                emptyState
            } else {
                ForEach(upNextTasks) { task in
                    NavigationLink(destination: TaskDetailView(task: task)) {
                        TaskRowView(task: task)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            deleteTask(task)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: AuraLayout.spacingMedium) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundColor(AuraColors.accent.opacity(0.5))
            Text("Your day is clear.")
                .font(AuraTypography.headline)
                .foregroundColor(AuraColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AuraLayout.spacingXLarge)
    }
    
    private func startFocus(for task: TaskItem) {
        AuraHaptics.impact(style: .heavy)
        withAnimation {
            task.status = .inProgress
            let session = FocusSession(startTime: Date(), task: task)
            modelContext.insert(session)
            
            let event = TaskHistory(eventType: .focusSessionStarted, details: "Started from Command Center", task: task)
            modelContext.insert(event)
        }
    }
    
    private func deleteTask(_ task: TaskItem) {
        withAnimation {
            modelContext.delete(task)
            AuraHaptics.error()
        }
    }
}
