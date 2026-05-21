import SwiftUI

/// Challenges home — Daily puzzle, Difficulty Packs, and Endless mode. Each is a `.abPanel`
/// section card. Daily and Endless mechanics live in this file; Packs link out to `PackListView`.
struct ChallengesView: View {
    @EnvironmentObject var store: ABStore

    @State private var dailyActive = false
    @State private var endlessActive = false
    @State private var endlessRunSeed: UInt64 = 0

    var body: some View {
        ZStack {
            ABBackground()
            ScrollView {
                VStack(spacing: 16) {
                    header
                    dailyCard
                    packsCard
                    endlessCard
                    Color.clear.frame(height: 8)
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }

            // Hidden navigation drivers for the Daily and Endless sessions.
            NavigationLink(destination: dailyDestination, isActive: $dailyActive) { EmptyView() }
                .hidden()
            NavigationLink(destination: endlessDestination, isActive: $endlessActive) { EmptyView() }
                .hidden()
        }
        .navigationBarTitle("Challenges", displayMode: .inline)
    }

    private var header: some View {
        HStack {
            Text("Challenges")
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundColor(ABPalette.textPrimary)
            Spacer()
        }
        .padding(.vertical, 4)
    }

    // MARK: - Daily

    /// Today's calendar-day key. The daily puzzle and "solved today" state both key off this.
    private var todayKey: Int { ABStore.dateKey() }

    /// Medium-difficulty profile derived from the date so every player gets the same puzzle on a
    /// given day. Grid 7...9, crates 3...5, scramble scales with the variant.
    static func dailyProfile(dateKey: Int) -> ABDifficultyProfile {
        let g = 7 + (dateKey % 3)               // 7,8,9
        let c = 3 + ((dateKey / 3) % 3)         // 3,4,5
        let scramble = 24 + (dateKey % 5) * 6   // 24...48
        return ABDifficultyProfile(gridSize: g, crates: c, scrambleDepth: scramble, wallDensity: 0.08)
    }

    static func dailyLevel(dateKey: Int) -> ABLevel {
        ABLevelGenerator.generate(profile: dailyProfile(dateKey: dateKey),
                                  seed: ABSplitMix64.mix(UInt64(dateKey)),
                                  levelIndex: 0)
    }

    private var dailyCard: some View {
        let solvedToday = store.isDailySolvedToday
        let streak = store.daily.currentStreak
        let best = store.daily.bestStreak
        return VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(ABPalette.panelRaised)
                        .frame(width: 56, height: 56)
                    ABStreakFlame(color: streak > 0 ? ABPalette.accent : ABPalette.textMuted, size: 30)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily Puzzle")
                        .font(.system(size: 19, weight: .heavy, design: .rounded))
                        .foregroundColor(ABPalette.textPrimary)
                    Text(solvedToday ? "Solved today — come back tomorrow" : "A fresh puzzle every day")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(ABPalette.textMuted)
                }
                Spacer()
            }

            HStack(spacing: 10) {
                statChip(label: "STREAK", value: "\(streak)")
                statChip(label: "BEST", value: "\(best)")
            }

            Button {
                dailyActive = true
            } label: {
                Text(solvedToday ? "Replay Today" : "Play Today")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(solvedToday ? ABPalette.textPrimary : ABPalette.backgroundDeep)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(solvedToday ? ABPalette.panelRaised : ABPalette.accent)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .abPanel()
    }

    @ViewBuilder
    private var dailyDestination: some View {
        let key = todayKey
        let level = ChallengesView.dailyLevel(dateKey: key)
        GameView(
            level: level,
            par: level.par,
            source: .daily(dateKey: key),
            onSolved: { moves, usedUndo, pushes in
                store.recordSolve(source: .daily(dateKey: key),
                                  moves: moves, par: level.par,
                                  usedUndo: usedUndo, pushes: pushes)
            },
            nextProvider: nil   // Daily is one puzzle; win overlay shows no "Next".
        )
    }

    // MARK: - Packs

    private var packsCard: some View {
        let totalSolved = ABStore.packIDs.reduce(0) { $0 + store.packSolvedCount($1) }
        let totalLevels = ABStore.packIDs.count * ABStore.packLevelCount
        return NavigationLink(destination: PackListView()) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(ABPalette.panelRaised)
                            .frame(width: 56, height: 56)
                        ABPackEmblem(tier: 4, tint: ABPalette.accent, size: 30)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Difficulty Packs")
                            .font(.system(size: 19, weight: .heavy, design: .rounded))
                            .foregroundColor(ABPalette.textPrimary)
                        Text("Relaxed · Standard · Tough · Brutal")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(ABPalette.textMuted)
                    }
                    Spacer()
                    ABChevron(color: ABPalette.textSecondary, size: 22)
                }
                HStack(spacing: 10) {
                    statChip(label: "SOLVED", value: "\(totalSolved)/\(totalLevels)")
                }
            }
            .padding(16)
            .abPanel()
        }
        .buttonStyle(.plain)
    }

    // MARK: - Endless (run mechanics added in Task 2.4)

    private var endlessCard: some View { EmptyView() }

    @ViewBuilder
    private var endlessDestination: some View { EmptyView() }

    // MARK: - Shared chip

    private func statChip(label: String, value: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundColor(ABPalette.textPrimary)
            Text(label)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(1)
                .foregroundColor(ABPalette.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: ABMetrics.cornerSmall, style: .continuous)
                .fill(ABPalette.panelRaised.opacity(0.5))
        )
    }
}
