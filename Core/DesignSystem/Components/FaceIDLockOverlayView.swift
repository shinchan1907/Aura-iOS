import SwiftUI
import LocalAuthentication

public struct FaceIDLockOverlayView: View {
    @Bindable var authManager: BiometricAuthManager = BiometricAuthManager.shared
    @State private var isPulseAnimating = false
    
    public init(authManager: BiometricAuthManager = BiometricAuthManager.shared) {
        self.authManager = authManager
    }
    
    public var body: some View {
        ZStack {
            // Ultra blurred vibrant background
            AuraBackgroundView()
                .blur(radius: 30)
                .ignoresSafeArea()
            
            // Dark glass tint overlay
            Color.black.opacity(0.65)
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // App Logo & Lock Badge
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.accentColor.opacity(0.6), Color.purple.opacity(0.4)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .scaleEffect(isPulseAnimating ? 1.15 : 1.0)
                            .opacity(isPulseAnimating ? 0.8 : 0.4)
                            .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: isPulseAnimating)
                        
                        Image(systemName: authManager.biometricType == .faceID ? "faceid" : (authManager.biometricType == .touchID ? "touchid" : "lock.shield.fill"))
                            .font(.system(size: 48, weight: .light))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, Color.accentColor],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: Color.accentColor.opacity(0.8), radius: 12, x: 0, y: 0)
                    }
                    .onAppear {
                        isPulseAnimating = true
                    }
                    
                    VStack(spacing: 8) {
                        Text("Aura Locked")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Authentication required to access your workspace")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                }
                
                if let errorMsg = authManager.authError {
                    Text(errorMsg)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.red.opacity(0.9))
                        .padding(.horizontal, 24)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                // Unlock Button
                Button {
                    authManager.authenticate()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: authManager.biometricType == .faceID ? "faceid" : "key.fill")
                            .font(.system(size: 20, weight: .semibold))
                        Text(authManager.biometricType == .faceID ? "Unlock with Face ID" : "Unlock Aura")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.accentColor, Color.purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: Color.accentColor.opacity(0.5), radius: 15, x: 0, y: 8)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 36)
                .padding(.bottom, 48)
            }
        }
        .onAppear {
            authManager.authenticate()
        }
    }
}
