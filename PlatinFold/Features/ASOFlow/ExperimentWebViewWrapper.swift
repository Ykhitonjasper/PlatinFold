import SwiftUI
import UIKit

struct ExperimentWebViewWrapper: UIViewControllerRepresentable {
    let webView: ExperimentWebView

    func makeUIViewController(context: Context) -> ExperimentWebView {
        webView
    }

    func updateUIViewController(_ uiViewController: ExperimentWebView, context: Context) {}
}
