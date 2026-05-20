import Foundation
import SwiftUI

// One reversible step recorded for undo.
private struct CPDUndoStep {
    let workerFrom: CPDPoint
    let workerTo: CPDPoint
    let pushedCrateFrom: CPDPoint?   // nil if no crate was pushed
    let pushedCrateTo: CPDPoint?
}

final class CPDGameModel: ObservableObject {
    let level: CPDLevel

    @Published private(set) var worker: CPDPoint
    @Published private(set) var crates: Set<CPDPoint>
    @Published private(set) var moves: Int = 0
    @Published private(set) var pushes: Int = 0
    @Published private(set) var solved: Bool = false
    @Published private(set) var facing: CPDDirection = .down
    @Published private(set) var lastPushAnimationTick: Int = 0

    private var undoStack: [CPDUndoStep] = []

    var canUndo: Bool { !undoStack.isEmpty }
    var goals: Set<CPDPoint> { level.goals }
    var par: Int { level.par }

    init(level: CPDLevel) {
        self.level = level
        self.worker = level.workerStart
        self.crates = Set(level.cratesStart)
    }

    // MARK: - Queries

    func isWall(_ p: CPDPoint) -> Bool {
        if p.x < 0 || p.y < 0 || p.x >= level.width || p.y >= level.height { return true }
        return level.tiles[p.y][p.x] == CPDTile.wall.rawValue
    }
    func hasCrate(_ p: CPDPoint) -> Bool { crates.contains(p) }
    func isGoal(_ p: CPDPoint) -> Bool { level.goals.contains(p) }
    func crateSeated(_ p: CPDPoint) -> Bool { crates.contains(p) && level.goals.contains(p) }

    var crateSeatedCount: Int { crates.filter { level.goals.contains($0) }.count }
    var crateTotal: Int { crates.count }

    var currentStars: Int {
        guard solved else { return 0 }
        return CPDStore.starCount(moves: moves, par: level.par)
    }

    // MARK: - Move

    /// Attempt to move the worker one cell in `dir`. Pushes a crate if present and
    /// the destination beyond it is free floor. Worker can never pull.
    @discardableResult
    func move(_ dir: CPDDirection, store: CPDStore) -> Bool {
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
            let step = CPDUndoStep(workerFrom: worker, workerTo: target,
                                   pushedCrateFrom: target, pushedCrateTo: beyond)
            undoStack.append(step)
            worker = target
            moves += 1
            pushes += 1
            lastPushAnimationTick &+= 1
            CPDFeedback.push(store)
            checkSolved(store: store)
            return true
        } else {
            // plain move into empty floor
            let step = CPDUndoStep(workerFrom: worker, workerTo: target,
                                   pushedCrateFrom: nil, pushedCrateTo: nil)
            undoStack.append(step)
            worker = target
            moves += 1
            CPDFeedback.tap(store)
            return true
        }
    }

    // MARK: - Undo

    func undo(store: CPDStore) {
        guard let step = undoStack.popLast() else { return }
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
        CPDFeedback.tap(store)
    }

    // MARK: - Restart

    func restart(store: CPDStore) {
        worker = level.workerStart
        crates = Set(level.cratesStart)
        moves = 0
        pushes = 0
        solved = false
        facing = .down
        undoStack.removeAll()
        CPDFeedback.tap(store)
    }

    // MARK: - Win

    private func checkSolved(store: CPDStore) {
        guard crateTotal > 0 else { return }
        if crateSeatedCount == crateTotal {
            solved = true
            store.recordResult(index: level.index, moves: moves, par: level.par)
            CPDFeedback.success(store)
        }
    }
}
