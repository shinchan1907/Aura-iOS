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
    public var descriptionText: String = ""
    public var iconName: String = "folder.fill"
    public var colorHex: String
    public var isArchived: Bool = false
    public var createdAt: Date
    
    public var tasks: [TaskItem] = []
    
    @Relationship(deleteRule: .cascade, inverse: \ProjectMilestone.project)
    public var milestones: [ProjectMilestone] = []
    
    public init(
        id: UUID = UUID(),
        title: String,
        descriptionText: String = "",
        iconName: String = "folder.fill",
        colorHex: String = "#6159F7",
        isArchived: Bool = false
    ) {
        self.id = id
        self.title = title
        self.descriptionText = descriptionText
        self.iconName = iconName
        self.colorHex = colorHex
        self.isArchived = isArchived
        self.createdAt = Date()
    }
    
    public var derivedProgress: Double {
        let activeTasks = tasks.filter { !$0.isArchived }
        guard !activeTasks.isEmpty else { return 0.0 }
        let totalProgress = activeTasks.reduce(0.0) { $0 + $1.derivedProgress }
        return totalProgress / Double(activeTasks.count)
    }
}

