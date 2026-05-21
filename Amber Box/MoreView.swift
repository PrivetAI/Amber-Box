import SwiftUI

/// More tab — hosts the existing Settings content (Audio/Haptics, How to Play, Privacy
/// Policy, About/Version, Reset Progress). The Settings/How-To previously reached from the
/// chapter map header now live here. `SettingsView` keeps its own How-To/Privacy sheets and
/// reset alert; MoreView is the NavigationView-hosted root for that content.
struct MoreView: View {
    var body: some View {
        SettingsView()
    }
}
