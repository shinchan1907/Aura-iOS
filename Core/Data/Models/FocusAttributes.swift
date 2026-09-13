import Foundation
import ActivityKit

public struct FocusAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var sessionState: SessionState
        public var elapsedSeconds: Int
        public var totalEstimatedSeconds: Int?
        
        public init(sessionState: SessionState, elapsedSeconds: Int, totalEstimatedSeconds: Int? = nil) {
            self.sessionState = sessionState
            self.elapsedSeconds = elapsedSeconds
            self.totalEstimatedSeconds = totalEstimatedSeconds
        }
    }
    
    public enum SessionState: String, Codable, Hashable {
        case active = "Active"
        case paused = "Paused"
        case approachingTarget = "Approaching Target"
        case completed = "Completed"
    }
    
    public var taskTitle: String
    
    public init(taskTitle: String) {
        self.taskTitle = taskTitle
    }
}
