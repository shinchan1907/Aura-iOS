import SwiftUI
import SwiftData

public struct ProjectDetailView: View {
    @Bindable var project: Project
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingAddTask = false
    @State private var showingAddMilestone = false
    @State private var newMilestoneTitle = ""
    @State private var selectedTabFilter = 0 // 0: Tasks, 1: Milestones, 2: Kanban
    
    public init(project: Project) {
        self.project = project
    }
    
    private var projectTasks: [TaskItem] {
        project.tasks.sorted(by: { $0.createdAt > $1.createdAt })
    }
    
    private var activeTasks: [TaskItem] {
        projectTasks.filter { !$0.isArchived }
    }
    
    private var archivedTasks: [TaskItem] {
        projectTasks.filter { $0.isArchived }
    }
    
    public var body: some View {
        ZStack {
            AuraColors.background.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: AuraLayout.spacingLarge) {
                    // Project Banner & Metrics
                    projectBannerHeader
                    
                    // View Mode Segmented Control
                    Picker("View", selection: $selectedTabFilter) {
                        Text("Task List (\(activeTasks.count))").tag(0)
                        Text("Milestones (\(project.milestones.count))").tag(1)
                        Text("Archived (\(archivedTasks.count))").tag(2)
                    }
                    .pickerStyle(.segmented)
                    
                    if selectedTabFilter == 0 {
                        taskListSection
                    } else if selectedTabFilter == 1 {
                        milestonesSection
                    } else {
                        archivedTasksSection
                    }
                }
                .padding(AuraLayout.screenPadding)
            }
        }
        .navigationTitle(project.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(action: toggleProjectArchive) {
                        Label(project.isArchived ? "Unarchive Project" : "Archive Project", systemImage: project.isArchived ? "tray.and.arrow.up" : "archivebox")
                    }
                    Button(role: .destructive, action: deleteProject) {
                        Label("Delete Project", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.headline)
                        .foregroundColor(AuraColors.accent)
                }
            }
        }
        .sheet(isPresented: $showingAddTask) {
            ProjectTaskCreationSheet(isPresented: $showingAddTask, project: project)
        }
        .alert("New Milestone", isPresented: $showingAddMilestone) {
            TextField("Milestone title", text: $newMilestoneTitle)
            Button("Cancel", role: .cancel) { newMilestoneTitle = "" }
            Button("Add") { addMilestone() }
        }
    }
    
    // MARK: - Project Banner Header
    private var projectBannerHeader: some View {
        VStack(alignment: .leading, spacing: AuraLayout.spacingMedium) {
            HStack {
                Image(systemName: project.iconName)
                    .font(.title)
                    .foregroundColor(Color(hex: project.colorHex) ?? AuraColors.accent)
                VStack(alignment: .leading) {
                    Text(project.title)
                        .font(AuraTypography.title1)
                        .foregroundColor(AuraColors.textPrimary)
                    if !project.descriptionText.isEmpty {
                        Text(project.descriptionText)
                            .font(AuraTypography.subheadline)
                            .foregroundColor(AuraColors.textSecondary)
                    }
                }
                Spacer()
            }
            
            // Progress Bar & Stats
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Overall Progress")
                        .font(AuraTypography.caption)
                        .foregroundColor(AuraColors.textSecondary)
                    Spacer()
                    Text("\(Int(project.derivedProgress * 100))%")
                        .font(AuraTypography.stats)
                        .foregroundColor(Color(hex: project.colorHex) ?? AuraColors.accent)
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(AuraColors.glassSurface)
                        Capsule()
                            .fill(Color(hex: project.colorHex) ?? AuraColors.accent)
                            .frame(width: geo.size.width * CGFloat(project.derivedProgress))
                    }
                }
                .frame(height: 8)
            }
        }
        .glassCard(borderColor: Color(hex: project.colorHex)?.opacity(0.4) ?? AuraColors.glassBorder)
    }
    
    // MARK: - Task List Section
    private var taskListSection: some View {
        VStack(alignment: .leading, spacing: AuraLayout.spacingMedium) {
            HStack {
                Text("Project Tasks")
                    .font(AuraTypography.title2)
                    .foregroundColor(AuraColors.textPrimary)
                Spacer()
                Button(action: { showingAddTask = true }) {
                    Label("Add Task", systemImage: "plus")
                        .font(AuraTypography.subheadline.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color(hex: project.colorHex) ?? AuraColors.accent))
                }
            }
            
            if activeTasks.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle")
                        .font(.largeTitle)
                        .foregroundColor(AuraColors.textSecondary)
                    Text("No active tasks in this project.")
                        .font(AuraTypography.subheadline)
                        .foregroundColor(AuraColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .glassCard()
            } else {
                ForEach(activeTasks) { task in
                    NavigationLink(destination: TaskDetailView(task: task)) {
                        TaskRowView(task: task)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Milestones Section
    private var milestonesSection: some View {
        VStack(alignment: .leading, spacing: AuraLayout.spacingMedium) {
            HStack {
                Text("Milestones")
                    .font(AuraTypography.title2)
                    .foregroundColor(AuraColors.textPrimary)
                Spacer()
                Button(action: { showingAddMilestone = true }) {
                    Label("Add Milestone", systemImage: "plus")
                        .font(AuraTypography.subheadline.bold())
                }
            }
            
            if project.milestones.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "flag")
                        .font(.largeTitle)
                        .foregroundColor(AuraColors.textSecondary)
                    Text("No milestones added yet.")
                        .font(AuraTypography.subheadline)
                        .foregroundColor(AuraColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .glassCard()
            } else {
                ForEach(project.milestones) { milestone in
                    HStack {
                        Button(action: {
                            withAnimation { milestone.isCompleted.toggle() }
                            AuraHaptics.selection()
                        }) {
                            Image(systemName: milestone.isCompleted ? "checkmark.seal.fill" : "circle")
                                .font(.title3)
                                .foregroundColor(milestone.isCompleted ? AuraColors.success : AuraColors.textSecondary)
                        }
                        
                        Text(milestone.title)
                            .font(AuraTypography.headline)
                            .foregroundColor(milestone.isCompleted ? AuraColors.textSecondary : AuraColors.textPrimary)
                            .strikethrough(milestone.isCompleted)
                        Spacer()
                    }
                    .glassCard(padding: 12)
                }
            }
        }
    }
    
    // MARK: - Archived Tasks Section
    private var archivedTasksSection: some View {
        VStack(alignment: .leading, spacing: AuraLayout.spacingMedium) {
            Text("Archived Tasks")
                .font(AuraTypography.title2)
                .foregroundColor(AuraColors.textPrimary)
            
            if archivedTasks.isEmpty {
                Text("No archived tasks.")
                    .font(AuraTypography.subheadline)
                    .foregroundColor(AuraColors.textSecondary)
                    .padding()
                    .glassCard()
            } else {
                ForEach(archivedTasks) { task in
                    TaskRowView(task: task)
                }
            }
        }
    }
    
    private func addMilestone() {
        let trimmed = newMilestoneTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let milestone = ProjectMilestone(title: trimmed, project: project)
        modelContext.insert(milestone)
        newMilestoneTitle = ""
        AuraHaptics.success()
    }
    
    private func toggleProjectArchive() {
        withAnimation {
            project.isArchived.toggle()
            AuraHaptics.warning()
        }
    }
    
    private func deleteProject() {
        withAnimation {
            modelContext.delete(project)
            AuraHaptics.error()
            dismiss()
        }
    }
}

// MARK: - Project Task Creation Sheet
struct ProjectTaskCreationSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var isPresented: Bool
    var project: Project
    
    @State private var title = ""
    @State private var notes = ""
    @State private var priority: TaskItem.Priority = .medium
    @State private var dueDate = Date()
    @State private var includeDueDate = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AuraBackgroundView()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: AuraLayout.spacingLarge) {
                        VStack(alignment: .leading, spacing: AuraLayout.spacingSmall) {
                            Text("Task Information")
                                .font(AuraTypography.headline)
                                .foregroundColor(AuraColors.textSecondary)
                            AuraGlassTextField(placeholder: "Task Title", text: $title, iconName: "pencil")
                            AuraGlassTextField(placeholder: "Notes (Optional)", text: $notes, iconName: "note.text")
                        }
                        .glassCard()
                        
                        VStack(alignment: .leading, spacing: AuraLayout.spacingSmall) {
                            Text("Priority Level")
                                .font(AuraTypography.headline)
                                .foregroundColor(AuraColors.textSecondary)
                            AuraGlassSegmentedPicker(
                                items: TaskItem.Priority.allCases,
                                selection: $priority,
                                titleKeyPath: \.label
                            )
                        }
                        .glassCard()
                        
                        VStack(alignment: .leading, spacing: AuraLayout.spacingSmall) {
                            AuraGlassToggle(title: "Schedule Due Date", iconName: "calendar", isOn: $includeDueDate)
                            if includeDueDate {
                                DatePicker("Select Date", selection: $dueDate)
                                    .font(AuraTypography.body)
                            }
                        }
                        .glassCard()
                        
                        AuraGlassButton(title: "Add Task to Workspace", iconName: "plus.circle.fill") {
                            addTask()
                        }
                    }
                    .padding(AuraLayout.screenPadding)
                }
            }
            .navigationTitle("New Project Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
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
            dueDate: includeDueDate ? dueDate : nil,
            project: project
        )
        modelContext.insert(newTask)
        AuraHaptics.success()
        isPresented = false
    }
}
