import SwiftUI

/// More tab — hosts the existing Settings content (Audio/Haptics, How to Play, Privacy,
/// Reset). Fleshed out in Task 1.4; minimal placeholder for the tab shell.
struct MoreView: View {
    @EnvironmentObject var store: ABStore

    var body: some View {
        ZStack {
            ABBackground()
            Text("More")
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundColor(ABPalette.textPrimary)
        }
        .navigationBarHidden(true)
    }
}
