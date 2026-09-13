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
    
    public func getDailyProgress(for daysOffset: Int, modelContext: ModelContext) -> [DailyProgress] {
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .day, value: daysOffset, to: Date()) else {
            return []
        }
        
        let descriptor = FetchDescriptor<TaskHistory>(
            predicate: #Predicate<TaskHistory> { event in
                event.timestamp >= startDate
            }
        )
        let events = (try? modelContext.fetch(descriptor)) ?? []
        
        var dailyStats: [String: (completed: Int, created: Int)] = [:]
        
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE" // e.g. "Mon", "Tue"
        
        for i in 0..<abs(daysOffset) {
            if let date = calendar.date(byAdding: .day, value: i, to: startDate) {
                dailyStats[formatter.string(from: date)] = (0, 0)
            }
        }
        
        for event in events {
            let day = formatter.string(from: event.timestamp)
            var stats = dailyStats[day] ?? (0, 0)
            if event.eventType == .completed {
                stats.completed += 1
            } else if event.eventType == .created {
                stats.created += 1
            }
            dailyStats[day] = stats
        }
        
        // Return sorted by date
        var result: [DailyProgress] = []
        for i in 0..<abs(daysOffset) {
            if let date = calendar.date(byAdding: .day, value: i, to: startDate) {
                let dayStr = formatter.string(from: date)
                if let stats = dailyStats[dayStr] {
                    result.append(DailyProgress(day: dayStr, completed: stats.completed, created: stats.created))
                }
            }
        }
        return result
    }
}

public struct DailyProgress: Identifiable {
    public let id = UUID()
    public let day: String
    public let completed: Int
    public let created: Int
    
    public init(day: String, completed: Int, created: Int) {
        self.day = day
        self.completed = completed
        self.created = created
    }
}
