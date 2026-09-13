import Foundation
import ActivityKit

public struct FocusAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var durationElapsed: TimeInterval
        public var progress: Double // 0 to 1
        
        public init(durationElapsed: TimeInterval, progress: Double) {
            self.durationElapsed = durationElapsed
            self.progress = progress
        }
    }
    
    public var taskTitle: String
    public var taskEstimatedDuration: TimeInterval?
    
    public init(taskTitle: String, taskEstimatedDuration: TimeInterval? = nil) {
        self.taskTitle = taskTitle
        self.taskEstimatedDuration = taskEstimatedDuration
    }
}
