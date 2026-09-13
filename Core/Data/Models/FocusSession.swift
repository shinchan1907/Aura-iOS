import Foundation
import SwiftData

@Model
public final class FocusSession {
    @Attribute(.unique) public var id: UUID
    public var startTime: Date
    public var endTime: Date?
    public var duration: TimeInterval // Cached total seconds when ended
    
    @Relationship
    public var task: TaskItem?
    
    public init(id: UUID = UUID(), startTime: Date = Date(), task: TaskItem? = nil) {
        self.id = id
        self.startTime = startTime
        self.duration = 0
        self.task = task
    }
    
    public var isActive: Bool {
        endTime == nil
    }
    
    public func endSession() {
        let now = Date()
        self.endTime = now
        self.duration = now.timeIntervalSince(self.startTime)
    }
}
