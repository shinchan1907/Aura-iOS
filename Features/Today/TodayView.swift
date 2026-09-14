import SwiftUI
import SwiftData

public struct TodayView: View {
    @Query(filter: #Predicate<TaskItem> { task in
        task.statusRaw != 2 && !task.isArchived // 2 is completed
    }, sort: \TaskItem.dueDate) 
    private var allIncompleteTasks: [TaskItem]
    
    @Query(filter: #Predicate<TaskItem> { task in
        task.statusRaw == 2 && !task.isArchived
    }) 
    private var allCompletedTasks: [TaskItem]
    
    @Query(sort: \AttendanceRecord.punchInTime, order: .reverse)
    private var attendanceRecords: [AttendanceRecord]
    
    @Environment(\.modelContext) private var modelContext
    @State private var showingCreateTask = false
    
    public init() {}
    
    private var activeAttendanceRecord: AttendanceRecord? {
        attendanceRecords.first(where: { $0.punchOutTime == nil })
    }
    
    private var focusNowTask: TaskItem? {
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
                AuraBackgroundView()
                
                // Ambient vibrant gradient glow
                LinearGradient(
                    colors: [AuraColors.accent.opacity(0.15), Color.clear],
                    startPoint: .topLeading,
                    endPoint: .center
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: AuraLayout.spacingLarge) {
                        headerSection
                        
                        // Office Punch Status Quick Pill
                        attendanceQuickWidget
                        
                        if let focusTask = focusNowTask {
                            focusNowSection(task: focusTask)
                        }
                        
                        tasksListSection
                    }
                    .padding(AuraLayout.screenPadding)
                }
            }
            .navigationTitle("Command Center")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        AuraHaptics.selection()
                        showingCreateTask = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(AuraColors.accent)
                    }
                }
            }
            .sheet(isPresented: $showingCreateTask) {
                QuickCaptureSheet(isPresented: $showingCreateTask)
                    .presentationDetents([.height(340)])
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AuraLayout.spacingTight) {
            Text(Date.now.formatted(date: .complete, time: .omitted))
                .font(AuraTypography.subheadline)
                .foregroundColor(AuraColors.textSecondary)
                .textCase(.uppercase)
            
            Text("Command Center")
                .font(AuraTypography.heroTitle)
                .foregroundColor(AuraColors.textPrimary)
            
            HStack {
                Text("\(allIncompleteTasks.count) tasks remaining • \(allCompletedTasks.count) finished")
                    .font(AuraTypography.subheadline)
                    .foregroundColor(AuraColors.textSecondary)
                
                Spacer()
                
                // Precision Progress Ring with % display
                ZStack {
                    Circle()
                        .stroke(AuraColors.accent.opacity(0.2), lineWidth: 5)
                    Circle()
                        .trim(from: 0, to: todayProgress)
                        .stroke(
                            AuraColors.cyberGlow,
                            style: StrokeStyle(lineWidth: 5, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: todayProgress)
                    
                    Text("\(Int(todayProgress * 100))%")
                        .font(AuraTypography.stats)
                        .foregroundColor(AuraColors.textPrimary)
                }
                .frame(width: 44, height: 44)
            }
        }
        .padding(.top, AuraLayout.spacingSmall)
    }
    
    private var attendanceQuickWidget: some View {
        HStack(spacing: AuraLayout.spacingMedium) {
            ZStack {
                Circle()
                    .fill(activeAttendanceRecord != nil ? AuraColors.success.opacity(0.2) : AuraColors.glassSurface)
                    .frame(width: 42, height: 42)
                Image(systemName: activeAttendanceRecord != nil ? "building.2.crop.circle.fill" : "building.2")
                    .foregroundColor(activeAttendanceRecord != nil ? AuraColors.success : AuraColors.textSecondary)
                    .font(.title3)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(activeAttendanceRecord != nil ? "Work Shift Active" : "Office Punch In Available")
                    .font(AuraTypography.headline)
                    .foregroundColor(AuraColors.textPrimary)
                Text(activeAttendanceRecord != nil ? "Punched in at \(activeAttendanceRecord!.punchInTime.formatted(date: .omitted, time: .shortened))" : "GPS geofence active • Tap Attendance to punch")
                    .font(AuraTypography.caption)
                    .foregroundColor(AuraColors.textSecondary)
            }
            Spacer()
            
            if activeAttendanceRecord != nil {
                Text("PUNCHED IN")
                    .font(AuraTypography.stats)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AuraColors.success.opacity(0.18))
                    .foregroundColor(AuraColors.success)
                    .clipShape(Capsule())
            }
        }
        .glassCard(
            padding: 14,
            borderColor: activeAttendanceRecord != nil ? AuraColors.success.opacity(0.45) : AuraColors.glassBorder,
            glowColor: activeAttendanceRecord != nil ? AuraColors.success : Color.clear
        )
    }
    
    private func focusNowSection(task: TaskItem) -> some View {
        VStack(alignment: .leading, spacing: AuraLayout.spacingMedium) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(AuraColors.warning)
                Text("Focus Spotlight")
                    .font(AuraTypography.title2)
                    .foregroundColor(AuraColors.textPrimary)
                Spacer()
                Text("TOP PRIORITY")
                    .font(AuraTypography.stats)
                    .foregroundColor(AuraColors.warning)
            }
            
            NavigationLink(destination: TaskDetailView(task: task)) {
                VStack(alignment: .leading, spacing: AuraLayout.spacingMedium) {
                    Text(task.title)
                        .font(AuraTypography.title1)
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
                            HStack(spacing: 6) {
                                Image(systemName: "play.fill")
                                    .font(.caption)
                                Text("Start Focus")
                                    .font(AuraTypography.subheadline.bold())
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(AuraColors.punchInGradient)
                                    .shadow(color: AuraColors.accent.opacity(0.4), radius: 8, x: 0, y: 4)
                            )
                        }
                    }
                }
                .glassCard(borderColor: AuraColors.accent.opacity(0.5), glowColor: AuraColors.accent)
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
                        TaskRowView(task: task, onToggle: {
                            toggleTaskCompletion(task)
                        })
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button {
                            toggleTaskCompletion(task)
                        } label: {
                            Label(task.isCompleted ? "Mark Uncompleted" : "Complete Task", systemImage: "checkmark.circle")
                        }
                        
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
                .foregroundColor(AuraColors.accent.opacity(0.6))
            Text("Workspace clear.")
                .font(AuraTypography.title2)
                .foregroundColor(AuraColors.textPrimary)
            Text("You've completed all scheduled tasks for today!")
                .font(AuraTypography.subheadline)
                .foregroundColor(AuraColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AuraLayout.spacingXLarge)
        .glassCard()
    }
    
    private func toggleTaskCompletion(_ task: TaskItem) {
        AuraHaptics.taskCompletion()
        withAnimation {
            task.status = task.isCompleted ? .todo : .completed
            let event = TaskHistory(
                eventType: task.isCompleted ? .completed : .reopened,
                details: "Toggled from Command Center",
                task: task
            )
            modelContext.insert(event)
        }
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
        FocusActivityManager.shared.startFocusActivity(taskTitle: task.title, estimatedSeconds: Int(task.estimatedDuration ?? 1500))
    }
    
    private func deleteTask(_ task: TaskItem) {
        withAnimation {
            modelContext.delete(task)
            AuraHaptics.error()
        }
    }
}

struct QuickCaptureSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var isPresented: Bool
    @State private var newTaskTitle: String = ""
    @State private var extractedDate: Date? = nil
    @State private var priority: TaskItem.Priority = .medium
    @FocusState private var isFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: AuraLayout.spacingLarge) {
                TextField("What needs to be done?", text: $newTaskTitle)
                    .font(AuraTypography.title2)
                    .focused($isFocused)
                    .onChange(of: newTaskTitle) { _, newValue in
                        parseNaturalLanguage(input: newValue)
                    }
                    .onSubmit {
                        addTask()
                    }
                    .submitLabel(.done)
                
                Picker("Priority", selection: $priority) {
                    ForEach(TaskItem.Priority.allCases, id: \.self) { p in
                        Text(p.label).tag(p)
                    }
                }
                .pickerStyle(.segmented)
                
                if let extractedDate = extractedDate {
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                            .font(AuraTypography.caption)
                        Text("Detected: \(extractedDate.formatted(date: .abbreviated, time: .shortened))")
                            .font(AuraTypography.caption.bold())
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AuraColors.accent.opacity(0.18))
                    .foregroundColor(AuraColors.accent)
                    .clipShape(Capsule())
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
                
                Spacer()
                
                Button(action: addTask) {
                    Text("Save Task")
                        .font(AuraTypography.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: AuraLayout.cornerRadiusMedium)
                                .fill(newTaskTitle.isEmpty ? Color.gray.opacity(0.4) : AuraColors.accent)
                        )
                }
                .disabled(newTaskTitle.isEmpty)
            }
            .padding()
            .navigationTitle("Quick Capture")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
            .onAppear {
                isFocused = true
            }
        }
    }
    
    private func parseNaturalLanguage(input: String) {
        guard !input.isEmpty else {
            withAnimation { self.extractedDate = nil }
            return
        }
        
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
        let matches = detector?.matches(in: input, options: [], range: NSRange(location: 0, length: input.utf16.count))
        
        if let match = matches?.first, let date = match.date {
            if self.extractedDate != date {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    self.extractedDate = date
                }
            }
        } else {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                self.extractedDate = nil
            }
        }
    }
    
    private func addTask() {
        let trimmed = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        withAnimation {
            let newTask = TaskItem(title: trimmed, priority: priority, dueDate: extractedDate)
            modelContext.insert(newTask)
            
            let event = TaskHistory(eventType: .created, details: "Captured in Quick Capture Sheet", task: newTask)
            modelContext.insert(event)
            
            AuraHaptics.success()
            isPresented = false
        }
    }
}
