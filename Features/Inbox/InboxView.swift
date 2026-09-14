import SwiftUI
import SwiftData

public struct InboxView: View {
    @Query(filter: #Predicate<TaskItem> { task in
        task.project == nil && task.statusRaw != 2 && !task.isArchived // 2 is TaskItem.Status.completed
    }, sort: \TaskItem.createdAt, order: .reverse) 
    private var inboxTasks: [TaskItem]
    
    @Environment(\.modelContext) private var modelContext
    
    @State private var newTaskTitle: String = ""
    @State private var extractedDate: Date? = nil
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AuraColors.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Quick Entry Area
                    VStack(alignment: .leading, spacing: AuraLayout.spacingTight) {
                        HStack {
                            Image(systemName: "circle")
                                .foregroundColor(AuraColors.textSecondary)
                                .font(.title2)
                            
                            TextField("What needs to be done?", text: $newTaskTitle)
                                .font(AuraTypography.headline)
                                .onChange(of: newTaskTitle) { _, newValue in
                                    parseNaturalLanguage(input: newValue)
                                }
                                .onSubmit {
                                    addTask()
                                }
                                .submitLabel(.done)
                            
                            if !newTaskTitle.isEmpty {
                                Button(action: addTask) {
                                    Image(systemName: "arrow.up.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(AuraColors.accent)
                                }
                            }
                        }
                        
                        // Extracted Date Chip
                        if let extractedDate = extractedDate {
                            HStack {
                                Image(systemName: "calendar")
                                    .font(AuraTypography.caption)
                                Text(extractedDate.formatted(date: .abbreviated, time: .shortened))
                                    .font(AuraTypography.caption)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AuraColors.accent.opacity(0.15))
                            .foregroundColor(AuraColors.accent)
                            .clipShape(Capsule())
                            .transition(.opacity.combined(with: .scale(scale: 0.9)))
                        }
                    }
                    .glassCard()
                    .padding()
                    
                    if inboxTasks.isEmpty {
                        emptyState
                    } else {
                        List {
                            ForEach(inboxTasks) { task in
                                NavigationLink(destination: TaskDetailView(task: task)) {
                                    TaskRowView(task: task)
                                }
                                .buttonStyle(.plain)
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .padding(.horizontal)
                                .padding(.vertical, AuraLayout.spacingTight)
                            }
                            .onDelete(perform: deleteTasks)
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .navigationTitle("Inbox")
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: AuraLayout.spacingMedium) {
            Spacer()
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(AuraColors.accent.opacity(0.5))
            Text("Clear Mind, Clear Inbox")
                .font(AuraTypography.title2)
                .foregroundColor(AuraColors.textPrimary)
            Text("Capture tasks quickly using natural language. Try typing 'Call Rahul tomorrow at 6 PM'.")
                .font(AuraTypography.body)
                .foregroundColor(AuraColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AuraLayout.spacingXLarge)
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Inbox is empty. Capture tasks quickly using natural language.")
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
        
        // Strip out the detected date text if needed, but keeping it simple for now.
        let finalTitle = trimmed
        let taskDueDate = extractedDate
        
        withAnimation {
            let newTask = TaskItem(title: finalTitle, dueDate: taskDueDate)
            modelContext.insert(newTask)
            
            let event = TaskHistory(eventType: .created, details: "Captured in Inbox", task: newTask)
            modelContext.insert(event)
            
            if taskDueDate != nil {
                let dueEvent = TaskHistory(eventType: .dueDateChanged, details: "Due date parsed automatically", task: newTask)
                modelContext.insert(dueEvent)
            }
            
            newTaskTitle = ""
            extractedDate = nil
            AuraHaptics.success()
        }
    }
    
    private func deleteTasks(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(inboxTasks[index])
            }
        }
    }
}
