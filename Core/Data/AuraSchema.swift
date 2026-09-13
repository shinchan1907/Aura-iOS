import SwiftData

public enum AuraSchema {
    public static var modelContainer: ModelContainer = {
        let schema = Schema([
            TaskItem.self,
            TaskHistory.self,
            Project.self,
            ProjectMilestone.self,
            FocusSession.self,
            Tag.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
}
