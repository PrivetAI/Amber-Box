import SwiftUI

/// Challenges home — Daily puzzle, Difficulty Packs, and Endless mode. Each is a `.abPanel`
/// section card. Daily and Endless mechanics live in this file; Packs link out to `PackListView`.
struct ChallengesView: View {
    @EnvironmentObject var store: ABStore

    @State private var dailyActive = false
    @State private var endlessActive = false
    @StateObject private var endlessRun = ABEndlessRun()

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

    // MARK: - Endless

    /// Difficulty for endless position `n` (0-based). Escalates grid 6→10, crates 1→8, and
    /// scramble depth steadily so each cleared puzzle is a little harder than the last.
    static func endlessProfile(position n: Int) -> ABDifficultyProfile {
        let g = min(6 + n / 3, 10)              // 6 → 10 over the first ~12 positions
        let c = min(1 + n / 2, 8)               // 1 → 8
        let scramble = 12 + n * 5               // grows linearly
        let density = min(0.04 + Double(n) * 0.01, 0.16)
        return ABDifficultyProfile(gridSize: g, crates: c, scrambleDepth: scramble, wallDensity: density)
    }

    static func endlessLevel(runSeed: UInt64, position n: Int) -> ABLevel {
        ABLevelGenerator.generate(profile: endlessProfile(position: n),
                                  seed: ABSplitMix64.mix(runSeed &+ UInt64(n)),
                                  levelIndex: n)
    }

    private var endlessCard: some View {
        let best = store.endless.bestStreak
        let lastRun = endlessRun.lastReached
        return VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(ABPalette.panelRaised)
                        .frame(width: 56, height: 56)
                    ABStreakFlame(color: best > 0 ? ABPalette.crate : ABPalette.textMuted, size: 30)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Endless")
                        .font(.system(size: 19, weight: .heavy, design: .rounded))
                        .foregroundColor(ABPalette.textPrimary)
                    Text("Solve as far as you can — it only gets harder")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(ABPalette.textMuted)
                }
                Spacer()
            }

            HStack(spacing: 10) {
                statChip(label: "BEST", value: "\(best)")
                if lastRun > 0 {
                    statChip(label: "LAST RUN", value: "\(lastRun)")
                }
            }

            // Lightweight summary of the most recent finished run.
            if lastRun > 0 {
                Text(lastRun >= best
                     ? "New best — cleared \(lastRun) in a row!"
                     : "Run ended at \(lastRun). Best is \(best).")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(lastRun >= best ? ABPalette.success : ABPalette.textSecondary)
            }

            Button {
                endlessRun.start()
                endlessActive = true
            } label: {
                Text("Start Run")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(ABPalette.backgroundDeep)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(ABPalette.accent)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .abPanel()
    }

    @ViewBuilder
    private var endlessDestination: some View {
        let run = endlessRun
        let seed = run.runSeed
        let first = ChallengesView.endlessLevel(runSeed: seed, position: 0)
        // GameView reuses one onSolved/nextProvider for the whole chain, so the run's position is
        // tracked on `run` (an ObservableObject): onSolved records at the current position then
        // advances it; nextProvider reads the advanced position. Best streak persists via
        // recordSolve; quitting/back simply stops chaining (the run summary uses lastReached).
        GameView(
            level: first,
            par: first.par,
            source: .endless(streak: 0),
            onSolved: { moves, usedUndo, pushes in
                let n = run.position
                let lvl = ChallengesView.endlessLevel(runSeed: seed, position: n)
                store.recordSolve(source: .endless(streak: n),
                                  moves: moves, par: lvl.par,
                                  usedUndo: usedUndo, pushes: pushes)
                run.advance(reached: n + 1)
            },
            nextProvider: {
                let n = run.position
                let lvl = ChallengesView.endlessLevel(runSeed: seed, position: n)
                return (level: lvl, par: lvl.par, source: .endless(streak: n))
            }
        )
    }

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

// MARK: - Endless run state

/// Drives an Endless run: a per-run seed (from the clock at `start()`), the live `position`
/// (also the cursor a chained GameView reads/advances), and `lastReached` — the count of
/// puzzles cleared in the most recently finished run, surfaced in the summary.
final class ABEndlessRun: ObservableObject {
    private(set) var runSeed: UInt64 = 0
    /// Current run position (0-based). Levels at this position are what `nextProvider` serves.
    private(set) var position: Int = 0
    @Published private(set) var lastReached: Int = 0

    /// Begin a fresh run with a clock-derived seed (SplitMix64-mixed — never Hasher/hashValue).
    func start() {
        let ms = UInt64((Date().timeIntervalSince1970 * 1000).rounded())
        runSeed = ABSplitMix64.mix(ms)
        position = 0
    }

    /// Called once per cleared puzzle (GameView guards onSolved). Advances the run position and
    /// records how far this run has reached so the summary can show it after the run ends.
    func advance(reached: Int) {
        position = reached
        lastReached = reached
    }
}
