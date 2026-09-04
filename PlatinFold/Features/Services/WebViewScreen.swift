import SwiftUI
import UIKit

struct WebViewScreen: UIViewControllerRepresentable {
    let webView: WebViewController

    func makeUIViewController(context: Context) -> WebViewController {
        webView
    }

    func updateUIViewController(_ uiViewController: WebViewController, context: Context) {}
}
