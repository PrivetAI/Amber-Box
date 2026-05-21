import SwiftUI

// All icons / art are custom SwiftUI Shapes — no SF Symbols, no emoji, no system images.

// MARK: - Worker

struct ABWorkerShape: View {
    var color: Color = ABPalette.worker
    var dark: Color = ABPalette.workerDark
    var visor: Color = ABPalette.workerVisor
    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            ZStack {
                // body / torso
                RoundedRectangle(cornerRadius: s * 0.18, style: .continuous)
                    .fill(color)
                    .frame(width: s * 0.62, height: s * 0.50)
                    .offset(y: s * 0.16)
                // shoulders shading
                RoundedRectangle(cornerRadius: s * 0.16, style: .continuous)
                    .fill(dark)
                    .frame(width: s * 0.62, height: s * 0.14)
                    .offset(y: s * 0.34)
                // helmet (hard hat)
                Path { p in
                    let w = s * 0.56
                    let cx = s * 0.5
                    let topY = s * 0.10
                    p.addArc(center: CGPoint(x: cx, y: topY + w * 0.34),
                             radius: w * 0.34,
                             startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false)
                    p.addLine(to: CGPoint(x: cx + w * 0.40, y: topY + w * 0.40))
                    p.addLine(to: CGPoint(x: cx - w * 0.40, y: topY + w * 0.40))
                    p.closeSubpath()
                }
                .fill(ABPalette.accent)
                // face plate
                Capsule()
                    .fill(visor)
                    .frame(width: s * 0.30, height: s * 0.12)
                    .offset(y: -s * 0.04)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

// MARK: - Crate (box with cross-bracing)

struct ABCrateShape: View {
    var seated: Bool = false
    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            let inset = s * 0.10
            let r = s * 0.10
            let base = seated ? ABPalette.crateOnPad : ABPalette.crate
            let edge = seated ? ABPalette.pad : ABPalette.crateDark
            let light = seated ? ABPalette.padGlow : ABPalette.crateLight
            ZStack {
                RoundedRectangle(cornerRadius: r, style: .continuous)
                    .fill(base)
                    .frame(width: s - inset * 2, height: s - inset * 2)
                // outer frame
                RoundedRectangle(cornerRadius: r, style: .continuous)
                    .stroke(edge, lineWidth: s * 0.06)
                    .frame(width: s - inset * 2, height: s - inset * 2)
                // cross bracing
                Path { p in
                    let a = inset + s * 0.04
                    let b = s - inset - s * 0.04
                    p.move(to: CGPoint(x: a, y: a))
                    p.addLine(to: CGPoint(x: b, y: b))
                    p.move(to: CGPoint(x: b, y: a))
                    p.addLine(to: CGPoint(x: a, y: b))
                }
                .stroke(edge, style: StrokeStyle(lineWidth: s * 0.05, lineCap: .round))
                // top highlight plank
                RoundedRectangle(cornerRadius: s * 0.03)
                    .fill(light)
                    .frame(width: s - inset * 2 - s * 0.18, height: s * 0.06)
                    .offset(y: -(s * 0.5 - inset - s * 0.13))
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

// MARK: - Target pad (ring)

struct ABPadShape: View {
    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            ZStack {
                Circle()
                    .fill(ABPalette.pad.opacity(0.16))
                    .frame(width: s * 0.66, height: s * 0.66)
                Circle()
                    .stroke(ABPalette.pad, lineWidth: s * 0.07)
                    .frame(width: s * 0.62, height: s * 0.62)
                Circle()
                    .stroke(ABPalette.padGlow.opacity(0.7), lineWidth: s * 0.03)
                    .frame(width: s * 0.36, height: s * 0.36)
                Circle()
                    .fill(ABPalette.padGlow)
                    .frame(width: s * 0.12, height: s * 0.12)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

// MARK: - Wall block

struct ABWallShape: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                Rectangle().fill(ABPalette.wall)
                // brick courses
                Path { p in
                    let rows = 3
                    for i in 1..<rows {
                        let y = h * CGFloat(i) / CGFloat(rows)
                        p.move(to: CGPoint(x: 0, y: y))
                        p.addLine(to: CGPoint(x: w, y: y))
                    }
                    // staggered verticals
                    for i in 0..<rows {
                        let y0 = h * CGFloat(i) / CGFloat(rows)
                        let y1 = h * CGFloat(i + 1) / CGFloat(rows)
                        let offset: CGFloat = (i % 2 == 0) ? w * 0.5 : w * 0.25
                        p.move(to: CGPoint(x: offset, y: y0))
                        p.addLine(to: CGPoint(x: offset, y: y1))
                        let offset2: CGFloat = (i % 2 == 0) ? w * 0.5 : w * 0.75
                        if offset2 != offset {
                            p.move(to: CGPoint(x: offset2, y: y0))
                            p.addLine(to: CGPoint(x: offset2, y: y1))
                        }
                    }
                }
                .stroke(ABPalette.wallEdge, lineWidth: max(1, w * 0.04))
                Rectangle()
                    .stroke(ABPalette.wallEdge, lineWidth: max(1, w * 0.05))
            }
        }
    }
}

// MARK: - D-pad arrow

struct ABArrowShape: Shape {
    // points up by default; rotate via view.
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.move(to: CGPoint(x: w * 0.5, y: h * 0.18))
        p.addLine(to: CGPoint(x: w * 0.82, y: h * 0.52))
        p.addLine(to: CGPoint(x: w * 0.62, y: h * 0.52))
        p.addLine(to: CGPoint(x: w * 0.62, y: h * 0.82))
        p.addLine(to: CGPoint(x: w * 0.38, y: h * 0.82))
        p.addLine(to: CGPoint(x: w * 0.38, y: h * 0.52))
        p.addLine(to: CGPoint(x: w * 0.18, y: h * 0.52))
        p.closeSubpath()
        return p
    }
}

// MARK: - Star

struct ABStarShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * 0.42
        let points = 5
        for i in 0..<(points * 2) {
            let r = (i % 2 == 0) ? outer : inner
            let angle = -Double.pi / 2 + Double(i) * Double.pi / Double(points)
            let pt = CGPoint(x: c.x + CGFloat(cos(angle)) * r, y: c.y + CGFloat(sin(angle)) * r)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }
}

struct ABStar: View {
    var filled: Bool
    var size: CGFloat
    var body: some View {
        ABStarShape()
            .fill(filled ? ABPalette.star : ABPalette.starEmpty)
            .overlay(
                ABStarShape().stroke(filled ? ABPalette.star.opacity(0.6) : ABPalette.starEmpty.opacity(0.6), lineWidth: 1)
            )
            .frame(width: size, height: size)
    }
}

// MARK: - Gear

struct ABGearShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * 0.72
        let teeth = 8
        let total = teeth * 2
        for i in 0..<total {
            let r = (i % 2 == 0) ? outer : inner
            let angle = Double(i) * 2 * Double.pi / Double(total)
            let pt = CGPoint(x: c.x + CGFloat(cos(angle)) * r, y: c.y + CGFloat(sin(angle)) * r)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        let holeR = outer * 0.34
        p.addEllipse(in: CGRect(x: c.x - holeR, y: c.y - holeR, width: holeR * 2, height: holeR * 2))
        return p
    }
}

struct ABGearIcon: View {
    var color: Color
    var size: CGFloat
    var body: some View {
        ABGearShape()
            .fill(style: FillStyle(eoFill: true))
            .foregroundColor(color)
            .frame(width: size, height: size)
    }
}

// MARK: - Lock

struct ABLockIcon: View {
    var color: Color
    var size: CGFloat
    var body: some View {
        ZStack {
            // shackle
            Path { p in
                let w = size, h = size
                p.addArc(center: CGPoint(x: w * 0.5, y: h * 0.42),
                         radius: w * 0.20,
                         startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false)
            }
            .stroke(color, lineWidth: size * 0.12)
            // body
            RoundedRectangle(cornerRadius: size * 0.12)
                .fill(color)
                .frame(width: size * 0.62, height: size * 0.46)
                .offset(y: size * 0.18)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Chevron

struct ABChevronShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.move(to: CGPoint(x: w * 0.3, y: h * 0.15))
        p.addLine(to: CGPoint(x: w * 0.7, y: h * 0.5))
        p.addLine(to: CGPoint(x: w * 0.3, y: h * 0.85))
        return p
    }
}

struct ABChevron: View {
    var color: Color
    var size: CGFloat
    var lineWidth: CGFloat = 2.4
    var body: some View {
        ABChevronShape()
            .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
            .frame(width: size, height: size)
    }
}

// MARK: - Undo arrow

struct ABUndoIcon: View {
    var color: Color
    var size: CGFloat
    var body: some View {
        ZStack {
            Path { p in
                let s = size
                p.addArc(center: CGPoint(x: s * 0.52, y: s * 0.52),
                         radius: s * 0.30,
                         startAngle: .degrees(150), endAngle: .degrees(20), clockwise: false)
            }
            .stroke(color, style: StrokeStyle(lineWidth: size * 0.11, lineCap: .round))
            // arrowhead at start (upper-left)
            Path { p in
                let s = size
                let tip = CGPoint(x: s * 0.22, y: s * 0.36)
                p.move(to: tip)
                p.addLine(to: CGPoint(x: tip.x + s * 0.02, y: tip.y - s * 0.20))
                p.move(to: tip)
                p.addLine(to: CGPoint(x: tip.x + s * 0.20, y: tip.y - s * 0.04))
            }
            .stroke(color, style: StrokeStyle(lineWidth: size * 0.11, lineCap: .round, lineJoin: .round))
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Restart arrow (circular)

struct ABRestartIcon: View {
    var color: Color
    var size: CGFloat
    var body: some View {
        ZStack {
            Path { p in
                let s = size
                p.addArc(center: CGPoint(x: s * 0.5, y: s * 0.5),
                         radius: s * 0.30,
                         startAngle: .degrees(-50), endAngle: .degrees(210), clockwise: false)
            }
            .stroke(color, style: StrokeStyle(lineWidth: size * 0.11, lineCap: .round))
            // arrowhead at end (upper-right)
            Path { p in
                let s = size
                let tip = CGPoint(x: s * 0.69, y: s * 0.24)
                p.move(to: tip)
                p.addLine(to: CGPoint(x: tip.x - s * 0.18, y: tip.y + s * 0.02))
                p.move(to: tip)
                p.addLine(to: CGPoint(x: tip.x + s * 0.02, y: tip.y + s * 0.20))
            }
            .stroke(color, style: StrokeStyle(lineWidth: size * 0.11, lineCap: .round, lineJoin: .round))
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Checkmark

struct ABCheckShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.move(to: CGPoint(x: w * 0.2, y: h * 0.55))
        p.addLine(to: CGPoint(x: w * 0.42, y: h * 0.76))
        p.addLine(to: CGPoint(x: w * 0.82, y: h * 0.28))
        return p
    }
}

// MARK: - Tab bar icons (custom Shapes — no SF Symbols, no emoji)

/// Play tab — a single-color crate glyph (box outline + cross bracing) that tints cleanly.
struct ABTabPlayIcon: View {
    var color: Color
    var size: CGFloat
    var body: some View {
        let s = size
        let inset = s * 0.12
        let r = s * 0.14
        let lw = max(1.6, s * 0.09)
        ZStack {
            RoundedRectangle(cornerRadius: r, style: .continuous)
                .stroke(color, lineWidth: lw)
                .frame(width: s - inset * 2, height: s - inset * 2)
            Path { p in
                let a = inset + s * 0.04
                let b = s - inset - s * 0.04
                p.move(to: CGPoint(x: a, y: a)); p.addLine(to: CGPoint(x: b, y: b))
                p.move(to: CGPoint(x: b, y: a)); p.addLine(to: CGPoint(x: a, y: b))
            }
            .stroke(color, style: StrokeStyle(lineWidth: lw * 0.85, lineCap: .round))
        }
        .frame(width: s, height: s)
    }
}

/// Challenges tab — a target-pad grid (2x2 mini pads) framed in `color`.
struct ABTabChallengeIcon: View {
    var color: Color
    var size: CGFloat
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.18, style: .continuous)
                .stroke(color, lineWidth: max(1.5, size * 0.09))
                .frame(width: size * 0.9, height: size * 0.9)
            let dot = size * 0.18
            let off = size * 0.2
            ForEach(0..<4, id: \.self) { i in
                Circle()
                    .fill(color)
                    .frame(width: dot, height: dot)
                    .offset(x: (i % 2 == 0 ? -off : off), y: (i < 2 ? -off : off))
            }
        }
        .frame(width: size, height: size)
    }
}

/// Awards tab — a star badge.
struct ABTabAwardsIcon: View {
    var color: Color
    var size: CGFloat
    var body: some View {
        ABStarShape()
            .fill(color)
            .frame(width: size, height: size)
    }
}

/// More tab — a gear.
struct ABTabMoreIcon: View {
    var color: Color
    var size: CGFloat
    var body: some View {
        ABGearIcon(color: color, size: size)
    }
}

// MARK: - Pack tier emblem (stacked crates, count = tier 1...4)

/// Difficulty-pack emblem: a stack of `tier` crate bars (1 = easiest, 4 = hardest), tinted by
/// the pack accent. Pure Shapes, no SF Symbols.
struct ABPackEmblem: View {
    var tier: Int       // 1...4
    var tint: Color
    var size: CGFloat
    var body: some View {
        let n = max(1, min(tier, 4))
        let gap = size * 0.10
        let barH = (size - gap * CGFloat(n - 1)) / CGFloat(n)
        VStack(spacing: gap) {
            ForEach(0..<n, id: \.self) { _ in
                RoundedRectangle(cornerRadius: barH * 0.28, style: .continuous)
                    .fill(tint)
                    .frame(width: size, height: barH)
                    .overlay(
                        RoundedRectangle(cornerRadius: barH * 0.28, style: .continuous)
                            .stroke(Color.black.opacity(0.18), lineWidth: max(1, size * 0.04))
                    )
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Streak flame (Daily / Endless)

/// A simple teardrop flame, used to mark streak counts. Drawn as a Shape (no emoji).
struct ABFlameShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.move(to: CGPoint(x: w * 0.5, y: 0))
        p.addQuadCurve(to: CGPoint(x: w, y: h * 0.62),
                       control: CGPoint(x: w * 1.02, y: h * 0.18))
        p.addQuadCurve(to: CGPoint(x: w * 0.5, y: h),
                       control: CGPoint(x: w * 0.94, y: h * 0.96))
        p.addQuadCurve(to: CGPoint(x: 0, y: h * 0.62),
                       control: CGPoint(x: w * 0.06, y: h * 0.96))
        p.addQuadCurve(to: CGPoint(x: w * 0.5, y: 0),
                       control: CGPoint(x: w * -0.02, y: h * 0.18))
        p.closeSubpath()
        return p
    }
}

struct ABStreakFlame: View {
    var color: Color
    var size: CGFloat
    var body: some View {
        ABFlameShape()
            .fill(color)
            .frame(width: size * 0.78, height: size)
    }
}

// MARK: - Achievement medal (unlocked state)

/// A circular medal with a ribbon notch and an embossed star, used for unlocked achievements.
/// Locked achievements use `ABLockIcon` instead. Pure Shapes — no SF Symbols / emoji.
struct ABMedalShape: View {
    var color: Color
    var size: CGFloat
    var body: some View {
        let s = size
        ZStack {
            // ribbon tails behind the disc
            Path { p in
                p.move(to: CGPoint(x: s * 0.30, y: s * 0.56))
                p.addLine(to: CGPoint(x: s * 0.18, y: s * 0.98))
                p.addLine(to: CGPoint(x: s * 0.40, y: s * 0.82))
                p.closeSubpath()
                p.move(to: CGPoint(x: s * 0.70, y: s * 0.56))
                p.addLine(to: CGPoint(x: s * 0.82, y: s * 0.98))
                p.addLine(to: CGPoint(x: s * 0.60, y: s * 0.82))
                p.closeSubpath()
            }
            .fill(color.opacity(0.55))
            // outer disc
            Circle()
                .fill(color)
                .frame(width: s * 0.72, height: s * 0.72)
                .offset(y: -s * 0.06)
            // inner ring
            Circle()
                .stroke(Color.black.opacity(0.18), lineWidth: max(1, s * 0.05))
                .frame(width: s * 0.58, height: s * 0.58)
                .offset(y: -s * 0.06)
            // embossed star
            ABStarShape()
                .fill(Color.white.opacity(0.92))
                .frame(width: s * 0.36, height: s * 0.36)
                .offset(y: -s * 0.06)
        }
        .frame(width: s, height: s)
    }
}

// MARK: - Small worker glyph for menu / header (logo-free abstract mark)

struct ABDepotMark: View {
    var size: CGFloat
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                .fill(ABPalette.panelRaised)
            ABCrateShape()
                .frame(width: size * 0.7, height: size * 0.7)
        }
        .frame(width: size, height: size)
    }
}
