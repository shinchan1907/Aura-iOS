import WidgetKit
import SwiftUI
import SwiftData

struct Provider: TimelineProvider {
    @MainActor
    private func fetchTodayStats() -> (count: Int, progress: Double, isPunchedIn: Bool) {
        do {
            let context = AuraSchema.modelContainer.mainContext
            let descriptor = FetchDescriptor<TaskItem>()
            let allTasks = try context.fetch(descriptor)
            let completed = allTasks.filter { $0.statusRaw == 2 }
            let incomplete = allTasks.filter { $0.statusRaw != 2 }
            
            let total = allTasks.count
            let progress = total > 0 ? Double(completed.count) / Double(total) : 0.0
            
            let attendanceDescriptor = FetchDescriptor<AttendanceRecord>(sortBy: [SortDescriptor(\.punchInTime, order: .reverse)])
            let records = try context.fetch(attendanceDescriptor)
            let isPunchedIn = records.contains(where: { $0.punchOutTime == nil })
            
            return (incomplete.count, progress, isPunchedIn)
        } catch {
            return (0, 0.0, false)
        }
    }

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), tasksCount: 3, progress: 0.6, isPunchedIn: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        Task { @MainActor in
            let stats = fetchTodayStats()
            let entry = SimpleEntry(date: Date(), tasksCount: stats.count, progress: stats.progress, isPunchedIn: stats.isPunchedIn)
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        Task { @MainActor in
            let stats = fetchTodayStats()
            let entry = SimpleEntry(date: Date(), tasksCount: stats.count, progress: stats.progress, isPunchedIn: stats.isPunchedIn)
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
    let isPunchedIn: Bool
}

struct AuraWidgetEntryView : View {
    @Environment(\.widgetFamily) var family
    var entry: Provider.Entry

    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                Gauge(value: entry.progress) {
                    Image(systemName: "bolt.fill")
                } currentValueLabel: {
                    Text("\(entry.tasksCount)")
                        .font(.headline)
                }
                .gaugeStyle(.accessoryCircular)
            }
            
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(.indigo)
                    Text("Aura Command")
                        .font(.headline)
                }
                Text("\(entry.tasksCount) tasks left • \(Int(entry.progress * 100))% done")
                    .font(.subheadline)
                
                Gauge(value: entry.progress) {}
                    .gaugeStyle(.accessoryLinear)
            }
            
        case .accessoryInline:
            Label("\(entry.tasksCount) Tasks • \(entry.isPunchedIn ? "Punched In" : "Out")", systemImage: "bolt.fill")
            
        default:
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Today")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Spacer()
                    if entry.isPunchedIn {
                        Text("OFFICE ACTIVE")
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .clipShape(Capsule())
                    }
                }
                
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
}

@main
struct AuraWidgetBundle: WidgetBundle {
    var body: some Widget {
        AuraWidget()
        LockScreenPunchWidget()
        QuickCaptureWidget()
        FocusLiveActivity()
    }
}

struct LockScreenPunchWidget: Widget {
    let kind: String = "LockScreenPunchWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Image(systemName: entry.isPunchedIn ? "building.2.crop.circle.fill" : "building.2")
                        .font(.headline)
                    Text(entry.isPunchedIn ? "Shift Active" : "Out of Office")
                        .font(.headline)
                }
                
                Button(intent: PunchInOutIntent()) {
                    Text(entry.isPunchedIn ? "Punch Out" : "Punch In")
                        .font(.caption.bold())
                }
                .buttonStyle(.plain)
            }
            .containerBackground(for: .widget) {
                Color.clear
            }
        }
        .configurationDisplayName("Interactive Office Punch")
        .description("Punch In or Out directly from your Lock Screen.")
        .supportedFamilies([.accessoryRectangular, .accessoryCircular, .systemSmall])
    }
}

struct QuickCaptureWidget: Widget {
    let kind: String = "QuickCaptureWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            VStack {
                Text("Capture Task")
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
        .supportedFamilies([.systemSmall, .accessoryCircular])
    }
}

struct AuraWidget: Widget {
    let kind: String = "AuraWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            AuraWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Today's Progress")
        .description("Track your daily task progress on Home or Lock Screen.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}
