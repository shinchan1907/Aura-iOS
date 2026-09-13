import Foundation
import SwiftData

@Model
public final class TaskItem {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var notes: String
    public var priorityRaw: Int
    public var statusRaw: Int
    public var progress: Double // 0.0 to 1.0
    
    public var startDate: Date?
    public var dueDate: Date?
    public var deadline: Date?
    public var estimatedDuration: TimeInterval? // in seconds
    public var actualDuration: TimeInterval = 0
    public var reminderDates: [Date] = []
    public var recurrenceRuleRaw: String? // e.g. "daily", "weekly"
    
    // Relationships
    @Relationship(deleteRule: .nullify, inverse: \Project.tasks)
    public var project: Project?
    
    @Relationship(deleteRule: .cascade)
    public var historyEvents: [TaskHistory] = []
    
    @Relationship(deleteRule: .cascade)
    public var focusSessions: [FocusSession] = []
    
    @Relationship
    public var tags: [Tag] = []
    
    @Relationship(deleteRule: .nullify, inverse: \TaskItem.subtasks)
    public var parentTask: TaskItem?
    
    @Relationship(deleteRule: .cascade)
    public var subtasks: [TaskItem] = []
    
    public var createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: UUID = UUID(),
        title: String = "",
        notes: String = "",
        priority: Priority = .medium,
        status: Status = .todo,
        progress: Double = 0.0,
        startDate: Date? = nil,
        dueDate: Date? = nil,
        deadline: Date? = nil,
        estimatedDuration: TimeInterval? = nil,
        project: Project? = nil,
        parentTask: TaskItem? = nil
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.priorityRaw = priority.rawValue
        self.statusRaw = status.rawValue
        self.progress = progress
        self.startDate = startDate
        self.dueDate = dueDate
        self.deadline = deadline
        self.estimatedDuration = estimatedDuration
        self.project = project
        self.parentTask = parentTask
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    public enum Priority: Int, Codable, CaseIterable {
        case low = 0
        case medium = 1
        case high = 2
    }
    
    public enum Status: Int, Codable, CaseIterable {
        case todo = 0
        case inProgress = 1
        case completed = 2
    }
    
    public var priority: Priority {
        get { Priority(rawValue: priorityRaw) ?? .medium }
        set { priorityRaw = newValue.rawValue }
    }
    
    public var status: Status {
        get { Status(rawValue: statusRaw) ?? .todo }
        set { statusRaw = newValue.rawValue }
    }
    
    public var isCompleted: Bool {
        status == .completed
    }
    
    // Subtask hierarchical progress derivation
    public var derivedProgress: Double {
        if subtasks.isEmpty {
            return progress
        } else {
            let total = subtasks.reduce(0.0) { $0 + $1.derivedProgress }
            return total / Double(subtasks.count)
        }
    }
}
