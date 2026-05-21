import SwiftUI

// Splash shown while the launch check runs.
struct AmberBoxLoadingScreen: View {
    @State private var spin = false
    @State private var pulse = false

    var body: some View {
        ZStack {
            ABBackground()
            VStack(spacing: 28) {
                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(ABPalette.panel)
                        .frame(width: 132, height: 132)
                    ABGearShape()
                        .fill(style: FillStyle(eoFill: true))
                        .foregroundColor(ABPalette.accent.opacity(0.35))
                        .frame(width: 110, height: 110)
                        .rotationEffect(.degrees(spin ? 360 : 0))
                    ABCrateShape()
                        .frame(width: 64, height: 64)
                        .scaleEffect(pulse ? 1.06 : 0.94)
                }
                Text("AMBER BOX")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .tracking(2)
                    .foregroundColor(ABPalette.textPrimary)
                Text("Loading depot…")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(ABPalette.textSecondary)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 2.4).repeatForever(autoreverses: false)) { spin = true }
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) { pulse = true }
        }
    }
}
