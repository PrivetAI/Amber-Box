import SwiftUI

// Levels are generated once and cached for the whole session (deterministic anyway).
final class CPDLevelCache {
    static let shared = CPDLevelCache()
    private var cache: [Int: CPDLevel] = [:]
    func level(_ index: Int) -> CPDLevel {
        if let l = cache[index] { return l }
        let l = CPDLevelGenerator.generate(index: index)
        cache[index] = l
        return l
    }
}

struct ContentView: View {
    @EnvironmentObject var store: CPDStore
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
