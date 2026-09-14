import Foundation
import SwiftData

@Model
public final class OfficeLocation {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var latitude: Double
    public var longitude: Double
    public var radiusMeters: Double
    public var autoPunchInEnabled: Bool
    public var autoPunchOutEnabled: Bool
    public var isConfigured: Bool
    
    public init(
        id: UUID = UUID(),
        name: String = "Main Office",
        latitude: Double = 0.0,
        longitude: Double = 0.0,
        radiusMeters: Double = 100.0,
        autoPunchInEnabled: Bool = true,
        autoPunchOutEnabled: Bool = true,
        isConfigured: Bool = false
    ) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.radiusMeters = radiusMeters
        self.autoPunchInEnabled = autoPunchInEnabled
        self.autoPunchOutEnabled = autoPunchOutEnabled
        self.isConfigured = isConfigured
    }
}
