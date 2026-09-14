import SwiftUI

public struct AuraBackgroundView: View {
    @State private var animateMesh = false
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // Dark base background
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            // Dynamic Ambient Glowing Fluid Mesh Orbs
            GeometryReader { geo in
                ZStack {
                    // Orb 1: Cyber Violet Glow
                    Circle()
                        .fill(AuraColors.accent.opacity(0.25))
                        .frame(width: geo.size.width * 0.8, height: geo.size.width * 0.8)
                        .blur(radius: 70)
                        .offset(x: animateMesh ? -60 : 40, y: animateMesh ? -80 : 20)
                    
                    // Orb 2: Aurora Cyan Glow
                    Circle()
                        .fill(AuraColors.cyanAccent.opacity(0.20))
                        .frame(width: geo.size.width * 0.7, height: geo.size.width * 0.7)
                        .blur(radius: 65)
                        .offset(x: animateMesh ? 80 : -40, y: animateMesh ? 100 : -50)
                    
                    // Orb 3: Neon Rose / Amber Accent Glow
                    Circle()
                        .fill(AuraColors.urgent.opacity(0.15))
                        .frame(width: geo.size.width * 0.6, height: geo.size.width * 0.6)
                        .blur(radius: 60)
                        .offset(x: animateMesh ? -30 : 70, y: animateMesh ? 120 : 40)
                }
                .onAppear {
                    withAnimation(
                        .easeInOut(duration: 8.0)
                        .repeatForever(autoreverses: true)
                    ) {
                        animateMesh.toggle()
                    }
                }
            }
            .ignoresSafeArea()
            
            // Subtle noise overlay for glass texture depth
            Color.black.opacity(0.03)
                .ignoresSafeArea()
        }
    }
}
