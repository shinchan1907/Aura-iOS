import Foundation
import SwiftData

@Model
public final class ProjectMilestone {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var targetDate: Date?
    public var isCompleted: Bool = false
    
    @Relationship
    public var project: Project?
    
    public init(id: UUID = UUID(), title: String, targetDate: Date? = nil, project: Project? = nil) {
        self.id = id
        self.title = title
        self.targetDate = targetDate
        self.project = project
    }
}

@Model
public final class Project {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var colorHex: String
    public var createdAt: Date
    
    public var tasks: [TaskItem] = []
    
    @Relationship(deleteRule: .cascade, inverse: \ProjectMilestone.project)
    public var milestones: [ProjectMilestone] = []
    
    public init(id: UUID = UUID(), title: String, colorHex: String = "#0A57D0") {
        self.id = id
        self.title = title
        self.colorHex = colorHex
        self.createdAt = Date()
    }
    
    public var derivedProgress: Double {
        guard !tasks.isEmpty else { return 0.0 }
        let totalProgress = tasks.reduce(0.0) { $0 + $1.derivedProgress }
        return totalProgress / Double(tasks.count)
    }
}
