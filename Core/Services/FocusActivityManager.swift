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
            sessionState: .active,
            elapsedSeconds: 0,
            totalEstimatedSeconds: estimatedSeconds
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
        
        var updatedState = activity.content.state
        updatedState.elapsedSeconds = elapsedSeconds
        updatedState.sessionState = state
        let targetState = updatedState
        
        Task {
            await activity.update(ActivityContent(state: targetState, staleDate: nil))
        }
    }
    
    public func endFocusActivity() {
        guard let activity = currentActivity else { return }
        
        var updatedState = activity.content.state
        updatedState.sessionState = .completed
        let targetFinalState = updatedState
        
        Task {
            await activity.end(ActivityContent(state: targetFinalState, staleDate: nil), dismissalPolicy: .immediate)
        }
        self.currentActivity = nil
    }
}
