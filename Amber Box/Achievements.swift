import Foundation

/// One achievement: a stable id, display strings, a target `goal`, and a `progress` closure that
/// reads the current store snapshot. Progress is always recomputed live (never stored) so it stays
/// correct after resets; only the unlocked flag is persisted (in `ABStore.unlocked`).
struct ABAchievement: Identifiable {
    let id: String
    let title: String
    let detail: String
    let goal: Int
    let progress: (ABStore) -> Int
}

/// The catalog. 26 achievements across Progression / Mastery / Style / Modes / Volume. Star- and
/// solve-based goals derive from the progress arrays (replay-proof); moves/pushes/no-undo/under-par
/// goals use the cumulative `ABStats` counters; daily/endless goals read their streak state.
enum ABAchievements {
    static let all: [ABAchievement] = [

        // MARK: Progression
        ABAchievement(id: "first_crate", title: "First Crate",
                      detail: "Solve your first level.", goal: 1,
                      progress: { $0.levelsSolved }),
        ABAchievement(id: "getting_settled", title: "Getting Settled",
                      detail: "Solve 10 levels.", goal: 10,
                      progress: { $0.levelsSolved }),
        ABAchievement(id: "floor_manager", title: "Floor Manager",
                      detail: "Solve 30 levels.", goal: 30,
                      progress: { $0.levelsSolved }),
        ABAchievement(id: "warehouse_boss", title: "Warehouse Boss",
                      detail: "Solve all 120 campaign levels.", goal: ABStore.totalLevels,
                      progress: { $0.campaignSolvedCount }),
        ABAchievement(id: "bay_cleared", title: "Bay Cleared",
                      detail: "Clear an entire chapter.", goal: 1,
                      progress: { $0.chaptersCleared }),
        ABAchievement(id: "full_sweep", title: "Full Sweep",
                      detail: "Clear all 6 chapters.", goal: ABStore.chapters,
                      progress: { $0.chaptersCleared }),

        // MARK: Mastery
        ABAchievement(id: "three_star_start", title: "Three-Star Start",
                      detail: "Earn 3 stars on any level.", goal: 1,
                      progress: { $0.threeStarCount }),
        ABAchievement(id: "perfectionist", title: "Perfectionist",
                      detail: "Earn 3 stars on 25 levels.", goal: 25,
                      progress: { $0.threeStarCount }),
        ABAchievement(id: "flawless_floor", title: "Flawless Floor",
                      detail: "Earn 3 stars on every level in a chapter.", goal: 1,
                      progress: { $0.chaptersThreeStarred }),
        ABAchievement(id: "star_collector", title: "Star Collector",
                      detail: "Collect 100 campaign stars.", goal: 100,
                      progress: { $0.totalStars }),
        ABAchievement(id: "star_hoarder", title: "Star Hoarder",
                      detail: "Collect 250 campaign stars.", goal: 250,
                      progress: { $0.totalStars }),
        ABAchievement(id: "full_marks", title: "Full Marks",
                      detail: "Collect all 360 campaign stars.", goal: ABStore.totalLevels * 3,
                      progress: { $0.totalStars }),

        // MARK: Style
        ABAchievement(id: "no_take_backs", title: "No Take-Backs",
                      detail: "Solve a level without using undo.", goal: 1,
                      progress: { $0.stats.noUndoSolves }),
        ABAchievement(id: "clean_hands", title: "Clean Hands",
                      detail: "Solve 10 levels without undo.", goal: 10,
                      progress: { $0.stats.noUndoSolves }),
        ABAchievement(id: "under_par", title: "Under Par",
                      detail: "Beat par on a level.", goal: 1,
                      progress: { $0.stats.underParSolves }),
        ABAchievement(id: "efficient", title: "Efficient",
                      detail: "Beat par on 15 levels.", goal: 15,
                      progress: { $0.stats.underParSolves }),

        // MARK: Modes
        ABAchievement(id: "daily_dabbler", title: "Daily Dabbler",
                      detail: "Solve a daily puzzle.", goal: 1,
                      progress: { $0.daily.lastSolvedDateKey != 0 ? 1 : 0 }),
        ABAchievement(id: "streak_starter", title: "Streak Starter",
                      detail: "Reach a 3-day daily streak.", goal: 3,
                      progress: { $0.daily.bestStreak }),
        ABAchievement(id: "routine", title: "Routine",
                      detail: "Reach a 7-day daily streak.", goal: 7,
                      progress: { $0.daily.bestStreak }),
        ABAchievement(id: "devoted", title: "Devoted",
                      detail: "Reach a 30-day daily streak.", goal: 30,
                      progress: { $0.daily.bestStreak }),
        ABAchievement(id: "pack_rat", title: "Pack Rat",
                      detail: "Clear an entire difficulty pack.", goal: 1,
                      progress: { $0.packsCleared }),
        ABAchievement(id: "brutal_honesty", title: "Brutal Honesty",
                      detail: "Clear the Brutal pack.", goal: 1,
                      progress: { $0.isPackCleared("brutal") ? 1 : 0 }),
        ABAchievement(id: "endless_5", title: "Endless 5",
                      detail: "Reach an Endless streak of 5.", goal: 5,
                      progress: { $0.endless.bestStreak }),
        ABAchievement(id: "endless_25", title: "Endless 25",
                      detail: "Reach an Endless streak of 25.", goal: 25,
                      progress: { $0.endless.bestStreak }),

        // MARK: Volume
        ABAchievement(id: "heavy_lifter", title: "Heavy Lifter",
                      detail: "Push crates 1,000 times.", goal: 1000,
                      progress: { $0.stats.totalPushes }),
        ABAchievement(id: "mover", title: "Mover",
                      detail: "Take 10,000 moves.", goal: 10000,
                      progress: { $0.stats.totalMoves }),
    ]
}
