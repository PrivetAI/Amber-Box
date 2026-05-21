import SwiftUI

// Levels are generated once and cached for the whole session (deterministic anyway).
final class ABLevelCache {
    static let shared = ABLevelCache()
    private var cache: [Int: ABLevel] = [:]
    func level(_ index: Int) -> ABLevel {
        if let l = cache[index] { return l }
        let l = ABLevelGenerator.generate(index: index)
        cache[index] = l
        return l
    }
}

struct ContentView: View {
    @EnvironmentObject var store: ABStore
    @State private var showOnboarding = false

    var body: some View {
        ZStack {
            NavigationView {
                ChapterMapView()
            }
            .navigationViewStyle(StackNavigationViewStyle())

            if showOnboarding {
                OnboardingView(isPresented: $showOnboarding)
                    .transition(.opacity)
                    .zIndex(10)
            }
        }
        .onAppear {
            if !store.onboardingDone {
                showOnboarding = true
            }
        }
    }
}
