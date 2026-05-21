import SwiftUI

// Industrial depot palette — slate / steel-blue, amber crates, teal pads, dark walls, warm accent.
enum ABPalette {
    static let background = Color(red: 0.16, green: 0.20, blue: 0.27)      // slate
    static let backgroundDeep = Color(red: 0.11, green: 0.14, blue: 0.20)  // deeper slate
    static let panel = Color(red: 0.22, green: 0.27, blue: 0.35)           // steel-blue panel
    static let panelRaised = Color(red: 0.27, green: 0.33, blue: 0.42)
    static let floor = Color(red: 0.30, green: 0.36, blue: 0.44)           // board floor
    static let floorAlt = Color(red: 0.27, green: 0.33, blue: 0.41)
    static let gridLine = Color(red: 0.20, green: 0.25, blue: 0.32)

    static let wall = Color(red: 0.13, green: 0.16, blue: 0.21)            // dark walls
    static let wallEdge = Color(red: 0.08, green: 0.10, blue: 0.14)

    static let crate = Color(red: 0.93, green: 0.62, blue: 0.18)           // amber
    static let crateDark = Color(red: 0.76, green: 0.47, blue: 0.10)
    static let crateLight = Color(red: 0.98, green: 0.74, blue: 0.34)
    static let crateOnPad = Color(red: 0.46, green: 0.78, blue: 0.62)      // amber-teal blend when seated

    static let pad = Color(red: 0.25, green: 0.74, blue: 0.70)             // teal target pad
    static let padGlow = Color(red: 0.40, green: 0.86, blue: 0.80)

    static let worker = Color(red: 0.96, green: 0.83, blue: 0.46)          // warm accent body
    static let workerDark = Color(red: 0.84, green: 0.66, blue: 0.28)
    static let workerVisor = Color(red: 0.18, green: 0.30, blue: 0.40)

    static let accent = Color(red: 0.95, green: 0.61, blue: 0.24)          // warm accent
    static let accentDeep = Color(red: 0.84, green: 0.46, blue: 0.16)

    static let textPrimary = Color(red: 0.93, green: 0.95, blue: 0.97)
    static let textSecondary = Color(red: 0.66, green: 0.72, blue: 0.80)
    static let textMuted = Color(red: 0.48, green: 0.55, blue: 0.64)

    static let star = Color(red: 0.98, green: 0.78, blue: 0.32)
    static let starEmpty = Color(red: 0.34, green: 0.40, blue: 0.49)
    static let lock = Color(red: 0.42, green: 0.49, blue: 0.58)
    static let success = Color(red: 0.40, green: 0.82, blue: 0.62)
}

enum ABMetrics {
    static let corner: CGFloat = 16
    static let cornerSmall: CGFloat = 10
}

// Reusable raised panel background.
struct ABPanel: ViewModifier {
    var corner: CGFloat = ABMetrics.corner
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(ABPalette.panel)
                    .overlay(
                        RoundedRectangle(cornerRadius: corner, style: .continuous)
                            .stroke(ABPalette.panelRaised, lineWidth: 1)
                    )
            )
    }
}

extension View {
    func abPanel(corner: CGFloat = ABMetrics.corner) -> some View {
        modifier(ABPanel(corner: corner))
    }
}

// Background gradient used across screens.
struct ABBackground: View {
    var body: some View {
        LinearGradient(
            colors: [ABPalette.background, ABPalette.backgroundDeep],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}
