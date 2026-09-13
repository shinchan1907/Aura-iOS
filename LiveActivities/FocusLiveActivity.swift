import ActivityKit
import WidgetKit
import SwiftUI

public struct FocusAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var sessionState: SessionState
        public var elapsedSeconds: Int
        public var totalEstimatedSeconds: Int?
        
        public init(sessionState: SessionState, elapsedSeconds: Int, totalEstimatedSeconds: Int? = nil) {
            self.sessionState = sessionState
            self.elapsedSeconds = elapsedSeconds
            self.totalEstimatedSeconds = totalEstimatedSeconds
        }
    }
    
    public enum SessionState: String, Codable, Hashable {
        case active = "Active"
        case paused = "Paused"
        case approachingTarget = "Approaching Target"
        case completed = "Completed"
    }
    
    public var taskTitle: String
    
    public init(taskTitle: String) {
        self.taskTitle = taskTitle
    }
}

public struct FocusLiveActivity: Widget {
    public init() {}
    
    public var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusAttributes.self) { context in
            // Lock Screen Presentation
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: iconForState(context.state.sessionState))
                        .foregroundColor(colorForState(context.state.sessionState))
                    Text(context.attributes.taskTitle)
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    Text(context.state.sessionState.rawValue)
                        .font(.subheadline.bold())
                        .foregroundColor(colorForState(context.state.sessionState))
                }
                
                HStack {
                    Text(formatSeconds(context.state.elapsedSeconds))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    if let target = context.state.totalEstimatedSeconds {
                        Text("/ \(formatSeconds(target))")
                            .font(.title3)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // Contextual Controls
                    if context.state.sessionState == .active {
                        Button(intent: PauseFocusIntent()) {
                            Image(systemName: "pause.fill")
                                .padding()
                                .background(Color.white.opacity(0.2))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    } else if context.state.sessionState == .paused {
                        Button(intent: ResumeFocusIntent()) {
                            Image(systemName: "play.fill")
                                .padding()
                                .background(Color.white.opacity(0.2))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Button(intent: CompleteFocusIntent()) {
                        Image(systemName: "checkmark")
                            .padding()
                            .background(Color.green.opacity(0.2))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .activityBackgroundTint(Color.black.opacity(0.6))
            
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded
                DynamicIslandExpandedRegion(.leading) {
                    HStack {
                        Image(systemName: iconForState(context.state.sessionState))
                            .foregroundColor(colorForState(context.state.sessionState))
                        Text("Focus")
                            .font(.caption)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(formatSeconds(context.state.elapsedSeconds))
                        .font(.headline.monospacedDigit())
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack {
                        Text(context.attributes.taskTitle)
                            .font(.headline)
                            .lineLimit(1)
                        
                        HStack {
                            if context.state.sessionState == .active {
                                Button(intent: PauseFocusIntent()) {
                                    Label("Pause", systemImage: "pause.fill")
                                }
                            } else {
                                Button(intent: ResumeFocusIntent()) {
                                    Label("Resume", systemImage: "play.fill")
                                }
                            }
                            Button(intent: CompleteFocusIntent()) {
                                Label("Done", systemImage: "checkmark")
                            }
                        }
                        .padding(.top, 4)
                    }
                }
            } compactLeading: {
                Image(systemName: iconForState(context.state.sessionState))
                    .foregroundColor(colorForState(context.state.sessionState))
            } compactTrailing: {
                Text(formatSeconds(context.state.elapsedSeconds))
                    .font(.caption2.monospacedDigit())
            } minimal: {
                Image(systemName: "bolt.fill")
                    .foregroundColor(colorForState(context.state.sessionState))
            }
        }
    }
    
    private func colorForState(_ state: FocusAttributes.SessionState) -> Color {
        switch state {
        case .active: return .indigo
        case .paused: return .orange
        case .approachingTarget: return .red
        case .completed: return .green
        }
    }
    
    private func iconForState(_ state: FocusAttributes.SessionState) -> String {
        switch state {
        case .active: return "bolt.fill"
        case .paused: return "pause.circle.fill"
        case .approachingTarget: return "flame.fill"
        case .completed: return "checkmark.circle.fill"
        }
    }
    
    private func formatSeconds(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}
