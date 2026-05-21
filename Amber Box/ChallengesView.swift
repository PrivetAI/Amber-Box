import SwiftUI

/// Challenges home — Daily / Packs / Endless live here. Filled in Phase 2; this is a
/// minimal titled placeholder so the tab shell compiles.
struct ChallengesView: View {
    @EnvironmentObject var store: ABStore

    var body: some View {
        ZStack {
            ABBackground()
            VStack(spacing: 12) {
                Text("Challenges")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(ABPalette.textPrimary)
                Text("Daily, Packs & Endless coming soon.")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(ABPalette.textSecondary)
            }
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .navigationBarHidden(true)
    }
}
