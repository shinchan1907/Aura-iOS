import Foundation
import UserNotifications
import SwiftData

@Observable
public final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    public static let shared = NotificationManager()
    
    public var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        checkAuthorizationStatus()
    }
    
    public func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authorizationStatus = settings.authorizationStatus
            }
        }
    }
    
    public func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                self.checkAuthorizationStatus()
            }
        }
    }
    
    public func scheduleReminder(for task: TaskItem, at date: Date, title: String, body: String, isTimeSensitive: Bool = false) {
        if authorizationStatus == .notDetermined {
            requestAuthorization()
        }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        if isTimeSensitive {
            content.interruptionLevel = .timeSensitive
        }
        
        // Setup Actions (Complete, Snooze, Start)
        let completeAction = UNNotificationAction(identifier: "COMPLETE_TASK", title: "Complete", options: [])
        let snoozeAction = UNNotificationAction(identifier: "SNOOZE_TASK", title: "Snooze 15m", options: [])
        let startAction = UNNotificationAction(identifier: "START_FOCUS", title: "Start Focus", options: [.foreground])
        
        let category = UNNotificationCategory(identifier: "TASK_REMINDER", actions: [startAction, completeAction, snoozeAction], intentIdentifiers: [], options: .customDismissAction)
        UNUserNotificationCenter.current().setNotificationCategories([category])
        
        content.categoryIdentifier = "TASK_REMINDER"
        
        let trigger: UNNotificationTrigger
        let secondsFromNow = date.timeIntervalSinceNow
        if secondsFromNow <= 10 {
            // Trigger immediately in 2 seconds for test/current reminders
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(2, secondsFromNow), repeats: false)
            
            // Automatically launch Dynamic Island activity for instant test reminders
            FocusActivityManager.shared.startFocusActivity(taskTitle: task.title, estimatedSeconds: 1500)
        } else {
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        }
        
        let request = UNNotificationRequest(identifier: "\(task.id.uuidString)_\(date.timeIntervalSince1970)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    public func scheduleFollowUpAlarm(for task: TaskItem, at date: Date) {
        if authorizationStatus == .notDetermined {
            requestAuthorization()
        }
        
        let content = UNMutableNotificationContent()
        content.title = "⏰ Follow-Up Reminder: \(task.title)"
        content.body = "It's time to check progress or complete this task."
        content.sound = .defaultCritical
        content.interruptionLevel = .timeSensitive
        
        let trigger: UNNotificationTrigger
        let secondsFromNow = date.timeIntervalSinceNow
        if secondsFromNow <= 10 {
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(2, secondsFromNow), repeats: false)
            FocusActivityManager.shared.startFocusActivity(taskTitle: task.title, estimatedSeconds: 1500)
        } else {
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        }
        
        let request = UNNotificationRequest(identifier: "FOLLOWUP_\(task.id.uuidString)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
    
    public func removeReminders(for task: TaskItem) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let identifiersToRemove = requests.filter { $0.identifier.contains(task.id.uuidString) }.map { $0.identifier }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
        }
    }
    
    // Delegate to handle in-app notification presentation & Dynamic Island spawn
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Automatically present Dynamic Island activity when task reminder notification fires
        let taskTitle = notification.request.content.title
        FocusActivityManager.shared.startFocusActivity(taskTitle: taskTitle, estimatedSeconds: 1500)
        
        completionHandler([.banner, .sound, .badge, .list])
    }
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let taskTitle = response.notification.request.content.title
        FocusActivityManager.shared.startFocusActivity(taskTitle: taskTitle, estimatedSeconds: 1500)
        completionHandler()
    }
}
