import Foundation
import SwiftUI

// MARK: - Persisted progress for a single level

struct ABLevelProgress: Codable {
    var stars: Int        // 0..3
    var bestMoves: Int    // best (lowest) moves to solve; 0 == unsolved
    var solved: Bool

    init(stars: Int = 0, bestMoves: Int = 0, solved: Bool = false) {
        self.stars = stars
        self.bestMoves = bestMoves
        self.solved = solved
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        stars = try c.decodeIfPresent(Int.self, forKey: .stars) ?? 0
        bestMoves = try c.decodeIfPresent(Int.self, forKey: .bestMoves) ?? 0
        solved = try c.decodeIfPresent(Bool.self, forKey: .solved) ?? false
    }

    enum CodingKeys: String, CodingKey { case stars, bestMoves, solved }
}

// MARK: - Settings

struct ABSettings: Codable {
    var soundOn: Bool
    var hapticsOn: Bool

    init(soundOn: Bool = true, hapticsOn: Bool = true) {
        self.soundOn = soundOn
        self.hapticsOn = hapticsOn
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        soundOn = try c.decodeIfPresent(Bool.self, forKey: .soundOn) ?? true
        hapticsOn = try c.decodeIfPresent(Bool.self, forKey: .hapticsOn) ?? true
    }

    enum CodingKeys: String, CodingKey { case soundOn, hapticsOn }
}

// MARK: - Daily puzzle state (cpd.daily.v1)

struct ABDailyState: Codable {
    var lastSolvedDateKey: Int = 0   // yyyymmdd; 0 == never solved
    var currentStreak: Int = 0
    var bestStreak: Int = 0

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        lastSolvedDateKey = try c.decodeIfPresent(Int.self, forKey: .lastSolvedDateKey) ?? 0
        currentStreak = try c.decodeIfPresent(Int.self, forKey: .currentStreak) ?? 0
        bestStreak = try c.decodeIfPresent(Int.self, forKey: .bestStreak) ?? 0
    }

    enum CodingKeys: String, CodingKey { case lastSolvedDateKey, currentStreak, bestStreak }
}

// MARK: - Endless run state (cpd.endless.v1)

struct ABEndlessState: Codable {
    var bestStreak: Int = 0

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        bestStreak = try c.decodeIfPresent(Int.self, forKey: .bestStreak) ?? 0
    }

    enum CodingKeys: String, CodingKey { case bestStreak }
}

// MARK: - Lifetime cumulative stats (cpd.stats.v1)

/// Cumulative counters that cannot be derived from the progress arrays (they accumulate across
/// every solve and every replay). Star/solve-based numbers are NOT stored here — they are derived
/// on demand from `progress` / `packProgress` so replays can't inflate them.
struct ABStats: Codable {
    var totalMoves: Int = 0       // sum of moves across all solves (campaign + packs + daily + endless)
    var totalPushes: Int = 0      // sum of crate pushes across all solves
    var noUndoSolves: Int = 0     // count of solves completed without ever using undo
    var underParSolves: Int = 0   // count of solves strictly under par

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        totalMoves = try c.decodeIfPresent(Int.self, forKey: .totalMoves) ?? 0
        totalPushes = try c.decodeIfPresent(Int.self, forKey: .totalPushes) ?? 0
        noUndoSolves = try c.decodeIfPresent(Int.self, forKey: .noUndoSolves) ?? 0
        underParSolves = try c.decodeIfPresent(Int.self, forKey: .underParSolves) ?? 0
    }

    enum CodingKeys: String, CodingKey { case totalMoves, totalPushes, noUndoSolves, underParSolves }
}

// MARK: - Store (Codable + UserDefaults under cpd.*)

final class ABStore: ObservableObject {
    static let totalLevels = 120
    static let chapters = 6
    static let levelsPerChapter = 20

    // Difficulty packs (Phase 2). 4 packs × 20 levels each (+80 levels).
    static let packIDs = ["relaxed", "standard", "tough", "brutal"]
    static let packLevelCount = 20

    @Published private(set) var progress: [ABLevelProgress]
    @Published var settings: ABSettings
    @Published var onboardingDone: Bool

    // Pack progress keyed by pack id; each id maps to `packLevelCount` ABLevelProgress.
    @Published private(set) var packProgress: [String: [ABLevelProgress]]
    @Published private(set) var daily: ABDailyState
    @Published private(set) var endless: ABEndlessState

    // Lifetime cumulative stats + unlocked achievements (Phase 3).
    @Published private(set) var stats: ABStats
    @Published private(set) var unlocked: Set<String>
    // Achievement ids unlocked by the most recent solve; consumed + cleared by the unlock toast.
    @Published var lastUnlocked: [String] = []

    private let progressKey = "cpd.progress.v1"
    private let settingsKey = "cpd.settings.v1"
    private let onboardingKey = "cpd.onboarding.v1"
    private let packsKey = "cpd.packs.v1"
    private let dailyKey = "cpd.daily.v1"
    private let endlessKey = "cpd.endless.v1"
    private let statsKey = "cpd.stats.v1"
    private let achievementsKey = "cpd.achievements.v1"

    init() {
        let d = UserDefaults.standard

        // progress
        if let data = d.data(forKey: progressKey),
           let decoded = try? JSONDecoder().decode([ABLevelProgress].self, from: data),
           decoded.count == ABStore.totalLevels {
            progress = decoded
        } else {
            progress = Array(repeating: ABLevelProgress(), count: ABStore.totalLevels)
        }

        // settings
        if let data = d.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode(ABSettings.self, from: data) {
            settings = decoded
        } else {
            settings = ABSettings()
        }

        onboardingDone = d.bool(forKey: onboardingKey)

        // pack progress — default each id to a fresh array, then overlay any decoded entries
        // (only when the count matches, mirroring the campaign-progress count guard).
        var packs = ABStore.freshPackProgress()
        if let data = d.data(forKey: packsKey),
           let decoded = try? JSONDecoder().decode([String: [ABLevelProgress]].self, from: data) {
            for id in ABStore.packIDs {
                if let arr = decoded[id], arr.count == ABStore.packLevelCount {
                    packs[id] = arr
                }
            }
        }
        packProgress = packs

        // daily
        if let data = d.data(forKey: dailyKey),
           let decoded = try? JSONDecoder().decode(ABDailyState.self, from: data) {
            daily = decoded
        } else {
            daily = ABDailyState()
        }

        // endless
        if let data = d.data(forKey: endlessKey),
           let decoded = try? JSONDecoder().decode(ABEndlessState.self, from: data) {
            endless = decoded
        } else {
            endless = ABEndlessState()
        }

        // stats
        if let data = d.data(forKey: statsKey),
           let decoded = try? JSONDecoder().decode(ABStats.self, from: data) {
            stats = decoded
        } else {
            stats = ABStats()
        }

        // unlocked achievements
        if let data = d.data(forKey: achievementsKey),
           let decoded = try? JSONDecoder().decode(Set<String>.self, from: data) {
            unlocked = decoded
        } else {
            unlocked = []
        }
    }

    private static func freshPackProgress() -> [String: [ABLevelProgress]] {
        var result: [String: [ABLevelProgress]] = [:]
        for id in packIDs {
            result[id] = Array(repeating: ABLevelProgress(), count: packLevelCount)
        }
        return result
    }

    // MARK: persistence

    private func saveProgress() {
        if let data = try? JSONEncoder().encode(progress) {
            UserDefaults.standard.set(data, forKey: progressKey)
        }
    }

    func saveSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: settingsKey)
        }
    }

    func markOnboardingDone() {
        onboardingDone = true
        UserDefaults.standard.set(true, forKey: onboardingKey)
    }

    private func savePacks() {
        if let data = try? JSONEncoder().encode(packProgress) {
            UserDefaults.standard.set(data, forKey: packsKey)
        }
    }

    private func saveDaily() {
        if let data = try? JSONEncoder().encode(daily) {
            UserDefaults.standard.set(data, forKey: dailyKey)
        }
    }

    private func saveEndless() {
        if let data = try? JSONEncoder().encode(endless) {
            UserDefaults.standard.set(data, forKey: endlessKey)
        }
    }

    private func saveStats() {
        if let data = try? JSONEncoder().encode(stats) {
            UserDefaults.standard.set(data, forKey: statsKey)
        }
    }

    private func saveAchievements() {
        if let data = try? JSONEncoder().encode(unlocked) {
            UserDefaults.standard.set(data, forKey: achievementsKey)
        }
    }

    // MARK: queries

    func progress(for index: Int) -> ABLevelProgress {
        guard index >= 0 && index < progress.count else { return ABLevelProgress() }
        return progress[index]
    }

    func stars(forChapter chapter: Int) -> Int {
        let start = chapter * ABStore.levelsPerChapter
        let end = start + ABStore.levelsPerChapter
        guard start >= 0 && end <= progress.count else { return 0 }
        return progress[start..<end].reduce(0) { $0 + $1.stars }
    }

    var totalStars: Int { progress.reduce(0) { $0 + $1.stars } }

    // Chapter 0 always unlocked; each later chapter needs >= 30 stars in previous.
    func isChapterUnlocked(_ chapter: Int) -> Bool {
        if chapter <= 0 { return true }
        return stars(forChapter: chapter - 1) >= 30
    }

    // MARK: mutation

    func recordResult(index: Int, moves: Int, par: Int) {
        guard index >= 0 && index < progress.count else { return }
        var p = progress[index]
        let earned = ABStore.starCount(moves: moves, par: par)
        p.solved = true
        if p.bestMoves == 0 || moves < p.bestMoves {
            p.bestMoves = moves
        }
        if earned > p.stars { p.stars = earned }
        progress[index] = p
        saveProgress()
    }

    static func starCount(moves: Int, par: Int) -> Int {
        let safePar = max(par, 1)
        if moves <= safePar { return 3 }
        if Double(moves) <= 1.5 * Double(safePar) { return 2 }
        return 1
    }

    func resetProgress() {
        progress = Array(repeating: ABLevelProgress(), count: ABStore.totalLevels)
        packProgress = ABStore.freshPackProgress()
        daily = ABDailyState()
        endless = ABEndlessState()
        stats = ABStats()
        unlocked = []
        lastUnlocked = []
        saveProgress()
        savePacks()
        saveDaily()
        saveEndless()
        saveStats()
        saveAchievements()
    }

    // MARK: - Pack queries

    func packProgress(forPack id: String) -> [ABLevelProgress] {
        packProgress[id] ?? Array(repeating: ABLevelProgress(), count: ABStore.packLevelCount)
    }

    func packProgress(forPack id: String, index: Int) -> ABLevelProgress {
        let arr = packProgress(forPack: id)
        guard index >= 0 && index < arr.count else { return ABLevelProgress() }
        return arr[index]
    }

    func packSolvedCount(_ id: String) -> Int {
        packProgress(forPack: id).reduce(0) { $0 + ($1.solved ? 1 : 0) }
    }

    func packStars(_ id: String) -> Int {
        packProgress(forPack: id).reduce(0) { $0 + $1.stars }
    }

    func isPackCleared(_ id: String) -> Bool {
        packSolvedCount(id) >= ABStore.packLevelCount
    }

    // MARK: - Unified solve funnel

    /// Every solve (campaign, pack, daily, endless) funnels through here so progress, stats,
    /// and achievements all update in one place. Star scoring uses the supplied reference `par`.
    func recordSolve(source: ABGameSource, moves: Int, par: Int, usedUndo: Bool, pushes: Int) {
        let earned = ABStore.starCount(moves: moves, par: par)
        switch source {
        case .campaign(let i):
            guard i >= 0 && i < progress.count else { break }
            ABStore.applyProgress(&progress[i], moves: moves, stars: earned)
            saveProgress()
        case .pack(let id, let i):
            if var arr = packProgress[id], i >= 0 && i < arr.count {
                ABStore.applyProgress(&arr[i], moves: moves, stars: earned)
                packProgress[id] = arr
                savePacks()
            }
        case .daily(let dateKey):
            updateDailyStreak(solvedDateKey: dateKey)
        case .endless(let streak):
            let reached = streak + 1   // solving position `streak` clears `streak+1` levels
            if reached > endless.bestStreak {
                endless.bestStreak = reached
                saveEndless()
            }
        }
        bumpStats(earned: earned, moves: moves, pushes: pushes, usedUndo: usedUndo, par: par)
        evaluateAchievements()
    }

    /// Mirrors the existing `recordResult` body: solved=true, best (lowest) moves, max stars.
    private static func applyProgress(_ p: inout ABLevelProgress, moves: Int, stars: Int) {
        p.solved = true
        if p.bestMoves == 0 || moves < p.bestMoves {
            p.bestMoves = moves
        }
        if stars > p.stars { p.stars = stars }
    }

    /// Increment the daily streak when `dateKey` is the day after `lastSolvedDateKey`; reset to
    /// 1 if it's a brand-new (non-consecutive) day. Solving the same day again is a no-op for the
    /// streak (replay is allowed but earns no extra streak). Always tracks `bestStreak`.
    private func updateDailyStreak(solvedDateKey dateKey: Int) {
        if dateKey == daily.lastSolvedDateKey {
            return   // already solved today — no extra streak
        }
        if daily.lastSolvedDateKey != 0,
           ABStore.dateKey(dayAfter: daily.lastSolvedDateKey) == dateKey {
            daily.currentStreak += 1
        } else {
            daily.currentStreak = 1
        }
        daily.lastSolvedDateKey = dateKey
        if daily.currentStreak > daily.bestStreak {
            daily.bestStreak = daily.currentStreak
        }
        saveDaily()
    }

    var isDailySolvedToday: Bool { daily.lastSolvedDateKey == ABStore.dateKey() }

    // MARK: - Date helpers

    /// Calendar day key: year*10000 + month*100 + day, using `Calendar.current`.
    static func dateKey(_ date: Date = Date()) -> Int {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        let y = c.year ?? 0, m = c.month ?? 0, d = c.day ?? 0
        return y * 10000 + m * 100 + d
    }

    /// The dateKey of the calendar day following the given dateKey (handles month/year rollover
    /// via `Calendar.current`). Returns the input unchanged if it can't be parsed.
    static func dateKey(dayAfter key: Int) -> Int {
        let y = key / 10000
        let m = (key / 100) % 100
        let d = key % 100
        var comps = DateComponents()
        comps.year = y; comps.month = m; comps.day = d
        let cal = Calendar.current
        guard let date = cal.date(from: comps),
              let next = cal.date(byAdding: .day, value: 1, to: date) else { return key }
        return dateKey(next)
    }

    // MARK: - Stats / achievements hooks (Phase 3 fills these in)

    /// Accumulate cumulative lifetime counters for one solve. Called once per solve from
    /// `recordSolve`. Star/solve totals are NOT counted here (they derive from progress arrays so
    /// replays never inflate them); only genuinely cumulative play counters live here.
    func bumpStats(earned: Int, moves: Int, pushes: Int, usedUndo: Bool, par: Int) {
        stats.totalMoves += moves
        stats.totalPushes += pushes
        if !usedUndo { stats.noUndoSolves += 1 }
        if moves < par { stats.underParSolves += 1 }
        saveStats()
    }

    func evaluateAchievements() {
        // Phase 3.2: achievement evaluation + lastUnlocked surfacing (cpd.achievements.v1).
    }
}

// MARK: - Haptics / sound feedback (lightweight, respects settings)

enum ABFeedback {
    static func tap(_ store: ABStore) {
        guard store.settings.hapticsOn else { return }
        let gen = UIImpactFeedbackGenerator(style: .light)
        gen.impactOccurred()
    }
    static func push(_ store: ABStore) {
        guard store.settings.hapticsOn else { return }
        let gen = UIImpactFeedbackGenerator(style: .rigid)
        gen.impactOccurred()
    }
    static func success(_ store: ABStore) {
        guard store.settings.hapticsOn else { return }
        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(.success)
    }
}
