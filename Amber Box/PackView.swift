import SwiftUI

// MARK: - Pack metadata + profiles

/// Static description of a difficulty pack: id, display name, tier (1...4 for emblem), accent
/// tint, and the fixed `ABDifficultyProfile` every level in the pack is generated from.
struct ABPack: Identifiable {
    let id: String
    let name: String
    let blurb: String
    let tier: Int
    let tint: Color
    let profile: ABDifficultyProfile

    /// Ordinal (0-based) used in seed derivation so each pack's levels are deterministic and
    /// distinct from other packs.
    var ordinal: Int { ABPackCatalog.all.firstIndex(where: { $0.id == id }) ?? 0 }
}

enum ABPackCatalog {
    /// Fixed profiles. Relaxed = small/few/shallow; Brutal = large/many/deep. Order matches
    /// `ABStore.packIDs`.
    static let all: [ABPack] = [
        ABPack(id: "relaxed",  name: "Relaxed",  blurb: "Roomy floors, gentle puzzles",
               tier: 1, tint: ABPalette.success,
               profile: ABDifficultyProfile(gridSize: 6,  crates: 2, scrambleDepth: 14, wallDensity: 0.04)),
        ABPack(id: "standard", name: "Standard", blurb: "A balanced warehouse shift",
               tier: 2, tint: ABPalette.pad,
               profile: ABDifficultyProfile(gridSize: 8,  crates: 3, scrambleDepth: 30, wallDensity: 0.08)),
        ABPack(id: "tough",    name: "Tough",    blurb: "Tight aisles, heavy loads",
               tier: 3, tint: ABPalette.accent,
               profile: ABDifficultyProfile(gridSize: 9,  crates: 5, scrambleDepth: 52, wallDensity: 0.11)),
        ABPack(id: "brutal",   name: "Brutal",   blurb: "Maximum crates, deepest tangles",
               tier: 4, tint: ABPalette.crateDark,
               profile: ABDifficultyProfile(gridSize: 10, crates: 7, scrambleDepth: 80, wallDensity: 0.14)),
    ]

    static func pack(_ id: String) -> ABPack {
        all.first(where: { $0.id == id }) ?? all[0]
    }

    /// Deterministic, pack- and index-specific seed (SplitMix64 mixed; never Hasher/hashValue).
    static func seed(packOrdinal: Int, index: Int) -> UInt64 {
        ABSplitMix64.mix(UInt64(packOrdinal) &* 100_003 &+ UInt64(index) &+ 1)
    }

    /// Build the level for a pack position, populating `ABLevel.index` with the in-pack index.
    static func level(for pack: ABPack, index: Int) -> ABLevel {
        ABLevelGenerator.generate(profile: pack.profile,
                                  seed: seed(packOrdinal: pack.ordinal, index: index),
                                  levelIndex: index)
    }
}

// MARK: - Pack list

struct PackListView: View {
    @EnvironmentObject var store: ABStore

    var body: some View {
        ZStack {
            ABBackground()
            ScrollView {
                VStack(spacing: 14) {
                    ForEach(ABPackCatalog.all) { pack in
                        packCard(pack)
                    }
                    Color.clear.frame(height: 8)
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationBarTitle("Difficulty Packs", displayMode: .inline)
    }

    private func packCard(_ pack: ABPack) -> some View {
        let solved = store.packSolvedCount(pack.id)
        let stars = store.packStars(pack.id)
        let maxStars = ABStore.packLevelCount * 3

        return NavigationLink(destination: PackLevelSelectView(packID: pack.id)) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(ABPalette.panelRaised)
                        .frame(width: 64, height: 64)
                    ABPackEmblem(tier: pack.tier, tint: pack.tint, size: 34)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(pack.name)
                        .font(.system(size: 19, weight: .heavy, design: .rounded))
                        .foregroundColor(ABPalette.textPrimary)
                    Text(pack.blurb)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(ABPalette.textMuted)
                    HStack(spacing: 8) {
                        ABStar(filled: true, size: 13)
                        Text("\(stars) / \(maxStars)")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(ABPalette.textSecondary)
                        Text("•")
                            .foregroundColor(ABPalette.textMuted)
                        Text("\(solved)/\(ABStore.packLevelCount) solved")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(ABPalette.textSecondary)
                    }
                }
                Spacer()
                ABChevron(color: ABPalette.textSecondary, size: 22)
            }
            .padding(16)
            .abPanel()
            .overlay(
                RoundedRectangle(cornerRadius: ABMetrics.corner, style: .continuous)
                    .stroke(pack.tint.opacity(0.22), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Pack level grid (mirrors LevelSelectView)

struct PackLevelSelectView: View {
    @EnvironmentObject var store: ABStore
    let packID: String

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)
    private var pack: ABPack { ABPackCatalog.pack(packID) }

    var body: some View {
        ZStack {
            ABBackground()
            ScrollView {
                VStack(spacing: 16) {
                    headerRow
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(0..<ABStore.packLevelCount, id: \.self) { idx in
                            levelCell(idx)
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
        .navigationBarTitle(pack.name, displayMode: .inline)
    }

    private var headerRow: some View {
        let stars = store.packStars(packID)
        let maxStars = ABStore.packLevelCount * 3
        return HStack(spacing: 12) {
            ABPackEmblem(tier: pack.tier, tint: pack.tint, size: 30)
            VStack(alignment: .leading, spacing: 4) {
                Text(pack.blurb)
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
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

    private func levelCell(_ idx: Int) -> some View {
        let p = store.packProgress(forPack: packID, index: idx)

        return NavigationLink(destination: packGame(at: idx)) {
            VStack(spacing: 6) {
                Text("\(idx + 1)")
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

    /// A pack session starting at `idx`. Because GameView reuses one `onSolved`/`nextProvider`
    /// pair for every level it chains to, we share an `ABRunCursor`: `onSolved` records at the
    /// cursor (exactly once per level — GameView guards it) then advances it; `nextProvider`
    /// purely reads the (already-advanced) cursor, so repeated SwiftUI evaluations are safe.
    private func packGame(at idx: Int) -> some View {
        let pk = pack
        let id = packID
        let cursor = ABRunCursor(index: idx)
        let first = ABPackCatalog.level(for: pk, index: idx)
        return GameView(
            level: first,
            par: first.par,
            source: .pack(id: id, index: idx),
            onSolved: { moves, usedUndo, pushes in
                let here = cursor.index
                let lvl = ABPackCatalog.level(for: pk, index: here)
                store.recordSolve(source: .pack(id: id, index: here),
                                  moves: moves, par: lvl.par,
                                  usedUndo: usedUndo, pushes: pushes)
                cursor.index = here + 1
            },
            nextProvider: {
                let nextIdx = cursor.index
                guard nextIdx < ABStore.packLevelCount else { return nil }
                let lvl = ABPackCatalog.level(for: pk, index: nextIdx)
                return (level: lvl, par: lvl.par, source: .pack(id: id, index: nextIdx))
            }
        )
    }
}

// MARK: - Run cursor (shared advancing position for chained GameView sessions)

/// Reference holder for the current position of a chained run (packs / endless). Lets a single
/// `onSolved`/`nextProvider` pair — which GameView reuses for every level it advances to —
/// stay correct: `onSolved` records then advances, `nextProvider` reads the advanced value.
final class ABRunCursor {
    var index: Int
    init(index: Int) { self.index = index }
}
