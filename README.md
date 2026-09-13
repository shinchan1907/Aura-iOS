# Aura - Premium iOS Task Management

Aura is an Apple Design Award-quality iOS productivity and execution system. It is built natively for iOS 17.0+ using SwiftUI, SwiftData, ActivityKit, and WidgetKit.

## Core Features
- **Frictionless Inbox**: Natural Language Parsing for lightning-fast task capture.
- **Intelligent Command Center**: A Today view that surfaces your single most important "Focus Now" task.
- **Deep Work Integration**: Full Focus Session tracking via ActivityKit Live Activities and the Dynamic Island.
- **Immutable Task Journey**: A beautiful timeline visually mapping the entire lifecycle of a task without overwriting historical data.
- **Actionable Notifications**: Time-sensitive, contextual reminders powered by `UNUserNotificationCenter`.
- **Insight-Driven Analytics**: Native SwiftUI Charts visualizing your productivity trends and providing non-judgmental behavioral insights.

## Architecture
The repository uses a strict MVVM and modular folder structure:
- `App/`: Main entry point and environment injection.
- `Core/`: DesignSystem (Typography, Colors, Haptics) and SwiftData Schema (TaskItem, TaskHistory, FocusSession, Project).
- `Features/`: Feature boundaries for Inbox, Today, Analytics, and TaskDetail.
- `Intents/`: App Intents (e.g., Quick Capture, Pause/Complete Focus).
- `LiveActivities/`: ActivityKit implementations for Dynamic Island.
- `Widgets/`: WidgetKit bundle containing Lock Screen and Home Screen widgets.

## Development Workflow (XcodeGen & GitHub Actions)
Because this project may be developed on a Windows machine, the Xcode project file (`Aura.xcodeproj`) is deliberately **not** committed to source control.

Instead, the project uses [XcodeGen](https://github.com/yonaskolb/XcodeGen) to define the targets and capabilities in `project.yml`.

### Building Locally (on macOS)
1. Install XcodeGen: `brew install xcodegen`
2. Generate the Xcode project: `xccodegen generate`
3. Open `Aura.xcodeproj` and hit Run.

### Continuous Integration
Aura includes a GitHub Actions workflow (`.github/workflows/ios.yml`) that automatically generates the Xcode project and compiles the application on a macOS runner for every push and pull request.

## Installation & Release
Please see [RELEASE.md](RELEASE.md) for explicit instructions on how to install Aura on a physical iPhone using TestFlight or ad-hoc provisioning.
