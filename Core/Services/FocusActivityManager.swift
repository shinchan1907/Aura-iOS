import Foundation
import ActivityKit
import SwiftUI

public final class FocusActivityManager {
    public static let shared = FocusActivityManager()
    
    private var currentActivity: Activity<FocusAttributes>?
    
    private init() {}
    
    public func startFocusActivity(taskTitle: String, estimatedSeconds: Int? = 1500) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("ActivityKit Live Activities are not enabled.")
            return
        }
        
        // End any previous session
        endFocusActivity()
        
        let attributes = FocusAttributes(taskTitle: taskTitle)
        let initialState = FocusAttributes.ContentState(
            elapsedSeconds: 0,
            totalEstimatedSeconds: estimatedSeconds,
            sessionState: .active
        )
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )
            self.currentActivity = activity
            print("Successfully requested Live Activity / Dynamic Island: \(activity.id)")
        } catch {
            print("Error requesting Live Activity: \(error.localizedDescription)")
        }
    }
    
    public func updateFocusActivity(elapsedSeconds: Int, state: FocusAttributes.SessionState = .active) {
        guard let activity = currentActivity else { return }
        
        var contentState = activity.content.state
        contentState.elapsedSeconds = elapsedSeconds
        contentState.sessionState = state
        
        Task {
            await activity.update(ActivityContent(state: contentState, staleDate: nil))
        }
    }
    
    public func endFocusActivity() {
        guard let activity = currentActivity else { return }
        
        var finalState = activity.content.state
        finalState.sessionState = .completed
        
        Task {
            await activity.end(ActivityContent(state: finalState, staleDate: nil), dismissalPolicy: .immediate)
        }
        self.currentActivity = nil
    }
}
