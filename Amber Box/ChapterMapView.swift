import SwiftUI

struct ChapterMapView: View {
    @EnvironmentObject var store: ABStore

    private let chapterNames = [
        "Loading Bay", "Cold Storage", "Pallet Yard",
        "Conveyor Wing", "High Racks", "Dispatch Hub"
    ]

    var body: some View {
        ZStack {
            ABBackground()
            ScrollView {
                VStack(spacing: 18) {
                    header
                    ForEach(0..<ABStore.chapters, id: \.self) { chapter in
                        chapterCard(chapter)
                    }
                    Color.clear.frame(height: 8)
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationBarTitle("", displayMode: .inline)
        .navigationBarHidden(true)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            ABDepotMark(size: 46)
            VStack(alignment: .leading, spacing: 2) {
                Text("Amber Box")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(ABPalette.textPrimary)
                HStack(spacing: 6) {
                    ABStar(filled: true, size: 13)
                    Text("\(store.totalStars) / \(ABStore.totalLevels * 3) stars")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(ABPalette.textSecondary)
                }
            }
            Spacer()
        }
        .padding(.vertical, 6)
    }

    private func chapterCard(_ chapter: Int) -> some View {
        let unlocked = store.isChapterUnlocked(chapter)
        let stars = store.stars(forChapter: chapter)
        let maxStars = ABStore.levelsPerChapter * 3
        let solvedCount = chapterSolvedCount(chapter)

        return NavigationLink(destination: LevelSelectView(chapter: chapter)) {
            HStack(spacing: 16) {
                // chapter emblem
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(unlocked ? ABPalette.panelRaised : ABPalette.panel.opacity(0.6))
                        .frame(width: 64, height: 64)
                    if unlocked {
                        chapterEmblem(chapter)
                            .frame(width: 40, height: 40)
                    } else {
                        ABLockIcon(color: ABPalette.lock, size: 30)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Chapter \(chapter + 1)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(ABPalette.accent)
                    Text(chapterNames[chapter])
                        .font(.system(size: 19, weight: .heavy, design: .rounded))
                        .foregroundColor(unlocked ? ABPalette.textPrimary : ABPalette.textMuted)
                    if unlocked {
                        HStack(spacing: 8) {
                            ABStar(filled: true, size: 13)
                            Text("\(stars) / \(maxStars)")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(ABPalette.textSecondary)
                            Text("•")
                                .foregroundColor(ABPalette.textMuted)
                            Text("\(solvedCount)/\(ABStore.levelsPerChapter) solved")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(ABPalette.textSecondary)
                        }
                    } else {
                        Text("Earn 30★ in Chapter \(chapter) to unlock")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(ABPalette.textMuted)
                    }
                }
                Spacer()
                if unlocked {
                    ABChevron(color: ABPalette.textSecondary, size: 22)
                }
            }
            .padding(16)
            .abPanel()
            .overlay(
                RoundedRectangle(cornerRadius: ABMetrics.corner, style: .continuous)
                    .stroke(unlocked ? ABPalette.accent.opacity(0.18) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .disabled(!unlocked)
    }

    private func chapterSolvedCount(_ chapter: Int) -> Int {
        let start = chapter * ABStore.levelsPerChapter
        var count = 0
        for i in start..<(start + ABStore.levelsPerChapter) {
            if store.progress(for: i).solved { count += 1 }
        }
        return count
    }

    @ViewBuilder
    private func chapterEmblem(_ chapter: Int) -> some View {
        switch chapter {
        case 0: ABCrateShape()
        case 1: ABCrateShape(seated: true)
        case 2: ABPadShape()
        case 3: ABGearIcon(color: ABPalette.accent, size: 36)
        case 4:
            VStack(spacing: 2) {
                ABCrateShape().frame(width: 24, height: 16)
                ABCrateShape().frame(width: 24, height: 16)
            }
        default: ABWorkerShape()
        }
    }
}
