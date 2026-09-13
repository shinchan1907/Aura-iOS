import SwiftUI

public enum AuraTypography {
    
    // Large prominent titles (e.g. Today view)
    public static var heroTitle: Font {
        .system(.largeTitle, design: .rounded).weight(.bold)
    }
    
    // Main screen headers
    public static var title1: Font {
        .system(.title, design: .default).weight(.semibold)
    }
    
    // Sub-headers
    public static var title2: Font {
        .system(.title2, design: .default).weight(.semibold)
    }
    
    // Standard task title
    public static var headline: Font {
        .system(.headline, design: .default)
    }
    
    // Body text for notes
    public static var body: Font {
        .system(.body, design: .default)
    }
    
    // Secondary information (tags, times)
    public static var subheadline: Font {
        .system(.subheadline, design: .default)
    }
    
    // Small metadata
    public static var caption: Font {
        .system(.caption, design: .default)
    }
    
    // Tiny stats/progress numbers
    public static var stats: Font {
        .system(.caption2, design: .monospaced).weight(.medium)
    }
}
