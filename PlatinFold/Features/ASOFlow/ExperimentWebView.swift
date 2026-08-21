import Foundation
import UIKit
import WebKit

public final class ExperimentWebView: UIViewController, WKNavigationDelegate, WKUIDelegate {

    private static let processPool = WKProcessPool()
    private static let websiteDataStore = WKWebsiteDataStore.default()

    private var mainWeb: WKWebView!
    private var overlayView: UIView?
    private var overlayWebView: WKWebView?
    private var didFailInitialLoad = false
    private var isContentReady = false
    private var readiness: OneShotContinuation<Void>?

    public var contentURL: String!
    public var onFailure: (() -> Void)?

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
        loadContent(contentURL)
    }

    public func waitUntilContentReady(timeout: TimeInterval) async {
        if isContentReady || didFailInitialLoad { return }

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let box = OneShotContinuation(continuation)
            readiness = box
            DispatchQueue.main.asyncAfter(deadline: .now() + timeout) { box.resume(()) }
        }
    }

    private func markContentReady() {
        isContentReady = true
        readiness?.resume(())
        readiness = nil
    }

    private func makeConfiguration() -> WKWebViewConfiguration {
        let config = WKWebViewConfiguration()
        config.processPool = Self.processPool
        config.websiteDataStore = Self.websiteDataStore
        config.preferences.javaScriptEnabled = true
        config.preferences.javaScriptCanOpenWindowsAutomatically = true

        let viewportScript = """
        var meta = document.createElement('meta');
        meta.name = 'viewport';
        meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
        document.getElementsByTagName('head')[0].appendChild(meta);
        """

        config.userContentController.addUserScript(
            WKUserScript(source: viewportScript, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        )

        return config
    }

    private func setupWebView() {
        mainWeb = WKWebView(frame: .zero, configuration: makeConfiguration())
        mainWeb.isOpaque = false
        mainWeb.backgroundColor = .systemBackground
        mainWeb.uiDelegate = self
        mainWeb.navigationDelegate = self
        mainWeb.allowsBackForwardNavigationGestures = true

        view.backgroundColor = .systemBackground
        view.addSubview(mainWeb)
        mainWeb.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mainWeb.topAnchor.constraint(equalTo: view.topAnchor),
            mainWeb.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            mainWeb.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mainWeb.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func loadContent(_ urlString: String) {
        guard !urlString.isEmpty,
              let decoded = urlString.removingPercentEncoding,
              let finalURL = URL(string: decoded) else { return }
        mainWeb.load(URLRequest(url: finalURL))
    }

    private func failInitialLoadToNative() {
        guard !didFailInitialLoad else { return }
        didFailInitialLoad = true
        AnalyticsSession.shared.clearCache()
        readiness?.resume(())
        readiness = nil
        onFailure?()
    }

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard webView === mainWeb else { return }
        if let finalUrl = webView.url?.absoluteString, !finalUrl.isEmpty {
            AnalyticsSession.shared.setFinalURLIfNeeded(finalUrl)
        }
        markContentReady()
    }

    public func webView(_ webView: WKWebView,
                        createWebViewWith config: WKWebViewConfiguration,
                        for navAction: WKNavigationAction,
                        windowFeatures: WKWindowFeatures) -> WKWebView? {
        markContentReady()
        config.processPool = Self.processPool
        config.websiteDataStore = Self.websiteDataStore
        let popup = WKWebView(frame: .zero, configuration: config)
        popup.navigationDelegate = self
        popup.uiDelegate = self
        presentPopupInOverlay(popup)
        return popup
    }

    public func webView(_ webView: WKWebView,
                        decidePolicyFor navigationAction: WKNavigationAction,
                        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        let scheme = url.scheme?.lowercased() ?? ""
        if ["mailto", "tel", "sms"].contains(scheme) {
            UIApplication.shared.open(url)
            decisionHandler(.cancel)
            return
        }

        decisionHandler(.allow)
    }

    public func webView(_ webView: WKWebView,
                        decidePolicyFor navigationResponse: WKNavigationResponse,
                        decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        if webView === mainWeb,
           let http = navigationResponse.response as? HTTPURLResponse,
           (400...599).contains(http.statusCode),
           !AnalyticsSession.shared.hasFinalURL {
            decisionHandler(.cancel)
            failInitialLoadToNative()
            return
        }

        decisionHandler(.allow)
    }

    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        guard webView === mainWeb, !AnalyticsSession.shared.hasFinalURL else { return }
        if (error as NSError).code == NSURLErrorCancelled { return }
        failInitialLoadToNative()
    }

    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        guard webView === mainWeb, !AnalyticsSession.shared.hasFinalURL else { return }
        if (error as NSError).code == NSURLErrorCancelled { return }
        failInitialLoadToNative()
    }

    private func presentPopupInOverlay(_ popup: WKWebView) {
        if overlayView != nil { closeOverlay() }

        let overlay = UIView()
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        overlay.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlay)
        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: view.topAnchor),
            overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        popup.translatesAutoresizingMaskIntoConstraints = false
        overlay.addSubview(popup)
        NSLayoutConstraint.activate([
            popup.topAnchor.constraint(equalTo: overlay.topAnchor),
            popup.bottomAnchor.constraint(equalTo: overlay.bottomAnchor),
            popup.leadingAnchor.constraint(equalTo: overlay.leadingAnchor),
            popup.trailingAnchor.constraint(equalTo: overlay.trailingAnchor)
        ])

        let close = makeCloseButton()
        overlay.addSubview(close)
        close.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            close.topAnchor.constraint(equalTo: overlay.safeAreaLayoutGuide.topAnchor, constant: 12),
            close.trailingAnchor.constraint(equalTo: overlay.trailingAnchor, constant: -16),
            close.widthAnchor.constraint(equalToConstant: 36),
            close.heightAnchor.constraint(equalToConstant: 36)
        ])

        overlayView = overlay
        overlayWebView = popup
    }

    private func makeCloseButton() -> UIButton {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "xmark"), for: .normal)
        btn.tintColor = .white
        btn.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        btn.layer.cornerRadius = 18
        btn.addTarget(self, action: #selector(closeOverlay), for: .touchUpInside)
        return btn
    }

    @objc private func closeOverlay() {
        overlayWebView?.stopLoading()
        overlayView?.removeFromSuperview()
        overlayWebView = nil
        overlayView = nil
    }

    public override var prefersStatusBarHidden: Bool { true }
}
