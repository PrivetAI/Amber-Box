import SwiftUI

struct ChapterMapView: View {
    @EnvironmentObject var store: CPDStore
    @State private var showSettings = false
    @State private var showHowTo = false

    private let chapterNames = [
        "Loading Bay", "Cold Storage", "Pallet Yard",
        "Conveyor Wing", "High Racks", "Dispatch Hub"
    ]

    var body: some View {
        ZStack {
            CPDBackground()
            ScrollView {
                VStack(spacing: 18) {
                    header
                    ForEach(0..<CPDStore.chapters, id: \.self) { chapter in
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
        .background(
            NavigationLink(destination: SettingsView(), isActive: $showSettings) { EmptyView() }.hidden()
        )
        .sheet(isPresented: $showHowTo) {
            HowToPlayView()
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            CPDDepotMark(size: 46)
            VStack(alignment: .leading, spacing: 2) {
                Text("Crate Push Depot")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(CPDPalette.textPrimary)
                HStack(spacing: 6) {
                    CPDStar(filled: true, size: 13)
                    Text("\(store.totalStars) / \(CPDStore.totalLevels * 3) stars")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(CPDPalette.textSecondary)
                }
            }
            Spacer()
            Button {
                showHowTo = true
            } label: {
                ZStack {
                    Circle().fill(CPDPalette.panel).frame(width: 40, height: 40)
                    Text("?")
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundColor(CPDPalette.textSecondary)
                }
            }
            Button {
                showSettings = true
            } label: {
                ZStack {
                    Circle().fill(CPDPalette.panel).frame(width: 40, height: 40)
                    CPDGearIcon(color: CPDPalette.textSecondary, size: 22)
                }
            }
        }
        .padding(.vertical, 6)
    }

    private func chapterCard(_ chapter: Int) -> some View {
        let unlocked = store.isChapterUnlocked(chapter)
        let stars = store.stars(forChapter: chapter)
        let maxStars = CPDStore.levelsPerChapter * 3
        let solvedCount = chapterSolvedCount(chapter)

        return NavigationLink(destination: LevelSelectView(chapter: chapter)) {
            HStack(spacing: 16) {
                // chapter emblem
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(unlocked ? CPDPalette.panelRaised : CPDPalette.panel.opacity(0.6))
                        .frame(width: 64, height: 64)
                    if unlocked {
                        chapterEmblem(chapter)
                            .frame(width: 40, height: 40)
                    } else {
                        CPDLockIcon(color: CPDPalette.lock, size: 30)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Chapter \(chapter + 1)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(CPDPalette.accent)
                    Text(chapterNames[chapter])
                        .font(.system(size: 19, weight: .heavy, design: .rounded))
                        .foregroundColor(unlocked ? CPDPalette.textPrimary : CPDPalette.textMuted)
                    if unlocked {
                        HStack(spacing: 8) {
                            CPDStar(filled: true, size: 13)
                            Text("\(stars) / \(maxStars)")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(CPDPalette.textSecondary)
                            Text("•")
                                .foregroundColor(CPDPalette.textMuted)
                            Text("\(solvedCount)/\(CPDStore.levelsPerChapter) solved")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(CPDPalette.textSecondary)
                        }
                    } else {
                        Text("Earn 30★ in Chapter \(chapter) to unlock")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(CPDPalette.textMuted)
                    }
                }
                Spacer()
                if unlocked {
                    CPDChevron(color: CPDPalette.textSecondary, size: 22)
                }
            }
            .padding(16)
            .cpdPanel()
            .overlay(
                RoundedRectangle(cornerRadius: CPDMetrics.corner, style: .continuous)
                    .stroke(unlocked ? CPDPalette.accent.opacity(0.18) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .disabled(!unlocked)
    }

    private func chapterSolvedCount(_ chapter: Int) -> Int {
        let start = chapter * CPDStore.levelsPerChapter
        var count = 0
        for i in start..<(start + CPDStore.levelsPerChapter) {
            if store.progress(for: i).solved { count += 1 }
        }
        return count
    }

    @ViewBuilder
    private func chapterEmblem(_ chapter: Int) -> some View {
        switch chapter {
        case 0: CPDCrateShape()
        case 1: CPDCrateShape(seated: true)
        case 2: CPDPadShape()
        case 3: CPDGearIcon(color: CPDPalette.accent, size: 36)
        case 4:
            VStack(spacing: 2) {
                CPDCrateShape().frame(width: 24, height: 16)
                CPDCrateShape().frame(width: 24, height: 16)
            }
        default: CPDWorkerShape()
        }
    }
}
