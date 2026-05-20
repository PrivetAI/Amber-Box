import SwiftUI
import WebKit

// Fullscreen / sheet WebView wrapper. Renamed per-app: cratePushDepot* prefix.
struct CratePushDepotWebPanel: UIViewRepresentable {
    let cratePushDepotURLString: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.contentInsetAdjustmentBehavior = .always
        webView.isOpaque = true
        webView.backgroundColor = UIColor(CPDPalette.background)
        if let url = URL(string: cratePushDepotURLString) {
            webView.load(URLRequest(url: url))
        }
        return webView
    }

    // MUST be empty — never reload on SwiftUI re-renders.
    func updateUIView(_ uiView: WKWebView, context: Context) {
    }
}
