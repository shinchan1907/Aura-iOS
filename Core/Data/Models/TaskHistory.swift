import Foundation
import SwiftData

@Model
public final class TaskHistory {
    @Attribute(.unique) public var id: UUID
    public var timestamp: Date
    public var eventTypeRaw: String
    public var details: String
    
    @Relationship
    public var task: TaskItem?
    
    public init(id: UUID = UUID(), timestamp: Date = Date(), eventType: EventType, details: String = "", task: TaskItem? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.eventTypeRaw = eventType.rawValue
        self.details = details
        self.task = task
    }
    
    public enum EventType: String, Codable {
        case created = "created"
        case started = "started"
        case paused = "paused"
        case completed = "completed"
        case reopened = "reopened"
        case snoozed = "snoozed"
        case rescheduled = "rescheduled"
        case priorityChanged = "priorityChanged"
        case progressChanged = "progressChanged"
        case dueDateChanged = "dueDateChanged"
        case reminderCreated = "reminderCreated"
        case reminderTriggered = "reminderTriggered"
        case reminderDismissed = "reminderDismissed"
        case focusSessionStarted = "focusSessionStarted"
        case focusSessionCompleted = "focusSessionCompleted"
        case subtaskCompleted = "subtaskCompleted"
        case projectChanged = "projectChanged"
    }
    
    public var eventType: EventType {
        EventType(rawValue: eventTypeRaw) ?? .created
    }
}
