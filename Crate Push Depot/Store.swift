import Foundation
import SwiftUI

// MARK: - Persisted progress for a single level

struct CPDLevelProgress: Codable {
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

struct CPDSettings: Codable {
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

// MARK: - Store (Codable + UserDefaults under cpd.*)

final class CPDStore: ObservableObject {
    static let totalLevels = 120
    static let chapters = 6
    static let levelsPerChapter = 20

    @Published private(set) var progress: [CPDLevelProgress]
    @Published var settings: CPDSettings
    @Published var onboardingDone: Bool

    private let progressKey = "cpd.progress.v1"
    private let settingsKey = "cpd.settings.v1"
    private let onboardingKey = "cpd.onboarding.v1"

    init() {
        let d = UserDefaults.standard

        // progress
        if let data = d.data(forKey: progressKey),
           let decoded = try? JSONDecoder().decode([CPDLevelProgress].self, from: data),
           decoded.count == CPDStore.totalLevels {
            progress = decoded
        } else {
            progress = Array(repeating: CPDLevelProgress(), count: CPDStore.totalLevels)
        }

        // settings
        if let data = d.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode(CPDSettings.self, from: data) {
            settings = decoded
        } else {
            settings = CPDSettings()
        }

        onboardingDone = d.bool(forKey: onboardingKey)
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

    // MARK: queries

    func progress(for index: Int) -> CPDLevelProgress {
        guard index >= 0 && index < progress.count else { return CPDLevelProgress() }
        return progress[index]
    }

    func stars(forChapter chapter: Int) -> Int {
        let start = chapter * CPDStore.levelsPerChapter
        let end = start + CPDStore.levelsPerChapter
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
        let earned = CPDStore.starCount(moves: moves, par: par)
        p.solved = true
        if !p.solved || p.bestMoves == 0 || moves < p.bestMoves {
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
        progress = Array(repeating: CPDLevelProgress(), count: CPDStore.totalLevels)
        saveProgress()
    }
}

// MARK: - Haptics / sound feedback (lightweight, respects settings)

enum CPDFeedback {
    static func tap(_ store: CPDStore) {
        guard store.settings.hapticsOn else { return }
        let gen = UIImpactFeedbackGenerator(style: .light)
        gen.impactOccurred()
    }
    static func push(_ store: CPDStore) {
        guard store.settings.hapticsOn else { return }
        let gen = UIImpactFeedbackGenerator(style: .rigid)
        gen.impactOccurred()
    }
    static func success(_ store: CPDStore) {
        guard store.settings.hapticsOn else { return }
        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(.success)
    }
}
