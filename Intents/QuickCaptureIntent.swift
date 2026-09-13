import AppIntents
import SwiftData

public struct QuickCaptureIntent: AppIntent {
    public static var title: LocalizedStringResource = "Quick Capture Task"
    
    @Parameter(title: "Task Title")
    public var title: String
    
    public init(title: String = "") {
        self.title = title
    }
    
    public func perform() async throws -> some IntentResult {
        // In a real implementation, this would instantiate the SwiftData context
        // and insert the task securely.
        return .result()
    }
}
