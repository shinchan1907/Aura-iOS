import SwiftUI
import SwiftData

@main
struct AuraApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var authManager = BiometricAuthManager.shared
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                
                if authManager.isLocked {
                    FaceIDLockOverlayView(authManager: authManager)
                        .transition(.opacity)
                        .zIndex(999)
                }
            }
            .onAppear {
                NotificationManager.shared.requestAuthorization()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .background {
                    authManager.lockIfNeeded()
                }
            }
        }
        .modelContainer(AuraSchema.modelContainer)
    }
}
