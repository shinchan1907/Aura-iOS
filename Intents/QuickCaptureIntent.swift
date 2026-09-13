import AppIntents
import SwiftData

public struct QuickCaptureIntent: AppIntent {
    public static var title: LocalizedStringResource = "Quick Capture Task"
    
    @Parameter(title: "Task Title")
    public var taskTitle: String?
    
    public init() {}
    
    public init(taskTitle: String) {
        self.taskTitle = taskTitle
    }
    
    public func perform() async throws -> some IntentResult {
        guard let title = taskTitle, !title.isEmpty else {
            return .result()
        }
        
        Task { @MainActor in
            let context = AuraSchema.modelContainer.mainContext
            let newTask = TaskItem(title: title)
            context.insert(newTask)
            
            let event = TaskHistory(eventType: .created, details: "Captured via Quick Capture", task: newTask)
            context.insert(event)
            
            try? context.save()
        }
        
        return .result()
    }
}
