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
        guard authorizationStatus == .authorized || authorizationStatus == .provisional else { return }
        
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
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: "\(task.id.uuidString)_\(date.timeIntervalSince1970)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    public func removeReminders(for task: TaskItem) {
        // Find and remove all pending notifications containing the task ID
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let identifiersToRemove = requests.filter { $0.identifier.hasPrefix(task.id.uuidString) }.map { $0.identifier }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
        }
    }
    
    // Delegate to handle in-app notification presentation
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}
