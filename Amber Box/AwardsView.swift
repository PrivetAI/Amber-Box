import SwiftUI

/// Awards — a top Stats strip of summary chips plus a grid of achievement cards (medal when
/// unlocked, lock when not) with a live progress bar.
struct AwardsView: View {
    @EnvironmentObject var store: ABStore

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)

    var body: some View {
        ZStack {
            ABBackground()
            ScrollView {
                VStack(spacing: 18) {
                    header
                    statsStrip
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(ABAchievements.all) { ach in
                            achievementCard(ach)
                        }
                    }
                    Color.clear.frame(height: 8)
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            ABMedalShape(color: ABPalette.accent, size: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text("Awards")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(ABPalette.textPrimary)
                Text("\(store.unlocked.count) / \(ABAchievements.all.count) unlocked")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(ABPalette.textSecondary)
            }
            Spacer()
        }
        .padding(.vertical, 6)
    }

    // MARK: - Stats strip

    private var statsStrip: some View {
        let cols = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)
        return LazyVGrid(columns: cols, spacing: 10) {
            statChip(value: "\(store.totalStars)", label: "STARS")
            statChip(value: "\(store.levelsSolved)", label: "SOLVED")
            statChip(value: "\(store.threeStarCount)", label: "3★ LEVELS")
            statChip(value: "\(store.daily.bestStreak)", label: "DAILY BEST")
            statChip(value: "\(store.endless.bestStreak)", label: "ENDLESS")
            statChip(value: "\(store.stats.totalPushes)", label: "PUSHES")
        }
    }

    private func statChip(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundColor(ABPalette.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .tracking(0.8)
                .foregroundColor(ABPalette.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: ABMetrics.cornerSmall, style: .continuous)
                .fill(ABPalette.panel)
        )
    }

    // MARK: - Achievement card

    private func achievementCard(_ ach: ABAchievement) -> some View {
        let isUnlocked = store.unlocked.contains(ach.id)
        let raw = ach.progress(store)
        let current = max(0, min(raw, ach.goal))
        let fraction = ach.goal > 0 ? Double(current) / Double(ach.goal) : 0

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(isUnlocked ? ABPalette.accent.opacity(0.16) : ABPalette.panelRaised.opacity(0.5))
                        .frame(width: 44, height: 44)
                    if isUnlocked {
                        ABMedalShape(color: ABPalette.accent, size: 34)
                    } else {
                        ABLockIcon(color: ABPalette.lock, size: 22)
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(ach.title)
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundColor(isUnlocked ? ABPalette.textPrimary : ABPalette.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(ach.detail)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(ABPalette.textMuted)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }

            progressBar(fraction: fraction, unlocked: isUnlocked)

            Text("\(current) / \(ach.goal)")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(isUnlocked ? ABPalette.success : ABPalette.textMuted)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: ABMetrics.corner, style: .continuous)
                .fill(ABPalette.panel)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ABMetrics.corner, style: .continuous)
                .stroke(isUnlocked ? ABPalette.accent.opacity(0.35) : ABPalette.panelRaised.opacity(0.5), lineWidth: 1.5)
        )
    }

    private func progressBar(fraction: Double, unlocked: Bool) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(ABPalette.backgroundDeep)
                    .frame(height: 7)
                Capsule()
                    .fill(unlocked ? ABPalette.success : ABPalette.accent)
                    .frame(width: max(0, geo.size.width * CGFloat(min(max(fraction, 0), 1))), height: 7)
            }
        }
        .frame(height: 7)
    }
}
