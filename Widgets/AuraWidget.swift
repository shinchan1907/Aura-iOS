import WidgetKit
import SwiftUI
import SwiftData

struct Provider: TimelineProvider {
    @MainActor
    private func fetchTodayProgress() -> (count: Int, progress: Double) {
        do {
            let context = AuraSchema.modelContainer.mainContext
            let descriptor = FetchDescriptor<TaskItem>()
            let allTasks = try context.fetch(descriptor)
            let completed = allTasks.filter { $0.statusRaw == 2 }
            let incomplete = allTasks.filter { $0.statusRaw != 2 }
            
            let total = allTasks.count
            let progress = total > 0 ? Double(completed.count) / Double(total) : 0.0
            return (incomplete.count, progress)
        } catch {
            return (0, 0.0)
        }
    }

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), tasksCount: 3, progress: 0.6)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        Task { @MainActor in
            let stats = fetchTodayProgress()
            let entry = SimpleEntry(date: Date(), tasksCount: stats.count, progress: stats.progress)
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        Task { @MainActor in
            let stats = fetchTodayProgress()
            let entry = SimpleEntry(date: Date(), tasksCount: stats.count, progress: stats.progress)
            // Update widget every 15 minutes
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
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
                Button(intent: QuickCaptureIntent(taskTitle: "")) {
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
