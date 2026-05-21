import Foundation
import SwiftUI

// One reversible step recorded for undo.
private struct ABUndoStep {
    let workerFrom: ABPoint
    let workerTo: ABPoint
    let pushedCrateFrom: ABPoint?   // nil if no crate was pushed
    let pushedCrateTo: ABPoint?
}

final class ABGameModel: ObservableObject {
    let level: ABLevel

    @Published private(set) var worker: ABPoint
    @Published private(set) var crates: Set<ABPoint>
    @Published private(set) var moves: Int = 0
    @Published private(set) var pushes: Int = 0
    @Published private(set) var solved: Bool = false
    @Published private(set) var facing: ABDirection = .down
    @Published private(set) var lastPushAnimationTick: Int = 0
    @Published private(set) var usedUndo: Bool = false   // true if undo was used at any point this attempt

    private var undoStack: [ABUndoStep] = []

    var canUndo: Bool { !undoStack.isEmpty }
    var goals: Set<ABPoint> { level.goals }
    var par: Int { level.par }

    init(level: ABLevel) {
        self.level = level
        self.worker = level.workerStart
        self.crates = Set(level.cratesStart)
    }

    // MARK: - Queries

    func isWall(_ p: ABPoint) -> Bool {
        if p.x < 0 || p.y < 0 || p.x >= level.width || p.y >= level.height { return true }
        return level.tiles[p.y][p.x] == ABTile.wall.rawValue
    }
    func hasCrate(_ p: ABPoint) -> Bool { crates.contains(p) }
    func isGoal(_ p: ABPoint) -> Bool { level.goals.contains(p) }
    func crateSeated(_ p: ABPoint) -> Bool { crates.contains(p) && level.goals.contains(p) }

    var crateSeatedCount: Int { crates.filter { level.goals.contains($0) }.count }
    var crateTotal: Int { crates.count }

    var currentStars: Int {
        guard solved else { return 0 }
        return ABStore.starCount(moves: moves, par: level.par)
    }

    // MARK: - Move

    /// Attempt to move the worker one cell in `dir`. Pushes a crate if present and
    /// the destination beyond it is free floor. Worker can never pull.
    @discardableResult
    func move(_ dir: ABDirection, store: ABStore) -> Bool {
        if solved { return false }
        facing = dir
        let target = worker.offset(dir)

        // Wall in front -> blocked.
        if isWall(target) { return false }

        if crates.contains(target) {
            // pushing: cell beyond crate must be free floor (no wall, no crate)
            let beyond = target.offset(dir)
            if isWall(beyond) || crates.contains(beyond) { return false }

            // perform push
            crates.remove(target)
            crates.insert(beyond)
            let step = ABUndoStep(workerFrom: worker, workerTo: target,
                                   pushedCrateFrom: target, pushedCrateTo: beyond)
            undoStack.append(step)
            worker = target
            moves += 1
            pushes += 1
            lastPushAnimationTick &+= 1
            ABFeedback.push(store)
            checkSolved(store: store)
            return true
        } else {
            // plain move into empty floor
            let step = ABUndoStep(workerFrom: worker, workerTo: target,
                                   pushedCrateFrom: nil, pushedCrateTo: nil)
            undoStack.append(step)
            worker = target
            moves += 1
            ABFeedback.tap(store)
            return true
        }
    }

    // MARK: - Undo

    func undo(store: ABStore) {
        guard let step = undoStack.popLast() else { return }
        usedUndo = true
        // reverse crate push first
        if let cFrom = step.pushedCrateFrom, let cTo = step.pushedCrateTo {
            crates.remove(cTo)
            crates.insert(cFrom)
        }
        worker = step.workerFrom
        if moves > 0 { moves -= 1 }
        if step.pushedCrateFrom != nil && pushes > 0 { pushes -= 1 }
        // undoing un-solves if it was solved (cannot normally undo after solve since input is locked,
        // but keep state consistent).
        solved = (crateSeatedCount == crateTotal && crateTotal > 0)
        ABFeedback.tap(store)
    }

    // MARK: - Restart

    func restart(store: ABStore) {
        worker = level.workerStart
        crates = Set(level.cratesStart)
        moves = 0
        pushes = 0
        solved = false
        usedUndo = false
        facing = .down
        undoStack.removeAll()
        ABFeedback.tap(store)
    }

    // MARK: - Win

    private func checkSolved(store: ABStore) {
        guard crateTotal > 0 else { return }
        if crateSeatedCount == crateTotal {
            solved = true
            // Progress recording is handled by GameView via the session's source/onSolved
            // hook (so every content source — campaign, packs, daily, endless — funnels
            // through one place). The model only flags the solve and fires feedback.
            ABFeedback.success(store)
        }
    }
}
