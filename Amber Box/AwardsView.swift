import SwiftUI

/// Awards — stats strip + achievements grid. Filled in Phase 3; this is a minimal titled
/// placeholder so the tab shell compiles.
struct AwardsView: View {
    @EnvironmentObject var store: ABStore

    var body: some View {
        ZStack {
            ABBackground()
            VStack(spacing: 12) {
                Text("Awards")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(ABPalette.textPrimary)
                Text("Stats & achievements coming soon.")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(ABPalette.textSecondary)
            }
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .navigationBarHidden(true)
    }
}
