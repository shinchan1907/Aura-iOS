import WidgetKit
import SwiftUI
import SwiftData

struct Provider: TimelineProvider {
    // In a real app, this would query SwiftData to get actual task counts.
    // For this boilerplate, we use placeholder data.
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), tasksCount: 3, progress: 0.6)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), tasksCount: 3, progress: 0.6)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []
        let entry = SimpleEntry(date: Date(), tasksCount: 3, progress: 0.6)
        entries.append(entry)

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let tasksCount: Int
    let progress: Double
}

struct AuraWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("\(entry.tasksCount) Tasks Left")
                .font(.title2.bold())
            
            Spacer()
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.secondary.opacity(0.2))
                    Capsule().fill(Color.indigo)
                        .frame(width: geo.size.width * CGFloat(entry.progress))
                }
            }
            .frame(height: 8)
        }
        .containerBackground(Color(UIColor.systemBackground), for: .widget)
    }
}

@main
struct AuraWidgetBundle: WidgetBundle {
    var body: some Widget {
        AuraWidget()
        QuickCaptureWidget()
        FocusLiveActivity()
    }
}

struct QuickCaptureWidget: Widget {
    let kind: String = "QuickCaptureWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            VStack {
                Text("Capture Idea")
                    .font(.headline)
                Button(intent: QuickCaptureIntent(title: "")) {
                    Image(systemName: "plus.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.indigo)
                }
                .buttonStyle(.plain)
            }
            .containerBackground(Color(UIColor.systemBackground), for: .widget)
        }
        .configurationDisplayName("Quick Capture")
        .description("Instantly save a new task.")
        .supportedFamilies([.systemSmall])
    }
}

struct AuraWidget: Widget {
    let kind: String = "AuraWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            AuraWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Today's Progress")
        .description("Track your daily task progress at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
