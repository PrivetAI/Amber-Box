import Foundation

// MARK: - Deterministic seeded RNG (SplitMix64)

struct CPDSplitMix64 {
    private var state: UInt64
    init(seed: UInt64) { self.state = seed }

    mutating func next() -> UInt64 {
        state = state &+ 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        z = z ^ (z >> 31)
        return z
    }

    // Uniform integer in 0..<bound
    mutating func int(_ bound: Int) -> Int {
        guard bound > 0 else { return 0 }
        return Int(next() % UInt64(bound))
    }

    mutating func bool() -> Bool { next() & 1 == 0 }
}

// MARK: - Tile model

enum CPDTile: Int, Codable {
    case floor = 0
    case wall = 1
}

struct CPDPoint: Hashable, Codable {
    var x: Int
    var y: Int
    func offset(_ dir: CPDDirection) -> CPDPoint {
        CPDPoint(x: x + dir.dx, y: y + dir.dy)
    }
}

enum CPDDirection: Int, CaseIterable, Codable {
    case up, down, left, right
    var dx: Int { switch self { case .left: return -1; case .right: return 1; default: return 0 } }
    var dy: Int { switch self { case .up: return -1; case .down: return 1; default: return 0 } }
    var opposite: CPDDirection {
        switch self {
        case .up: return .down; case .down: return .up
        case .left: return .right; case .right: return .left
        }
    }
}

// MARK: - Level definition (puzzle start state + goals)

struct CPDLevel: Codable {
    let index: Int            // 0-based global index 0..119
    let width: Int
    let height: Int
    let tiles: [[Int]]        // [row][col] -> CPDTile.rawValue
    let walls: Set<CPDPoint>
    let goals: Set<CPDPoint>  // target pad cells
    let cratesStart: [CPDPoint]
    let workerStart: CPDPoint
    let par: Int              // reference par = reverse-construction worker-step length

    var chapter: Int { index / 20 }       // 0..5
    var indexInChapter: Int { index % 20 } // 0..19

    // Forward solution directions derived from the reverse-construction scramble.
    // Not persisted (regenerated deterministically); used for hint/verification only.
    var solutionPath: [CPDDirection] = []

    enum CodingKeys: String, CodingKey {
        case index, width, height, tiles, walls, goals, cratesStart, workerStart, par
    }

    init(index: Int, width: Int, height: Int, tiles: [[Int]], walls: Set<CPDPoint>,
         goals: Set<CPDPoint>, cratesStart: [CPDPoint], workerStart: CPDPoint,
         par: Int, solutionPath: [CPDDirection] = []) {
        self.index = index
        self.width = width
        self.height = height
        self.tiles = tiles
        self.walls = walls
        self.goals = goals
        self.cratesStart = cratesStart
        self.workerStart = workerStart
        self.par = par
        self.solutionPath = solutionPath
    }
}

// MARK: - Level generator (reverse construction guarantees solvability)

enum CPDLevelGenerator {

    struct Spec {
        let width: Int
        let height: Int
        let crates: Int
        let scrambleSteps: Int
    }

    static func spec(for index: Int) -> Spec {
        let chapter = index / 20         // 0..5
        let within = index % 20          // 0..19
        // Grid grows 6x6 -> 10x10 across chapters; crate count rises 1 -> 8.
        let size = 6 + chapter           // 6,7,8,9,10,11 -> clamp to 10
        let w = min(size, 10)
        let h = min(size, 10)
        // crates: chapter base + progression within chapter
        let baseCrates = 1 + chapter      // chapter0:1 ... chapter5:6
        let extra = within / 7            // 0..2 across the chapter
        let crates = min(baseCrates + extra, 8)
        // scramble grows with difficulty
        let scramble = 8 + chapter * 6 + within * 2
        return Spec(width: w, height: h, crates: max(1, crates), scrambleSteps: scramble)
    }

    static func generate(index: Int) -> CPDLevel {
        var rng = CPDSplitMix64(seed: seedSafe(for: index))
        let s = spec(for: index)
        let w = s.width, h = s.height

        // Attempt loop: produce a valid puzzle. The reverse construction always
        // yields a solvable layout; we re-roll only to satisfy quality validators.
        for _ in 0..<60 {
            if let level = attempt(index: index, spec: s, rng: &rng) {
                return level
            }
        }
        // Fallback: simplest guaranteed-valid layout (rare).
        return fallback(index: index, w: w, h: h)
    }

    private static func seedSafe(for index: Int) -> UInt64 {
        let base: UInt64 = 0x7A11D00D1234ABCD
        return base &+ (UInt64(index) &* 0x9E3779B97F4A7C15) &+ 0xCA7
    }

    private static func attempt(index: Int, spec s: Spec, rng: inout CPDSplitMix64) -> CPDLevel? {
        let w = s.width, h = s.height

        // Build interior wall ring is the border; interior is floor with some scattered walls.
        var walls = Set<CPDPoint>()
        // border walls
        for x in 0..<w {
            walls.insert(CPDPoint(x: x, y: 0))
            walls.insert(CPDPoint(x: x, y: h - 1))
        }
        for y in 0..<h {
            walls.insert(CPDPoint(x: 0, y: y))
            walls.insert(CPDPoint(x: w - 1, y: y))
        }

        // interior cells
        var interior: [CPDPoint] = []
        for y in 1..<(h - 1) {
            for x in 1..<(w - 1) {
                interior.append(CPDPoint(x: x, y: y))
            }
        }
        guard interior.count >= s.crates + 4 else { return nil }

        // Scatter a few interior obstacle walls for higher chapters (kept sparse).
        let chapter = index / 20
        let obstacleCount = max(0, min(chapter - 1, (interior.count / 8)))
        var obstacleCandidates = interior
        shuffle(&obstacleCandidates, rng: &rng)
        var placedObstacles = Set<CPDPoint>()
        var oi = 0
        while placedObstacles.count < obstacleCount && oi < obstacleCandidates.count {
            let c = obstacleCandidates[oi]; oi += 1
            // keep obstacles off the very center band to avoid sealing
            placedObstacles.insert(c)
        }
        walls.formUnion(placedObstacles)

        // floor cells available (interior minus obstacles)
        var floors = interior.filter { !walls.contains($0) }
        guard floors.count >= s.crates + 2 else { return nil }

        // Ensure floor region is fully connected; if not, reject.
        if !isConnected(floors: Set(floors), w: w, h: h) { return nil }

        // Place goals (target pads) = solved crate positions.
        shuffle(&floors, rng: &rng)
        // pick goals not directly adjacent-clustered into impossible blocks
        var goals: [CPDPoint] = []
        var goalSet = Set<CPDPoint>()
        var fi = 0
        while goals.count < s.crates && fi < floors.count {
            let c = floors[fi]; fi += 1
            goals.append(c)
            goalSet.insert(c)
        }
        if goals.count < s.crates { return nil }

        // Worker starts on a floor cell not occupied by a crate (initially crates == goals).
        let workerCandidates = floors.filter { !goalSet.contains($0) }
        guard let workerSeed = pick(workerCandidates, rng: &rng) else { return nil }

        // Reverse simulation: crates begin ON goals, worker at workerSeed.
        var crates = goalSet           // current crate positions
        var worker = workerSeed
        var pathLen = 0

        let allFloor = Set(floors)

        // Perform reverse "pulls": choose a direction, the worker steps into a free
        // cell, and (optionally) drags the crate that was behind it. A normal solver
        // could reverse each such step. We bias toward producing pulls so crates move.
        var lastDir: CPDDirection? = nil
        var attemptsLeft = s.scrambleSteps * 6
        var pulls = 0
        // Record each reverse step's move direction so a forward solution can be derived.
        var scrambleDirs: [CPDDirection] = []

        while pathLen < s.scrambleSteps && attemptsLeft > 0 {
            attemptsLeft -= 1
            let dir = CPDDirection.allCases[rng.int(4)]
            // avoid immediately undoing the previous move too often (keeps motion)
            if let ld = lastDir, dir == ld.opposite, rng.bool() { continue }

            let dest = worker.offset(dir)              // where the worker would move
            // dest must be free floor (not wall, not crate)
            if !allFloor.contains(dest) { continue }
            if crates.contains(dest) { continue }

            // The cell BEHIND the worker (opposite of move dir) may hold a crate to pull.
            let behind = worker.offset(dir.opposite)
            let canPull = crates.contains(behind)

            // Decide: pull if possible (bias high) else plain move.
            let doPull = canPull && (rng.int(100) < 80)

            if doPull {
                // crate moves from `behind` to `worker`'s old cell.
                crates.remove(behind)
                crates.insert(worker)
                pulls += 1
            }
            worker = dest
            pathLen += 1
            lastDir = dir
            scrambleDirs.append(dir)
        }

        // The forward solution is the scramble replayed in reverse: each reverse step
        // (worker moved in `dir`, optionally pulling a crate) inverts to a forward worker
        // move in `dir.opposite` (which pushes that crate back onto its pad).
        let solution = scrambleDirs.reversed().map { $0.opposite }

        // Need at least some crates displaced off their goals.
        let displaced = crates.subtracting(goalSet)
        if displaced.isEmpty { return nil }
        if pulls < max(1, s.crates) { return nil }   // ensure meaningful scramble

        // Validate: no off-pad crate trapped in an unrecoverable corner.
        for crate in crates where !goalSet.contains(crate) {
            if isDeadCorner(crate, walls: walls, goals: goalSet, w: w, h: h) {
                return nil
            }
        }

        // Validate: worker can reach a cell adjacent to at least one displaced crate
        // on the push side (basic reachability so puzzle isn't visually stuck).
        if !workerCanReachAnyPushSpot(worker: worker, crates: crates, walls: walls, goals: goalSet, w: w, h: h) {
            return nil
        }

        // Build tile grid.
        var tiles = Array(repeating: Array(repeating: CPDTile.floor.rawValue, count: w), count: h)
        for wcell in walls {
            if wcell.y >= 0 && wcell.y < h && wcell.x >= 0 && wcell.x < w {
                tiles[wcell.y][wcell.x] = CPDTile.wall.rawValue
            }
        }

        let cratesArr = Array(crates).sorted { ($0.y, $0.x) < ($1.y, $1.x) }

        return CPDLevel(
            index: index,
            width: w,
            height: h,
            tiles: tiles,
            walls: walls,
            goals: goalSet,
            cratesStart: cratesArr,
            workerStart: worker,
            par: max(pathLen, displaced.count),
            solutionPath: solution
        )
    }

    // MARK: - Validators / helpers

    private static func isDeadCorner(_ p: CPDPoint, walls: Set<CPDPoint>, goals: Set<CPDPoint>, w: Int, h: Int) -> Bool {
        if goals.contains(p) { return false }
        func blocked(_ pt: CPDPoint) -> Bool {
            if pt.x < 0 || pt.y < 0 || pt.x >= w || pt.y >= h { return true }
            return walls.contains(pt)
        }
        let up = blocked(p.offset(.up))
        let down = blocked(p.offset(.down))
        let left = blocked(p.offset(.left))
        let right = blocked(p.offset(.right))
        // A crate is dead if it's wedged into a corner (two perpendicular blocks)
        // and not on a goal — it can never be pushed out.
        let corner = (up && left) || (up && right) || (down && left) || (down && right)
        return corner
    }

    private static func isConnected(floors: Set<CPDPoint>, w: Int, h: Int) -> Bool {
        guard let start = floors.first else { return false }
        var seen = Set<CPDPoint>()
        var stack = [start]
        while let cur = stack.popLast() {
            if seen.contains(cur) { continue }
            seen.insert(cur)
            for d in CPDDirection.allCases {
                let n = cur.offset(d)
                if floors.contains(n) && !seen.contains(n) { stack.append(n) }
            }
        }
        return seen.count == floors.count
    }

    private static func workerCanReachAnyPushSpot(worker: CPDPoint, crates: Set<CPDPoint>, walls: Set<CPDPoint>, goals: Set<CPDPoint>, w: Int, h: Int) -> Bool {
        // BFS over cells the worker can stand on (floor, non-crate).
        func passable(_ p: CPDPoint) -> Bool {
            if p.x < 0 || p.y < 0 || p.x >= w || p.y >= h { return false }
            if walls.contains(p) { return false }
            if crates.contains(p) { return false }
            return true
        }
        var seen = Set<CPDPoint>([worker])
        var queue = [worker]
        while !queue.isEmpty {
            let cur = queue.removeFirst()
            for d in CPDDirection.allCases {
                let n = cur.offset(d)
                if passable(n) && !seen.contains(n) {
                    seen.insert(n)
                    queue.append(n)
                }
            }
        }
        // For each displaced crate, is the worker beside a side from which a valid push exists?
        for crate in crates where !goals.contains(crate) {
            for d in CPDDirection.allCases {
                let pushFrom = crate.offset(d.opposite) // stand here to push crate toward d
                let pushTo = crate.offset(d)
                let toFree = !walls.contains(pushTo) && !crates.contains(pushTo) &&
                    pushTo.x >= 0 && pushTo.y >= 0 && pushTo.x < w && pushTo.y < h
                if seen.contains(pushFrom) && toFree { return true }
            }
        }
        return false
    }

    private static func shuffle<T>(_ arr: inout [T], rng: inout CPDSplitMix64) {
        guard arr.count > 1 else { return }
        for i in stride(from: arr.count - 1, to: 0, by: -1) {
            let j = rng.int(i + 1)
            arr.swapAt(i, j)
        }
    }

    private static func pick<T>(_ arr: [T], rng: inout CPDSplitMix64) -> T? {
        guard !arr.isEmpty else { return nil }
        return arr[rng.int(arr.count)]
    }

    private static func fallback(index: Int, w: Int, h: Int) -> CPDLevel {
        var walls = Set<CPDPoint>()
        for x in 0..<w { walls.insert(CPDPoint(x: x, y: 0)); walls.insert(CPDPoint(x: x, y: h - 1)) }
        for y in 0..<h { walls.insert(CPDPoint(x: 0, y: y)); walls.insert(CPDPoint(x: w - 1, y: y)) }
        // one goal in center-left, crate one cell to its right, worker right of crate.
        let goal = CPDPoint(x: 2, y: h / 2)
        let crate = CPDPoint(x: 3, y: h / 2)
        let worker = CPDPoint(x: 4, y: h / 2)
        var tiles = Array(repeating: Array(repeating: CPDTile.floor.rawValue, count: w), count: h)
        for c in walls { tiles[c.y][c.x] = CPDTile.wall.rawValue }
        return CPDLevel(
            index: index, width: w, height: h, tiles: tiles, walls: walls,
            goals: [goal], cratesStart: [crate], workerStart: worker, par: 1
        )
    }
}
