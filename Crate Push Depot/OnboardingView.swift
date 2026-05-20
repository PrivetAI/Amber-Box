import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var store: CPDStore
    @Binding var isPresented: Bool
    @State private var step = 0

    private let steps: [(title: String, body: String)] = [
        ("Move the Worker", "Tap the D-pad arrows or swipe on the board to move your worker one tile at a time — up, down, left, or right."),
        ("Push the Crates", "Walk into a crate to push it one cell ahead. It only moves if the next tile is empty floor. You can never pull a crate back."),
        ("Cover Every Pad", "Each teal ring is a target pad. Slide every amber crate onto a pad to clear the depot and finish the level."),
        ("Undo Anytime", "Pushed yourself into a corner? Use Undo to step back move by move, or Restart to reset the whole level.")
    ]

    var body: some View {
        ZStack {
            CPDPalette.backgroundDeep.opacity(0.97).ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button {
                        finish()
                    } label: {
                        Text("Skip")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(CPDPalette.textSecondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                    }
                }
                .padding(.top, 8)
                .padding(.horizontal, 12)

                Spacer()

                stepArt(step)
                    .frame(width: 180, height: 180)
                    .padding(.bottom, 28)

                Text(steps[step].title)
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundColor(CPDPalette.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)

                Text(steps[step].body)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(CPDPalette.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 32)
                    .padding(.top, 12)
                    .frame(maxWidth: 460)

                Spacer()

                // dots
                HStack(spacing: 8) {
                    ForEach(0..<steps.count, id: \.self) { i in
                        Capsule()
                            .fill(i == step ? CPDPalette.accent : CPDPalette.panelRaised)
                            .frame(width: i == step ? 22 : 8, height: 8)
                    }
                }
                .padding(.bottom, 20)

                Button {
                    if step < steps.count - 1 {
                        withAnimation(.easeInOut(duration: 0.2)) { step += 1 }
                    } else {
                        finish()
                    }
                } label: {
                    Text(step < steps.count - 1 ? "Next" : "Start Pushing")
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                        .foregroundColor(CPDPalette.backgroundDeep)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(CPDPalette.accent)
                        )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 28)
                .frame(maxWidth: 460)
                .padding(.bottom, 28)
            }
        }
    }

    private func finish() {
        store.markOnboardingDone()
        withAnimation(.easeInOut(duration: 0.25)) { isPresented = false }
    }

    @ViewBuilder
    private func stepArt(_ step: Int) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(CPDPalette.panel)
            switch step {
            case 0:
                // worker + d-pad arrows
                HStack(spacing: 16) {
                    CPDWorkerShape().frame(width: 56, height: 56)
                    VStack(spacing: 4) {
                        CPDArrowShape().fill(CPDPalette.accent).frame(width: 22, height: 22)
                        HStack(spacing: 4) {
                            CPDArrowShape().fill(CPDPalette.accent).frame(width: 22, height: 22).rotationEffect(.degrees(270))
                            CPDArrowShape().fill(CPDPalette.accent).frame(width: 22, height: 22).rotationEffect(.degrees(90))
                        }
                        CPDArrowShape().fill(CPDPalette.accent).frame(width: 22, height: 22).rotationEffect(.degrees(180))
                    }
                }
            case 1:
                // worker pushing crate -> arrow
                HStack(spacing: 8) {
                    CPDWorkerShape().frame(width: 44, height: 44)
                    CPDArrowShape().fill(CPDPalette.accent).frame(width: 26, height: 26).rotationEffect(.degrees(90))
                    CPDCrateShape().frame(width: 50, height: 50)
                }
            case 2:
                // crate seated on pad
                ZStack {
                    CPDPadShape().frame(width: 90, height: 90)
                    CPDCrateShape(seated: true).frame(width: 64, height: 64)
                }
            default:
                HStack(spacing: 18) {
                    CPDUndoIcon(color: CPDPalette.accent, size: 56)
                    CPDRestartIcon(color: CPDPalette.textSecondary, size: 56)
                }
            }
        }
    }
}
