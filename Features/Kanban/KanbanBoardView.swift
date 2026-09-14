import SwiftUI
import SwiftData

public struct KanbanBoardView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \TaskItem.createdAt, order: .reverse)
    private var allTasks: [TaskItem]
    
    @Query(sort: \Project.createdAt)
    private var allProjects: [Project]
    
    @State private var selectedFilter: TaskFilter = .all
    @State private var searchText = ""
    @State private var showingCreateTask = false
    @State private var initialStatusForNewTask: TaskItem.Status = .todo
    
    enum TaskFilter: Hashable {
        case all
        case standalone
        case project(Project)
        
        var title: String {
            switch self {
            case .all: return "All Tasks"
            case .standalone: return "Standalone"
            case .project(let p): return p.title
            }
        }
    }
    
    public init() {}
    
    private var filteredTasks: [TaskItem] {
        allTasks.filter { task in
            let matchesFilter: Bool
            switch selectedFilter {
            case .all:
                matchesFilter = true
            case .standalone:
                matchesFilter = task.project == nil
            case .project(let targetProject):
                matchesFilter = task.project?.id == targetProject.id
            }
            
            if searchText.isEmpty {
                return matchesFilter
            } else {
                return matchesFilter && (task.title.localizedCaseInsensitiveContains(searchText) || task.notes.localizedCaseInsensitiveContains(searchText))
            }
        }
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AuraColors.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Filter & Search Header
                    filterHeader
                    
                    // Horizontal Scrollable Kanban Columns
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing: AuraLayout.spacingMedium) {
                            kanbanColumn(status: .todo, title: "Todo", icon: "circle", color: AuraColors.textSecondary)
                            kanbanColumn(status: .inProgress, title: "In Progress", icon: "bolt.fill", color: AuraColors.warning)
                            kanbanColumn(status: .completed, title: "Completed", icon: "checkmark.circle.fill", color: AuraColors.success)
                            kanbanColumn(status: .archived, title: "Archived", icon: "archivebox.fill", color: AuraColors.projectPurple)
                        }
                        .padding(AuraLayout.screenPadding)
                    }
                }
            }
            .navigationTitle("Kanban Board")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingCreateTask) {
                QuickKanbanTaskSheet(isPresented: $showingCreateTask, defaultStatus: initialStatusForNewTask, projects: allProjects)
            }
        }
    }
    
    // MARK: - Filter Header View
    private var filterHeader: some View {
        VStack(spacing: AuraLayout.spacingSmall) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AuraLayout.spacingSmall) {
                    filterChip(title: "All", filter: .all)
                    filterChip(title: "Standalone", filter: .standalone)
                    
                    ForEach(allProjects) { project in
                        filterChip(title: project.title, filter: .project(project), colorHex: project.colorHex)
                    }
                }
                .padding(.horizontal, AuraLayout.screenPadding)
            }
            
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AuraColors.textSecondary)
                TextField("Search board...", text: $searchText)
                    .font(AuraTypography.body)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(AuraColors.glassSurface)
            .clipShape(RoundedRectangle(cornerRadius: AuraLayout.cornerRadiusSmall))
            .padding(.horizontal, AuraLayout.screenPadding)
        }
        .padding(.vertical, AuraLayout.spacingSmall)
    }
    
    private func filterChip(title: String, filter: TaskFilter, colorHex: String? = nil) -> some View {
        let isSelected = selectedFilter == filter
        let color = colorHex != nil ? (Color(hex: colorHex!) ?? AuraColors.accent) : AuraColors.accent
        
        return Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedFilter = filter
                AuraHaptics.selection()
            }
        }) {
            Text(title)
                .font(AuraTypography.subheadline.weight(isSelected ? .bold : .regular))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(isSelected ? color.opacity(0.2) : AuraColors.glassSurface)
                .foregroundColor(isSelected ? color : AuraColors.textSecondary)
                .overlay(
                    Capsule()
                        .stroke(isSelected ? color : AuraColors.glassBorder, lineWidth: 1)
                )
                .clipShape(Capsule())
        }
    }
    
    // MARK: - Kanban Column View
    private func kanbanColumn(status: TaskItem.Status, title: String, icon: String, color: Color) -> some View {
        let tasksForColumn = filteredTasks.filter { task in
            if status == .archived {
                return task.isArchived || task.status == .archived
            } else {
                return !task.isArchived && task.status == status
            }
        }
        
        return VStack(alignment: .leading, spacing: AuraLayout.spacingMedium) {
            // Column Header
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(AuraTypography.headline)
                    .foregroundColor(AuraColors.textPrimary)
                Spacer()
                Text("\(tasksForColumn.count)")
                    .font(AuraTypography.stats)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(color.opacity(0.15))
                    .foregroundColor(color)
                    .clipShape(Capsule())
            }
            .padding(.bottom, AuraLayout.spacingTight)
            
            // Task List
            ScrollView {
                VStack(spacing: AuraLayout.spacingSmall) {
                    ForEach(tasksForColumn) { task in
                        kanbanCardView(task: task)
                    }
                    
                    // Add Task Button
                    Button(action: {
                        initialStatusForNewTask = status
                        showingCreateTask = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Task")
                                .font(AuraTypography.subheadline.bold())
                        }
                        .foregroundColor(color)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(color.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: AuraLayout.cornerRadiusSmall))
                        .overlay(
                            RoundedRectangle(cornerRadius: AuraLayout.cornerRadiusSmall)
                                .stroke(color.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [4]))
                        )
                    }
                }
            }
        }
        .frame(width: 280)
        .glassCard(padding: 14)
    }
    
    // MARK: - Kanban Card View
    private func kanbanCardView(task: TaskItem) -> some View {
        NavigationLink(destination: TaskDetailView(task: task)) {
            VStack(alignment: .leading, spacing: AuraLayout.spacingSmall) {
                // Priority & Project Header Row
                HStack {
                    priorityBadge(task.priority)
                    
                    if let project = task.project {
                        Text(project.title)
                            .font(AuraTypography.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(hex: project.colorHex)?.opacity(0.15) ?? AuraColors.accent.opacity(0.15))
                            .foregroundColor(Color(hex: project.colorHex) ?? AuraColors.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    } else {
                        Text("Standalone")
                            .font(AuraTypography.caption)
                            .foregroundColor(AuraColors.textSecondary)
                    }
                    Spacer()
                }
                
                Text(task.title)
                    .font(AuraTypography.headline)
                    .foregroundColor(AuraColors.textPrimary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                
                if !task.notes.isEmpty {
                    Text(task.notes)
                        .font(AuraTypography.caption)
                        .foregroundColor(AuraColors.textSecondary)
                        .lineLimit(2)
                }
                
                // Metadata & Navigation Control Footer Row
                HStack {
                    if let dueDate = task.dueDate {
                        HStack(spacing: 2) {
                            Image(systemName: "calendar")
                            Text(dueDate.formatted(date: .abbreviated, time: .omitted))
                        }
                        .font(AuraTypography.caption)
                        .foregroundColor(dueDate < Date() && !task.isCompleted ? AuraColors.destructive : AuraColors.textSecondary)
                    }
                    
                    Spacer()
                    
                    // Quick Shift Column Controls
                    HStack(spacing: 4) {
                        if task.status != .todo {
                            Button(action: { moveTaskBackward(task) }) {
                                Image(systemName: "chevron.left.circle")
                                    .font(.subheadline)
                                    .foregroundColor(AuraColors.textSecondary)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        if task.status != .archived {
                            Button(action: { moveTaskForward(task) }) {
                                Image(systemName: "chevron.right.circle")
                                    .font(.subheadline)
                                    .foregroundColor(AuraColors.accent)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .glassCard(padding: 10, borderColor: priorityBorderColor(task.priority))
        }
        .buttonStyle(.plain)
    }
    
    private func priorityBadge(_ priority: TaskItem.Priority) -> some View {
        let color: Color
        switch priority {
        case .low: color = AuraColors.success
        case .medium: color = AuraColors.warning
        case .high: color = AuraColors.destructive
        case .urgent: color = AuraColors.urgent
        }
        
        return Text(priority.label.uppercased())
            .font(AuraTypography.stats)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.18))
            .foregroundColor(color)
            .clipShape(Capsule())
    }
    
    private func priorityBorderColor(_ priority: TaskItem.Priority) -> Color {
        switch priority {
        case .urgent: return AuraColors.urgent.opacity(0.6)
        case .high: return AuraColors.destructive.opacity(0.4)
        default: return AuraColors.glassBorder
        }
    }
    
    private func moveTaskForward(_ task: TaskItem) {
        withAnimation {
            switch task.status {
            case .todo:
                task.status = .inProgress
            case .inProgress:
                task.status = .completed
            case .completed:
                task.status = .archived
                task.isArchived = true
            case .archived:
                break
            }
            AuraHaptics.kanbanMove()
        }
    }
    
    private func moveTaskBackward(_ task: TaskItem) {
        withAnimation {
            switch task.status {
            case .archived:
                task.status = .completed
                task.isArchived = false
            case .completed:
                task.status = .inProgress
            case .inProgress:
                task.status = .todo
            case .todo:
                break
            }
            AuraHaptics.kanbanMove()
        }
    }
}

// MARK: - Quick Kanban Task Sheet
struct QuickKanbanTaskSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var isPresented: Bool
    var defaultStatus: TaskItem.Status
    var projects: [Project]
    
    @State private var title = ""
    @State private var notes = ""
    @State private var priority: TaskItem.Priority = .medium
    @State private var selectedProject: Project?
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Task Details") {
                    TextField("Title", text: $title)
                    TextField("Notes", text: $notes, axis: .vertical)
                }
                
                Section("Priority") {
                    Picker("Priority", selection: $priority) {
                        ForEach(TaskItem.Priority.allCases, id: \.self) { p in
                            Text(p.label).tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Project (Optional)") {
                    Picker("Project", selection: $selectedProject) {
                        Text("None (Standalone)").tag(Project?.none)
                        ForEach(projects) { project in
                            Text(project.title).tag(Project?.some(project))
                        }
                    }
                }
            }
            .navigationTitle("New Kanban Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { addTask() }
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func addTask() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let newTask = TaskItem(
            title: trimmed,
            notes: notes,
            priority: priority,
            status: defaultStatus,
            project: selectedProject
        )
        if defaultStatus == .archived {
            newTask.isArchived = true
        }
        
        modelContext.insert(newTask)
        AuraHaptics.success()
        isPresented = false
    }
}
