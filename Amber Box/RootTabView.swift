import SwiftUI

/// App shell: a custom HStack tab bar (NOT a TabView) over a `switch` on the selected tab.
/// Each tab hosts its own NavigationView so navigation state is isolated per tab.
struct RootTabView: View {
    @EnvironmentObject var store: ABStore
    @State private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                Group {
                    switch selectedTab {
                    case 0:
                        NavigationView { ChapterMapView() }
                            .navigationViewStyle(StackNavigationViewStyle())
                    case 1:
                        NavigationView { ChallengesView() }
                            .navigationViewStyle(StackNavigationViewStyle())
                    case 2:
                        NavigationView { AwardsView() }
                            .navigationViewStyle(StackNavigationViewStyle())
                    default:
                        NavigationView { MoreView() }
                            .navigationViewStyle(StackNavigationViewStyle())
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                tabBar
            }
        }
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            tabButton(0, "Play", AnyView(ABTabPlayIcon(color: tint(0), size: 24)))
            tabButton(1, "Challenges", AnyView(ABTabChallengeIcon(color: tint(1), size: 24)))
            tabButton(2, "Awards", AnyView(ABTabAwardsIcon(color: tint(2), size: 24)))
            tabButton(3, "More", AnyView(ABTabMoreIcon(color: tint(3), size: 24)))
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(ABPalette.panel.edgesIgnoringSafeArea(.bottom))
        .overlay(
            Rectangle()
                .fill(ABPalette.panelRaised.opacity(0.6))
                .frame(height: 1),
            alignment: .top
        )
    }

    private func tint(_ i: Int) -> Color { selectedTab == i ? ABPalette.accent : ABPalette.textMuted }

    private func tabButton(_ i: Int, _ label: String, _ icon: AnyView) -> some View {
        Button {
            selectedTab = i
        } label: {
            VStack(spacing: 3) {
                icon
                    .frame(height: 26)
                Text(label)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(tint(i))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}
