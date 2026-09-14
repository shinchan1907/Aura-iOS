import Foundation
import SwiftData

@Model
public final class AttendanceRecord {
    @Attribute(.unique) public var id: UUID
    public var date: Date
    public var punchInTime: Date
    public var punchOutTime: Date?
    public var totalDurationSeconds: TimeInterval = 0
    public var statusRaw: Int
    public var locationName: String
    public var latitude: Double
    public var longitude: Double
    public var isAutoPunch: Bool
    public var notes: String
    
    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        punchInTime: Date = Date(),
        punchOutTime: Date? = nil,
        totalDurationSeconds: TimeInterval = 0,
        status: AttendanceStatus = .inProgress,
        locationName: String = "Office",
        latitude: Double = 0.0,
        longitude: Double = 0.0,
        isAutoPunch: Bool = false,
        notes: String = ""
    ) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.punchInTime = punchInTime
        self.punchOutTime = punchOutTime
        self.totalDurationSeconds = totalDurationSeconds
        self.statusRaw = status.rawValue
        self.locationName = locationName
        self.latitude = latitude
        self.longitude = longitude
        self.isAutoPunch = isAutoPunch
        self.notes = notes
    }
    
    public enum AttendanceStatus: Int, Codable, CaseIterable {
        case inProgress = 0
        case present = 1       // >= 8 hours
        case halfDay = 2       // < 8 hours and >= 4 hours
        case absent = 3        // < 4 hours
        case overtime = 4      // > 9 hours
        
        public var label: String {
            switch self {
            case .inProgress: return "Punched In"
            case .present: return "Full Day"
            case .halfDay: return "Half Day"
            case .absent: return "Absent / Incomplete"
            case .overtime: return "Overtime"
            }
        }
    }
    
    public var status: AttendanceStatus {
        get { AttendanceStatus(rawValue: statusRaw) ?? .inProgress }
        set { statusRaw = newValue.rawValue }
    }
    
    public var currentDuration: TimeInterval {
        if let punchOut = punchOutTime {
            return punchOut.timeIntervalSince(punchInTime)
        } else {
            return Date().timeIntervalSince(punchInTime)
        }
    }
    
    public func recalculateStatus() {
        guard let punchOut = punchOutTime else {
            status = .inProgress
            return
        }
        
        let duration = punchOut.timeIntervalSince(punchInTime)
        self.totalDurationSeconds = duration
        let hours = duration / 3600.0
        
        if hours >= 9.5 {
            status = .overtime
        } else if hours >= 7.5 {
            status = .present
        } else if hours >= 3.5 {
            status = .halfDay
        } else {
            status = .absent
        }
    }
}
