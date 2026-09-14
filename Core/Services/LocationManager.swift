import Foundation
import CoreLocation
import Combine
import SwiftData
import UserNotifications

@Observable
public final class LocationManager: NSObject, CLLocationManagerDelegate {
    public static let shared = LocationManager()
    
    private let locationManager = CLLocationManager()
    
    public var currentLocation: CLLocation?
    public var authorizationStatus: CLAuthorizationStatus = .notDetermined
    public var distanceToOfficeMeters: Double?
    public var isAtOffice: Bool = false
    public var activePunchRecord: AttendanceRecord?
    
    public override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Update every 10 meters
        self.authorizationStatus = locationManager.authorizationStatus
    }
    
    public func requestPermissions() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestAlwaysAuthorization()
    }
    
    public func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }
    
    public func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    public func updateOfficeGeofence(office: OfficeLocation) {
        guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else { return }
        
        // Remove existing regions
        for region in locationManager.monitoredRegions {
            if region.identifier == "OFFICE_GEOFENCE" {
                locationManager.stopMonitoring(for: region)
            }
        }
        
        guard office.isConfigured else { return }
        
        let center = CLLocationCoordinate2D(latitude: office.latitude, longitude: office.longitude)
        let region = CLCircularRegion(center: center, radius: office.radiusMeters, identifier: "OFFICE_GEOFENCE")
        region.notifyOnEntry = true
        region.notifyOnExit = true
        
        locationManager.startMonitoring(for: region)
    }
    
    public func evaluateLocationAgainstOffice(office: OfficeLocation) {
        guard office.isConfigured, let currentLoc = currentLocation else {
            distanceToOfficeMeters = nil
            isAtOffice = false
            return
        }
        
        let officeLoc = CLLocation(latitude: office.latitude, longitude: office.longitude)
        let dist = currentLoc.distance(from: officeLoc)
        self.distanceToOfficeMeters = dist
        self.isAtOffice = dist <= office.radiusMeters
    }
    
    // MARK: - Punch Operations
    
    public func punchIn(context: ModelContext, office: OfficeLocation?, notes: String = "", isAuto: Bool = false) -> AttendanceRecord {
        let now = Date()
        let record = AttendanceRecord(
            date: now,
            punchInTime: now,
            status: .inProgress,
            locationName: office?.name ?? "Office",
            latitude: currentLocation?.coordinate.latitude ?? (office?.latitude ?? 0),
            longitude: currentLocation?.coordinate.longitude ?? (office?.longitude ?? 0),
            isAutoPunch: isAuto,
            notes: notes
        )
        
        context.insert(record)
        self.activePunchRecord = record
        
        AuraHaptics.punchIn()
        
        // Schedule notification confirmation
        NotificationManager.shared.scheduleReminder(
            for: TaskItem(title: "Punched In"),
            at: Date().addingTimeInterval(2),
            title: "Punched In Successfully 🏢",
            body: "Your office work shift has started at \(now.formatted(date: .omitted, time: .shortened)).",
            isTimeSensitive: true
        )
        
        return record
    }
    
    public func punchOut(context: ModelContext, record: AttendanceRecord, office: OfficeLocation? = nil, notes: String = "", isAuto: Bool = false) {
        let now = Date()
        record.punchOutTime = now
        if !notes.isEmpty {
            record.notes = notes
        }
        record.isAutoPunch = isAuto
        record.recalculateStatus()
        
        self.activePunchRecord = nil
        
        AuraHaptics.punchOut()
        
        // Notification confirmation
        let durationFormatted = formatDuration(record.totalDurationSeconds)
        NotificationManager.shared.scheduleReminder(
            for: TaskItem(title: "Punched Out"),
            at: Date().addingTimeInterval(2),
            title: "Punched Out 👋",
            body: "Work shift ended. Total duration: \(durationFormatted). Status: \(record.status.label).",
            isTimeSensitive: true
        )
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
    
    // MARK: - CLLocationManagerDelegate
    
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
            if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
                self.startUpdatingLocation()
            }
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        DispatchQueue.main.async {
            self.currentLocation = latest
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if region.identifier == "OFFICE_GEOFENCE" {
            DispatchQueue.main.async {
                self.isAtOffice = true
                NotificationManager.shared.scheduleReminder(
                    for: TaskItem(title: "Arrived at Office"),
                    at: Date().addingTimeInterval(1),
                    title: "Welcome to Office! 🏢",
                    body: "Tap to Punch In for your work shift.",
                    isTimeSensitive: true
                )
            }
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if region.identifier == "OFFICE_GEOFENCE" {
            DispatchQueue.main.async {
                self.isAtOffice = false
                if self.activePunchRecord != nil {
                    NotificationManager.shared.scheduleReminder(
                        for: TaskItem(title: "Left Office"),
                        at: Date().addingTimeInterval(1),
                        title: "Left Office Area 🚗",
                        body: "You left office boundaries. Don't forget to Punch Out!",
                        isTimeSensitive: true
                    )
                }
            }
        }
    }
}
