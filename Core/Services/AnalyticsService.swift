import Foundation
import SwiftData

public final class AnalyticsService {
    public static let shared = AnalyticsService()
    
    private init() {}
    
    public struct AnalyticsData {
        public let tasksCompleted: Int
        public let tasksCreated: Int
        public let overdueTasks: Int
        public let totalFocusTime: TimeInterval
        public let completionRate: Double // 0 to 1
    }
    
    public func getLast7DaysAnalytics(modelContext: ModelContext) -> AnalyticsData {
        return getAnalytics(for: -7, modelContext: modelContext)
    }
    
    public func getLast30DaysAnalytics(modelContext: ModelContext) -> AnalyticsData {
        return getAnalytics(for: -30, modelContext: modelContext)
    }
    
    private func getAnalytics(for daysOffset: Int, modelContext: ModelContext) -> AnalyticsData {
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .day, value: daysOffset, to: Date()) else {
            return AnalyticsData(tasksCompleted: 0, tasksCreated: 0, overdueTasks: 0, totalFocusTime: 0, completionRate: 0)
        }
        
        // In SwiftData we'd ideally use FetchDescriptors with Predicates, 
        // but for complex aggregation across history events, we might fetch and map.
        
        // Fetch history events within date range
        let descriptor = FetchDescriptor<TaskHistory>(
            predicate: #Predicate<TaskHistory> { event in
                event.timestamp >= startDate
            }
        )
        
        let events = (try? modelContext.fetch(descriptor)) ?? []
        
        let completed = events.filter { $0.eventType == .completed }.count
        let created = events.filter { $0.eventType == .created }.count
        
        // Focus time
        let focusDescriptor = FetchDescriptor<FocusSession>(
            predicate: #Predicate<FocusSession> { session in
                session.startTime >= startDate
            }
        )
        let sessions = (try? modelContext.fetch(focusDescriptor)) ?? []
        let totalFocusTime = sessions.reduce(0) { $0 + $1.duration }
        
        let completionRate = created > 0 ? Double(completed) / Double(created) : 0.0
        
        return AnalyticsData(
            tasksCompleted: completed,
            tasksCreated: created,
            overdueTasks: 0, // Requires checking tasks directly against their due dates
            totalFocusTime: totalFocusTime,
            completionRate: min(completionRate, 1.0)
        )
    }
}
