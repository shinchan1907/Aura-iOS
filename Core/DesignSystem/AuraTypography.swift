import SwiftUI

public enum AuraTypography {
    
    // Hero Title (e.g. Today view greeting)
    public static var heroTitle: Font {
        .system(size: 34, weight: .bold, design: .rounded)
    }
    
    // Main screen headers
    public static var title1: Font {
        .system(size: 26, weight: .bold, design: .rounded)
    }
    
    // Sub-headers & Section Titles
    public static var title2: Font {
        .system(size: 20, weight: .semibold, design: .rounded)
    }
    
    // Standard Task & Component Titles
    public static var headline: Font {
        .system(size: 17, weight: .semibold, design: .default)
    }
    
    // Body Text
    public static var body: Font {
        .system(size: 15, weight: .regular, design: .default)
    }
    
    // Secondary Information
    public static var subheadline: Font {
        .system(size: 14, weight: .medium, design: .default)
    }
    
    // Captions & Metadata
    public static var caption: Font {
        .system(size: 12, weight: .medium, design: .default)
    }
    
    // Metrics, Monospaced Timers & Stats
    public static var stats: Font {
        .system(size: 12, weight: .bold, design: .monospaced)
    }
    
    // Large Gauge Number Display
    public static var gaugeNumber: Font {
        .system(size: 44, weight: .bold, design: .rounded)
    }
}
