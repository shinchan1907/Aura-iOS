import Foundation
import ActivityKit
import SwiftUI

public final class FocusActivityManager {
    public static let shared = FocusActivityManager()
    
    private var currentActivity: Activity<FocusAttributes>?
    private var timer: Timer?
    private var elapsedSeconds: Int = 0
    
    private init() {}
    
    public func startFocusActivity(taskTitle: String, estimatedSeconds: Int? = 1500) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("ActivityKit Live Activities are not enabled on this device/settings.")
            return
        }
        
        // End any existing session & timer
        endFocusActivity()
        
        self.elapsedSeconds = 0
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
            print("Successfully started Dynamic Island Live Activity: \(activity.id)")
            
            // Start real-time ticking timer for Dynamic Island updates
            DispatchQueue.main.async {
                self.timer?.invalidate()
                self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                    guard let self = self else { return }
                    self.elapsedSeconds += 1
                    self.updateFocusActivity(elapsedSeconds: self.elapsedSeconds)
                }
            }
        } catch {
            print("Error requesting ActivityKit Live Activity: \(error.localizedDescription)")
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
        DispatchQueue.main.async {
            self.timer?.invalidate()
            self.timer = nil
        }
        
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
