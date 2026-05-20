import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: CPDStore
    @State private var showPrivacy = false
    @State private var showResetAlert = false
    @State private var showHowTo = false

    private let privacyURL = "https://example.com"

    var body: some View {
        ZStack {
            CPDBackground()
            ScrollView {
                VStack(spacing: 16) {
                    sectionCard(title: "Audio & Feedback") {
                        toggleRow(title: "Sound", isOn: Binding(
                            get: { store.settings.soundOn },
                            set: { store.settings.soundOn = $0; store.saveSettings() }
                        ))
                        divider
                        toggleRow(title: "Haptics", isOn: Binding(
                            get: { store.settings.hapticsOn },
                            set: { store.settings.hapticsOn = $0; store.saveSettings() }
                        ))
                    }

                    sectionCard(title: "Help") {
                        tapRow(title: "How to Play") { showHowTo = true }
                    }

                    sectionCard(title: "About") {
                        tapRow(title: "Privacy Policy") { showPrivacy = true }
                        divider
                        infoRow(title: "Version", value: "1.0")
                    }

                    sectionCard(title: "Progress") {
                        Button {
                            showResetAlert = true
                        } label: {
                            HStack {
                                Text("Reset All Progress")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(CPDPalette.accentDeep)
                                Spacer()
                            }
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }

                    HStack(spacing: 6) {
                        CPDStar(filled: true, size: 12)
                        Text("\(store.totalStars) / \(CPDStore.totalLevels * 3) stars earned")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(CPDPalette.textMuted)
                    }
                    .padding(.top, 4)

                    Color.clear.frame(height: 8)
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationBarTitle("Settings", displayMode: .inline)
        .sheet(isPresented: $showPrivacy) {
            CratePushDepotWebPanel(cratePushDepotURLString: privacyURL)
                .edgesIgnoringSafeArea(.all)
        }
        .sheet(isPresented: $showHowTo) {
            HowToPlayView()
        }
        .alert(isPresented: $showResetAlert) {
            Alert(
                title: Text("Reset Progress?"),
                message: Text("This permanently clears all stars and best scores for every level. This cannot be undone."),
                primaryButton: .destructive(Text("Reset")) {
                    store.resetProgress()
                },
                secondaryButton: .cancel()
            )
        }
    }

    // MARK: - Building blocks

    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(1.2)
                .foregroundColor(CPDPalette.textMuted)
                .padding(.bottom, 8)
                .padding(.leading, 4)
            VStack(spacing: 0) {
                content()
            }
            .padding(.horizontal, 16)
            .cpdPanel()
        }
    }

    private func toggleRow(title: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(CPDPalette.textPrimary)
            Spacer()
            CPDToggle(isOn: isOn)
        }
        .padding(.vertical, 12)
    }

    private func tapRow(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(CPDPalette.textPrimary)
                Spacer()
                CPDChevron(color: CPDPalette.textMuted, size: 18)
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(CPDPalette.textPrimary)
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(CPDPalette.textSecondary)
        }
        .padding(.vertical, 12)
    }

    private var divider: some View {
        Rectangle()
            .fill(CPDPalette.panelRaised.opacity(0.6))
            .frame(height: 1)
    }
}

// Custom toggle (no native styling reliance — themed track + knob).
struct CPDToggle: View {
    @Binding var isOn: Bool
    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.16)) { isOn.toggle() }
        } label: {
            ZStack(alignment: isOn ? .trailing : .leading) {
                Capsule()
                    .fill(isOn ? CPDPalette.success : CPDPalette.panelRaised)
                    .frame(width: 50, height: 30)
                Circle()
                    .fill(Color.white)
                    .frame(width: 24, height: 24)
                    .padding(.horizontal, 3)
            }
        }
        .buttonStyle(.plain)
    }
}
