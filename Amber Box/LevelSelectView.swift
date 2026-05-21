import SwiftUI

struct LevelSelectView: View {
    @EnvironmentObject var store: ABStore
    let chapter: Int

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)

    var body: some View {
        ZStack {
            ABBackground()
            ScrollView {
                VStack(spacing: 16) {
                    headerRow
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(0..<ABStore.levelsPerChapter, id: \.self) { within in
                            levelCell(within)
                        }
                    }
                    Color.clear.frame(height: 8)
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationBarTitle("Chapter \(chapter + 1)", displayMode: .inline)
    }

    private var headerRow: some View {
        let stars = store.stars(forChapter: chapter)
        let maxStars = ABStore.levelsPerChapter * 3
        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Select a Level")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundColor(ABPalette.textPrimary)
                HStack(spacing: 6) {
                    ABStar(filled: true, size: 13)
                    Text("\(stars) / \(maxStars)")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(ABPalette.textSecondary)
                }
            }
            Spacer()
        }
        .padding(16)
        .abPanel()
    }

    private func levelCell(_ within: Int) -> some View {
        let globalIndex = chapter * ABStore.levelsPerChapter + within
        let p = store.progress(for: globalIndex)

        return NavigationLink(destination: GameView(levelIndex: globalIndex)) {
            VStack(spacing: 6) {
                Text("\(within + 1)")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(p.solved ? ABPalette.textPrimary : ABPalette.textSecondary)
                HStack(spacing: 2) {
                    ForEach(0..<3, id: \.self) { i in
                        ABStar(filled: i < p.stars, size: 11)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 74)
            .background(
                RoundedRectangle(cornerRadius: ABMetrics.cornerSmall, style: .continuous)
                    .fill(p.solved ? ABPalette.panelRaised : ABPalette.panel)
            )
            .overlay(
                RoundedRectangle(cornerRadius: ABMetrics.cornerSmall, style: .continuous)
                    .stroke(p.stars == 3 ? ABPalette.star.opacity(0.5) : ABPalette.panelRaised.opacity(0.6), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
