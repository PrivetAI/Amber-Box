import SwiftUI

struct GameView: View {
    @EnvironmentObject var store: ABStore
    @Environment(\.presentationMode) private var presentationMode

    let levelIndex: Int
    @StateObject private var game: ABGameModel
    @State private var showWin = false
    @State private var goNext = false

    init(levelIndex: Int) {
        self.levelIndex = levelIndex
        let level = ABLevelCache.shared.level(levelIndex)
        _game = StateObject(wrappedValue: ABGameModel(level: level))
    }

    private var hasNext: Bool { levelIndex + 1 < ABStore.totalLevels }

    var body: some View {
        ZStack {
            ABBackground()
            GeometryReader { geo in
                gameBody(parentSize: geo.size)
            }

            if showWin {
                winOverlay
                    .transition(.opacity)
                    .zIndex(20)
            }

            // Hidden link to advance to the next level.
            NavigationLink(
                destination: nextLevelDestination,
                isActive: $goNext
            ) { EmptyView() }
            .hidden()
        }
        .navigationBarTitle("Level \(levelIndex + 1)", displayMode: .inline)
        .onChange(of: game.solved) { solved in
            if solved {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.25)) {
                    showWin = true
                }
            }
        }
    }

    @ViewBuilder
    private var nextLevelDestination: some View {
        if hasNext {
            GameView(levelIndex: levelIndex + 1)
        } else {
            EmptyView()
        }
    }

    // MARK: - Layout

    private func gameBody(parentSize: CGSize) -> some View {
        let isLandscape = parentSize.width > parentSize.height
        return Group {
            if isLandscape {
                HStack(spacing: 18) {
                    VStack(spacing: 14) {
                        hudBar
                        boardArea(parentSize: parentSize, landscape: true)
                    }
                    .frame(maxWidth: .infinity)
                    controlsColumn
                        .frame(width: min(parentSize.width * 0.34, 280))
                }
                .padding(16)
            } else {
                VStack(spacing: 16) {
                    hudBar
                    boardArea(parentSize: parentSize, landscape: false)
                    Spacer(minLength: 4)
                    controlsRow
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 12)
            }
        }
    }

    // MARK: - HUD

    private var hudBar: some View {
        HStack(spacing: 10) {
            hudStat(label: "MOVES", value: "\(game.moves)")
            hudStat(label: "PUSHES", value: "\(game.pushes)")
            hudStat(label: "PAR", value: "\(game.par)")
            hudStat(label: "PADS", value: "\(game.crateSeatedCount)/\(game.crateTotal)")
        }
    }

    private func hudStat(label: String, value: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 19, weight: .heavy, design: .rounded))
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
                .fill(ABPalette.panel)
        )
    }

    // MARK: - Board

    private func boardArea(parentSize: CGSize, landscape: Bool) -> some View {
        // reserve a square area for the board sized to available width/height
        let maxW = landscape ? parentSize.width * 0.60 : parentSize.width - 32
        let maxH = landscape ? parentSize.height - 80 : parentSize.height * 0.52
        let side = max(120, min(maxW, maxH))
        return ABBoardView(game: game, side: side, store: store)
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity)
    }

    // MARK: - Controls (portrait row layout)

    private var controlsRow: some View {
        HStack(alignment: .center, spacing: 18) {
            sideButton(icon: AnyView(ABUndoIcon(color: game.canUndo ? ABPalette.textPrimary : ABPalette.textMuted, size: 26)),
                       label: "Undo",
                       enabled: game.canUndo) {
                game.undo(store: store)
            }
            Spacer()
            dpad
            Spacer()
            sideButton(icon: AnyView(ABRestartIcon(color: ABPalette.textPrimary, size: 26)),
                       label: "Restart",
                       enabled: true) {
                game.restart(store: store)
            }
        }
        .padding(.horizontal, 6)
    }

    // MARK: - Controls (landscape column layout)

    private var controlsColumn: some View {
        VStack(spacing: 18) {
            dpad
            HStack(spacing: 14) {
                sideButton(icon: AnyView(ABUndoIcon(color: game.canUndo ? ABPalette.textPrimary : ABPalette.textMuted, size: 24)),
                           label: "Undo",
                           enabled: game.canUndo) {
                    game.undo(store: store)
                }
                sideButton(icon: AnyView(ABRestartIcon(color: ABPalette.textPrimary, size: 24)),
                           label: "Restart",
                           enabled: true) {
                    game.restart(store: store)
                }
            }
        }
    }

    private func sideButton(icon: AnyView, label: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 5) {
                ZStack {
                    Circle()
                        .fill(ABPalette.panel)
                        .frame(width: 56, height: 56)
                    icon
                }
                Text(label)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(enabled ? ABPalette.textSecondary : ABPalette.textMuted)
            }
        }
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.5)
    }

    // MARK: - D-pad

    private var dpad: some View {
        VStack(spacing: 6) {
            arrowButton(.up)
            HStack(spacing: 6) {
                arrowButton(.left)
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(ABPalette.panel.opacity(0.5))
                        .frame(width: 56, height: 56)
                    Circle()
                        .fill(ABPalette.panelRaised)
                        .frame(width: 16, height: 16)
                }
                arrowButton(.right)
            }
            arrowButton(.down)
        }
    }

    private func arrowButton(_ dir: ABDirection) -> some View {
        Button {
            _ = game.move(dir, store: store)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(ABPalette.panelRaised)
                    .frame(width: 56, height: 56)
                ABArrowShape()
                    .fill(ABPalette.accent)
                    .frame(width: 30, height: 30)
                    .rotationEffect(rotation(for: dir))
            }
        }
        .disabled(game.solved)
    }

    private func rotation(for dir: ABDirection) -> Angle {
        switch dir {
        case .up: return .degrees(0)
        case .right: return .degrees(90)
        case .down: return .degrees(180)
        case .left: return .degrees(270)
        }
    }

    // MARK: - Win overlay

    private var winOverlay: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 22) {
                Text("DEPOT CLEARED")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .tracking(1.5)
                    .foregroundColor(ABPalette.textPrimary)

                HStack(spacing: 14) {
                    ForEach(0..<3, id: \.self) { i in
                        ABStar(filled: i < game.currentStars, size: 46)
                            .scaleEffect(i < game.currentStars ? 1.0 : 0.82)
                    }
                }

                VStack(spacing: 6) {
                    statRow("Moves", "\(game.moves)")
                    statRow("Pushes", "\(game.pushes)")
                    statRow("Par", "\(game.par)")
                    if game.currentStars == 3 {
                        Text("Perfect — par or better!")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(ABPalette.success)
                    } else {
                        Text(starHint)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(ABPalette.textSecondary)
                    }
                }
                .padding(.vertical, 4)

                VStack(spacing: 10) {
                    if hasNext {
                        winButton(title: "Next Level", primary: true) {
                            goNext = true
                        }
                    }
                    winButton(title: "Replay", primary: false) {
                        withAnimation(.easeInOut(duration: 0.2)) { showWin = false }
                        game.restart(store: store)
                    }
                    winButton(title: "Level Map", primary: false) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .padding(28)
            .frame(maxWidth: 360)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(ABPalette.panel)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(ABPalette.accent.opacity(0.25), lineWidth: 1.5)
                    )
            )
            .padding(.horizontal, 28)
        }
    }

    private var starHint: String {
        let par = max(game.par, 1)
        let twoStar = Int((1.5 * Double(par)).rounded(.down))
        if game.currentStars == 2 {
            return "Solve in \(par) moves for 3★"
        }
        return "Solve in \(twoStar) for 2★, \(par) for 3★"
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(ABPalette.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundColor(ABPalette.textPrimary)
        }
        .frame(maxWidth: 200)
    }

    private func winButton(title: String, primary: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(primary ? ABPalette.backgroundDeep : ABPalette.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(primary ? ABPalette.accent : ABPalette.panelRaised)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Board view (grid + tiles + swipe gestures)

struct ABBoardView: View {
    @ObservedObject var game: ABGameModel
    let side: CGFloat
    let store: ABStore

    var body: some View {
        let cols = game.level.width
        let rows = game.level.height
        let cell = side / CGFloat(max(cols, rows))
        let boardW = cell * CGFloat(cols)
        let boardH = cell * CGFloat(rows)

        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(ABPalette.backgroundDeep)
                .frame(width: boardW + 14, height: boardH + 14)

            ZStack(alignment: .topLeading) {
                // floor + grid lines
                ForEach(0..<rows, id: \.self) { y in
                    ForEach(0..<cols, id: \.self) { x in
                        cellBackground(x: x, y: y, cell: cell)
                    }
                }
                // pads (drawn above floor, below crates)
                ForEach(Array(game.goals), id: \.self) { goal in
                    ABPadShape()
                        .frame(width: cell, height: cell)
                        .position(x: CGFloat(goal.x) * cell + cell / 2,
                                  y: CGFloat(goal.y) * cell + cell / 2)
                }
                // crates
                ForEach(Array(game.crates), id: \.self) { crate in
                    ABCrateShape(seated: game.isGoal(crate))
                        .frame(width: cell, height: cell)
                        .position(x: CGFloat(crate.x) * cell + cell / 2,
                                  y: CGFloat(crate.y) * cell + cell / 2)
                        .animation(.easeOut(duration: 0.12), value: game.crates)
                }
                // worker
                ABWorkerShape()
                    .frame(width: cell * 0.92, height: cell * 0.92)
                    .position(x: CGFloat(game.worker.x) * cell + cell / 2,
                              y: CGFloat(game.worker.y) * cell + cell / 2)
                    .animation(.easeOut(duration: 0.12), value: game.worker)
            }
            .frame(width: boardW, height: boardH)
        }
        .frame(width: side, height: side)
        .contentShape(Rectangle())
        .gesture(swipeGesture)
    }

    @ViewBuilder
    private func cellBackground(x: Int, y: Int, cell: CGFloat) -> some View {
        let p = ABPoint(x: x, y: y)
        let isWall = game.level.tiles[y][x] == ABTile.wall.rawValue
        Group {
            if isWall {
                ABWallShape()
            } else {
                Rectangle()
                    .fill((x + y) % 2 == 0 ? ABPalette.floor : ABPalette.floorAlt)
                    .overlay(Rectangle().stroke(ABPalette.gridLine, lineWidth: 0.5))
            }
        }
        .frame(width: cell, height: cell)
        .position(x: CGFloat(x) * cell + cell / 2, y: CGFloat(y) * cell + cell / 2)
        .id("cell-\(x)-\(y)-\(p.x)")
    }

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 18)
            .onEnded { value in
                let dx = value.translation.width
                let dy = value.translation.height
                guard abs(dx) > 14 || abs(dy) > 14 else { return }
                let dir: ABDirection
                if abs(dx) > abs(dy) {
                    dir = dx > 0 ? .right : .left
                } else {
                    dir = dy > 0 ? .down : .up
                }
                _ = game.move(dir, store: store)
            }
    }
}
