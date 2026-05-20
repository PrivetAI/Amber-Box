import SwiftUI

// Splash shown while the launch check runs.
struct CratePushDepotLoadingScreen: View {
    @State private var spin = false
    @State private var pulse = false

    var body: some View {
        ZStack {
            CPDBackground()
            VStack(spacing: 28) {
                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(CPDPalette.panel)
                        .frame(width: 132, height: 132)
                    CPDGearShape()
                        .fill(style: FillStyle(eoFill: true))
                        .foregroundColor(CPDPalette.accent.opacity(0.35))
                        .frame(width: 110, height: 110)
                        .rotationEffect(.degrees(spin ? 360 : 0))
                    CPDCrateShape()
                        .frame(width: 64, height: 64)
                        .scaleEffect(pulse ? 1.06 : 0.94)
                }
                Text("CRATE PUSH DEPOT")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .tracking(2)
                    .foregroundColor(CPDPalette.textPrimary)
                Text("Loading depot…")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(CPDPalette.textSecondary)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 2.4).repeatForever(autoreverses: false)) { spin = true }
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) { pulse = true }
        }
    }
}
