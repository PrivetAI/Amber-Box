import Foundation

/// Parameters that fully determine a generated Sokoban level's difficulty.
struct ABDifficultyProfile: Equatable {
    let gridSize: Int        // square board side (interior playfield)
    let crates: Int          // number of crates / target pads
    let scrambleDepth: Int   // reverse-construction pull count (raises par/complexity)
    let wallDensity: Double   // 0...0.35 fraction of interior cells that become walls
}

/// Where a GameView session comes from — drives progress recording, the win-overlay
/// buttons, and the "next" provider.
enum ABGameSource: Equatable {
    case campaign(index: Int)        // existing 120-level campaign
    case pack(id: String, index: Int) // difficulty pack level
    case daily(dateKey: Int)         // one-per-day puzzle
    case endless(streak: Int)        // current endless run position
}
