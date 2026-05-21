import SwiftUI

struct HowToPlayView: View {
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        ZStack {
            ABBackground()
            VStack(spacing: 0) {
                // header
                HStack {
                    Text("How to Play")
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundColor(ABPalette.textPrimary)
                    Spacer()
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        ZStack {
                            Circle().fill(ABPalette.panel).frame(width: 34, height: 34)
                            ABCloseShape()
                                .stroke(ABPalette.textSecondary, style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
                                .frame(width: 14, height: 14)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ruleCard(
                            art: AnyView(HStack(spacing: 10) {
                                ABWorkerShape().frame(width: 38, height: 38)
                            }),
                            title: "The Worker",
                            text: "You control one warehouse worker. Move one tile per step with the D-pad or by swiping across the board."
                        )
                        ruleCard(
                            art: AnyView(HStack(spacing: 4) {
                                ABWorkerShape().frame(width: 30, height: 30)
                                ABArrowShape().fill(ABPalette.accent).frame(width: 18, height: 18).rotationEffect(.degrees(90))
                                ABCrateShape().frame(width: 34, height: 34)
                            }),
                            title: "Pushing Rule",
                            text: "Move into a crate to push it forward one cell — but only when the tile beyond it is empty floor. Walls and other crates block the push. The worker can never pull."
                        )
                        ruleCard(
                            art: AnyView(ZStack {
                                ABPadShape().frame(width: 48, height: 48)
                                ABCrateShape(seated: true).frame(width: 34, height: 34)
                            }),
                            title: "Target Pads",
                            text: "Every teal ring is a target pad. Cover all of them with crates at once and the level is solved. Seated crates turn teal."
                        )
                        ruleCard(
                            art: AnyView(HStack(spacing: 14) {
                                ABUndoIcon(color: ABPalette.accent, size: 36)
                                ABRestartIcon(color: ABPalette.textSecondary, size: 36)
                            }),
                            title: "Undo & Restart",
                            text: "Undo rewinds your steps one at a time, even pushes. Restart resets the whole level. There is no way to lose — only to find the cleanest solution."
                        )
                        ruleCard(
                            art: AnyView(HStack(spacing: 4) {
                                ABStar(filled: true, size: 26)
                                ABStar(filled: true, size: 26)
                                ABStar(filled: true, size: 26)
                            }),
                            title: "Stars & Par",
                            text: "Solving a level earns 1★. Match 1.5× the par move count for 2★, and finish at par or better for 3★. Par is the depot's reference best."
                        )
                        Color.clear.frame(height: 8)
                    }
                    .padding(.horizontal, 20)
                    .frame(maxWidth: 560)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .preferredColorScheme(.light)
    }

    private func ruleCard(art: AnyView, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(ABPalette.panelRaised)
                    .frame(width: 64, height: 64)
                art
            }
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundColor(ABPalette.textPrimary)
                Text(text)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(ABPalette.textSecondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .abPanel()
    }
}

struct ABCloseShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        return p
    }
}
