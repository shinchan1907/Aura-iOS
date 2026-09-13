import AppIntents
import SwiftData
import ActivityKit

public struct PauseFocusIntent: LiveActivityIntent {
    public static var title: LocalizedStringResource = "Pause Focus"
    
    public init() {}
    
    public func perform() async throws -> some IntentResult {
        Task { @MainActor in
            for activity in Activity<FocusAttributes>.activities {
                var contentState = activity.content.state
                contentState.sessionState = .paused
                await activity.update(using: contentState)
            }
        }
        return .result()
    }
}

public struct ResumeFocusIntent: LiveActivityIntent {
    public static var title: LocalizedStringResource = "Resume Focus"
    
    public init() {}
    
    public func perform() async throws -> some IntentResult {
        Task { @MainActor in
            for activity in Activity<FocusAttributes>.activities {
                var contentState = activity.content.state
                contentState.sessionState = .active
                await activity.update(using: contentState)
            }
        }
        return .result()
    }
}

public struct CompleteFocusIntent: LiveActivityIntent {
    public static var title: LocalizedStringResource = "Complete Focus"
    
    public init() {}
    
    public func perform() async throws -> some IntentResult {
        Task { @MainActor in
            let context = AuraSchema.modelContainer.mainContext
            let descriptor = FetchDescriptor<FocusSession>()
            if let sessions = try? context.fetch(descriptor) {
                for session in sessions where session.isActive {
                    session.endSession()
                    if let task = session.task {
                        let event = TaskHistory(eventType: .completed, details: "Completed via Live Activity", task: task)
                        context.insert(event)
                        task.status = .completed
                    }
                }
                try? context.save()
            }
            
            for activity in Activity<FocusAttributes>.activities {
                var contentState = activity.content.state
                contentState.sessionState = .completed
                await activity.end(ActivityContent(state: contentState, staleDate: nil), dismissalPolicy: .immediate)
            }
        }
        return .result()
    }
}
