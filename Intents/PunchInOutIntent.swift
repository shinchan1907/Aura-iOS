import AppIntents
import SwiftData
import Foundation

public struct PunchInOutIntent: AppIntent {
    public static var title: LocalizedStringResource = "Punch In / Out"
    
    public init() {}
    
    public func perform() async throws -> some IntentResult {
        Task { @MainActor in
            let context = AuraSchema.modelContainer.mainContext
            let descriptor = FetchDescriptor<AttendanceRecord>(sortBy: [SortDescriptor(\.punchInTime, order: .reverse)])
            let records = (try? context.fetch(descriptor)) ?? []
            
            if let active = records.first(where: { $0.punchOutTime == nil }) {
                active.punchOutTime = Date()
                active.recalculateStatus()
                try? context.save()
                FocusActivityManager.shared.endFocusActivity()
            } else {
                let newRecord = AttendanceRecord(date: Date(), punchInTime: Date(), status: .inProgress, locationName: "Office")
                context.insert(newRecord)
                try? context.save()
                FocusActivityManager.shared.startFocusActivity(taskTitle: "Office Shift", estimatedSeconds: 28800)
            }
        }
        return .result()
    }
}
