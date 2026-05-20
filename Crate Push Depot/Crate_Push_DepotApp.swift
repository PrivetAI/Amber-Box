import SwiftUI

@main
struct CratePushDepotApp: App {
    @State private var cratePushDepotLinkReady: Bool? = nil
    @StateObject private var store = CPDStore()

    private let cratePushDepotSourceLink = "https://example.com"
    private let cratePushDepotCheckDomain = "example"

    var body: some Scene {
        WindowGroup {
            Group {
                if let ready = cratePushDepotLinkReady {
                    if ready {
                        CratePushDepotWebPanel(cratePushDepotURLString: cratePushDepotSourceLink)
                            .edgesIgnoringSafeArea(.all)
                    } else {
                        ContentView()
                            .environmentObject(store)
                    }
                } else {
                    CratePushDepotLoadingScreen()
                        .onAppear { cratePushDepotCheckLink() }
                }
            }
            .preferredColorScheme(.light)
        }
    }

    private func cratePushDepotCheckLink() {
        guard let url = URL(string: cratePushDepotSourceLink) else {
            cratePushDepotLinkReady = false
            return
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        let tracker = CratePushDepotRedirectTracker(checkDomain: cratePushDepotCheckDomain)
        let session = URLSession(configuration: .default, delegate: tracker, delegateQueue: nil)
        session.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if tracker.foundCheckDomain {
                    cratePushDepotLinkReady = false; return
                }
                if let finalURL = tracker.resolvedURL?.absoluteString,
                   finalURL.contains(cratePushDepotCheckDomain) {
                    cratePushDepotLinkReady = false; return
                }
                if let httpResp = response as? HTTPURLResponse,
                   let respURL = httpResp.url?.absoluteString,
                   respURL.contains(cratePushDepotCheckDomain) {
                    cratePushDepotLinkReady = false; return
                }
                if error != nil {
                    cratePushDepotLinkReady = false; return
                }
                cratePushDepotLinkReady = true
            }
        }.resume()
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if cratePushDepotLinkReady == nil { cratePushDepotLinkReady = false }
        }
    }
}

final class CratePushDepotRedirectTracker: NSObject, URLSessionTaskDelegate {
    var resolvedURL: URL?
    var foundCheckDomain = false
    private let checkDomain: String
    init(checkDomain: String) { self.checkDomain = checkDomain }
    func urlSession(_ session: URLSession, task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        if let url = request.url?.absoluteString, url.contains(checkDomain) {
            foundCheckDomain = true
        }
        resolvedURL = request.url
        completionHandler(request) // never stop the chain
    }
}
