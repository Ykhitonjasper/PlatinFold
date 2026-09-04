import Foundation
import UIKit
import WebKit

public final class WebViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {

    private static let websiteDataStore = WKWebsiteDataStore.default()

    /// Presence-only handler. Main chrome user-scripts no-op unless this name
    /// exists, so `window.open` copies of the configuration can drop it and
    /// skip viewport/dark-paint without replacing the WKWebView configuration
    /// object (WebKit crashes if the returned view was built from another config).
    private final class LayoutHelper: NSObject, WKScriptMessageHandler {
        func userContentController(_ controller: WKUserContentController,
                                   didReceive message: WKScriptMessage) {}
    }

    private static func gatedForMain(_ source: String) -> String {
        """
        (function(){
          try {
            if (!window.webkit || !window.webkit.messageHandlers || !window.webkit.messageHandlers.page) return;
          } catch (e) { return; }
          \(source)
        })();
        """
    }

    /// Everything this controller waits on, in one place. The launch budgets it
    /// has to fit inside live in `Timeouts` and are shared with the
    /// router, so they are deliberately not duplicated here.
    enum Tuning {
        static let probeInterval: TimeInterval = 0.1

        /// A lone spinner scores 2 to 4, a page built from one large image
        /// scores 20, and anything carrying a sentence clears the bar on text
        /// alone. See `Scripts.contentProbe` for how the score is made.
        static let minimumContentScore = 15

        /// A page that opens a window and then abandons it leaves the overlay
        /// with nothing in it. That reads as a dimmed, broken page, and because
        /// the empty window is pinned edge to edge it also swallows every tap
        /// meant for the content underneath.
        static let popupFirstByteWindow: TimeInterval = 2.5

        /// A page can pass the probe and only then fall into a spinner. This
        /// second look happens after the view is on screen, so it costs the
        /// launch nothing.
        static let blankGrace: TimeInterval = 5.0
        static let readableTextFloor = 20

        /// SPA / late CSS often paints the real body colour after `didFinish`.
        /// A second adopt catches canvas/`underPage` before they look stale.
        static let backgroundAdoptRetry: TimeInterval = 0.7
    }

    /// Shared chrome colours for the WKWebView canvas and early document paint.
    enum Paint {
        /// Single source for Swift canvas and injected `html,body` CSS.
        static let fallbackHex = "0b0b0b"
        static let fallbackColor = UIColor(
            red: 11 / 255,
            green: 11 / 255,
            blue: 11 / 255,
            alpha: 1
        )
    }

    enum Scripts {
        /// Paints a dark document before site CSS loads so back-forward swipes
        /// and the first paint do not flash system white. Site rules may override.
        static var darkDocumentPaint: String {
            """
            (function(){
              var id = 'doc-bg';
              if (document.getElementById(id)) return;
              var s = document.createElement('style');
              s.id = id;
              s.textContent = 'html,body{background-color:#\(Paint.fallbackHex);}';
              (document.documentElement || document).appendChild(s);
            })();
            """
        }

        static let viewport = """
        (function(){
          var meta = document.querySelector('meta[name="viewport"]');
          if (!meta) {
            meta = document.createElement('meta');
            meta.name = 'viewport';
            (document.head || document.documentElement).appendChild(meta);
          }
          meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover';
        })();
        """

        /// Viewport helper only. Tab-bar insets come from
        /// `contentInsetAdjustmentBehavior = .never`, not DOM padding hacks.
        static let safeAreaStyle = """
        (function(){
          var id = 'safe-insets';
          if (document.getElementById(id)) return;
          var s = document.createElement('style');
          s.id = id;
          s.textContent = 'html{height:-webkit-fill-available;overscroll-behavior-y:none;}body{overscroll-behavior-y:none;}';
          (document.head || document.documentElement).appendChild(s);
        })();
        """

        /// Counting any element as content read a site stuck on its own loader
        /// as a live page, because a spinner is an element. Weighing the three
        /// kinds of evidence separately tells them apart: prose is worth most
        /// per unit, a block of layout barely registers, and media counts only
        /// when it is large enough to be content rather than a loading badge.
        static let contentProbe = """
        (function(){
          var b = document.body;
          if (!b) return 0;
          var text = (b.innerText || '').trim().length;
          var blocks = b.children.length;
          var media = 0;
          var nodes = document.querySelectorAll('img, video, canvas');
          for (var i = 0; i < nodes.length; i++) {
            if (nodes[i].clientWidth * nodes[i].clientHeight > 10000) media++;
          }
          return text + blocks * 2 + media * 20;
        })()
        """

        static let backgroundColour = """
        (function(){
          var c = getComputedStyle(document.documentElement).backgroundColor;
          if (!c || c === 'transparent' || c === 'rgba(0, 0, 0, 0)') {
            c = document.body ? getComputedStyle(document.body).backgroundColor : '';
          }
          return c || '';
        })()
        """

        static let textLength = "((document.body && document.body.innerText) || '').trim().length"

    }

    private var mainWeb: WKWebView!
    private var overlayView: UIView?
    private var overlayWebView: WKWebView?
    private var popupWatchdog: DispatchWorkItem?
    private var adoptBackgroundRetry: DispatchWorkItem?
    private var didCommitPopup = false
    private let layoutHelper = LayoutHelper()
    private let refresher = UIRefreshControl()

    private static let webSchemes: Set<String> = [
        "http", "https", "about", "blob", "data", "file", "ws", "wss"
    ]
    private var didFailInitialLoad = false
    private var didLoadMainFrame = false
    private var isContentReady = false
    private var isDetached = false
    public private(set) var isPriming = false
    /// Last JS content-probe score (need ≥ Tuning.minimumContentScore).
    public private(set) var lastContentScore: Int = 0

    /// True while WKWebView still has an in-flight main-frame navigation.
    public var isDocumentLoading: Bool { mainWeb.isLoading }
    private var probeDeadline: Date?
    private var probeGeneration = 0
    private var didRetryFromEntry = false
    private var didReloadBlank = false
    private var blankCheck: DispatchWorkItem?
    private var acceptsURLUpdates = true
    private var urlSaveDeadline: Date?
    private var readiness: OneShotContinuation<Void>?
    private let appSession: AppSessionType

    /// Top pin for the WKWebView — safe-area by default, edge when host matches token.
    private var webTopConstraint: NSLayoutConstraint?
    /// `true` = full-bleed under notch (page draws its own status chrome).
    private var usesEdgeToEdgeChrome = false

    public var contentURL: String!
    public var onFailure: (() -> Void)?

    public init(session: AppSessionType = AppSession.shared) {
        self.appSession = session
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        self.appSession = AppSession.shared
        super.init(coder: coder)
    }

    /// Pending timers would fire into a dead object, and an unanswered readiness
    /// wait would leave the launch task suspended for good. The web view's own
    /// delegates are weak, so they need no clearing here.
    deinit {
        blankCheck?.cancel()
        popupWatchdog?.cancel()
        adoptBackgroundRetry?.cancel()
        readiness?.resume(())
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
        urlSaveDeadline = Date().addingTimeInterval(Timeouts.startup)
        loadContent(contentURL)
    }

    public func waitUntilContentReady(timeout: TimeInterval) async -> Bool {
        if didFailInitialLoad { return false }
        if isContentReady { return true }

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let box = OneShotContinuation(continuation)
            readiness = box
            DispatchQueue.main.asyncAfter(deadline: .now() + timeout) { box.resume(()) }
        }

        if isContentReady && !didFailInitialLoad {
            return true
        }
        // A slow network is not evidence of a dead route, so running out of
        // launch budget costs this launch alone and leaves the commit standing.
        primeInBackground()
        return false
    }

    /// The chain is usually only a second short when the budget runs out.
    /// Letting it finish off-screen turns a lost launch into a stored route
    /// instead of making the next launch start the whole chain over. The timer
    /// holds a strong reference on purpose: the router drops this controller the
    /// moment it settles on native, and the load has to outlive that.
    public func primeInBackground() {
        guard !didFailInitialLoad, !isDetached, !isPriming else {
            detach()
            return
        }
        isPriming = true
        onFailure = nil
        readiness?.resume(())
        readiness = nil
        urlSaveDeadline = Date().addingTimeInterval(Timeouts.primingWindow)

        DispatchQueue.main.asyncAfter(deadline: .now() + Timeouts.primingWindow) {
            self.detach()
        }
    }

    public func detach() {
        isDetached = true
        isPriming = false
        onFailure = nil
        readiness?.resume(())
        readiness = nil
        blankCheck?.cancel()
        blankCheck = nil
        popupWatchdog?.cancel()
        popupWatchdog = nil
        mainWeb?.stopLoading()
    }

    private func markContentReady() {
        isContentReady = true
        readiness?.resume(())
        readiness = nil
    }

    private func makeConfiguration() -> WKWebViewConfiguration {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = Self.websiteDataStore
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        config.preferences.javaScriptCanOpenWindowsAutomatically = true

        // Gate: popup configs remove `page` so these scripts become no-ops there.
        config.userContentController.add(layoutHelper, name: "page")
        config.userContentController.addUserScript(
            WKUserScript(source: Self.gatedForMain(Scripts.darkDocumentPaint), injectionTime: .atDocumentStart, forMainFrameOnly: true)
        )
        config.userContentController.addUserScript(
            WKUserScript(source: Self.gatedForMain(Scripts.viewport), injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        )
        config.userContentController.addUserScript(
            WKUserScript(source: Self.gatedForMain(Scripts.safeAreaStyle), injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        )

        return config
    }

    /// Softens the system home-indicator “stick” that makes a WKWebView feel
    /// like Safari: it auto-hides until the user interacts near the bottom edge.
    public override var prefersHomeIndicatorAutoHidden: Bool { true }

    private func setupWebView() {
        // Dark canvas until the page reports a real (non-white) body colour.
        let canvas = Paint.fallbackColor

        mainWeb = WKWebView(frame: .zero, configuration: makeConfiguration())
        mainWeb.isOpaque = true
        mainWeb.backgroundColor = canvas
        mainWeb.scrollView.backgroundColor = canvas
        if #available(iOS 15.0, *) {
            // Colour shown during interactive back/forward swipe between pages.
            mainWeb.underPageBackgroundColor = canvas
        }
        mainWeb.uiDelegate = self
        mainWeb.navigationDelegate = self
        mainWeb.allowsBackForwardNavigationGestures = true

        refresher.tintColor = .systemGray
        refresher.addTarget(self, action: #selector(reloadFromPull), for: .valueChanged)
        // Automatic insets shrink the web layout viewport so `position:fixed;
        // bottom:0` sits above the home-indicator band and our canvas shows
        // through as a black strip under the tab bar.
        mainWeb.scrollView.contentInsetAdjustmentBehavior = .never
        mainWeb.scrollView.bounces = true
        mainWeb.scrollView.alwaysBounceVertical = false
        mainWeb.scrollView.showsVerticalScrollIndicator = false
        mainWeb.scrollView.showsHorizontalScrollIndicator = false
        mainWeb.scrollView.refreshControl = refresher

        view.backgroundColor = canvas
        view.addSubview(mainWeb)
        mainWeb.translatesAutoresizingMaskIntoConstraints = false

        // Default: top under safe area (headers clear Dynamic Island). Bottom
        // stays edge-to-edge so fixed tab bars sit flush. Matching hosts flip
        // top to edge once committed — those pages paint their own status chrome.
        let top = mainWeb.topAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.topAnchor
        )
        webTopConstraint = top
        NSLayoutConstraint.activate([
            top,
            mainWeb.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            mainWeb.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mainWeb.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        if let seed = contentURL {
            applyChromeInsets(for: Self.resolveURL(from: seed))
        }
    }

    /// Some destinations already inset for the notch in CSS — full-bleed only
    /// for those hosts. Everyone else gets a native top safe-area band.
    static func usesEdgeToEdgeChrome(host: String?) -> Bool {
        guard let host = host?.lowercased(), !host.isEmpty else { return false }
        let token = AppKeys.edgeChromeHostToken
        guard !token.isEmpty else { return false }
        return host.contains(token)
    }

    private func applyChromeInsets(for url: URL?) {
        let edge = Self.usesEdgeToEdgeChrome(host: url?.host)
        guard edge != usesEdgeToEdgeChrome || webTopConstraint == nil else { return }
        usesEdgeToEdgeChrome = edge

        webTopConstraint?.isActive = false
        let anchor = edge ? view.topAnchor : view.safeAreaLayoutGuide.topAnchor
        let top = mainWeb.topAnchor.constraint(equalTo: anchor)
        webTopConstraint = top
        top.isActive = true
        view.setNeedsLayout()
        setNeedsStatusBarAppearanceUpdate()
    }

    static func resolveURL(from raw: String) -> URL? {
        guard !raw.isEmpty else { return nil }
        if let direct = URL(string: raw), direct.scheme != nil { return direct }
        guard let decoded = raw.removingPercentEncoding else { return nil }
        return URL(string: decoded)
    }

    @discardableResult
    private func loadContent(_ urlString: String) -> Bool {
        guard let url = Self.resolveURL(from: urlString) else { return false }
        mainWeb.load(URLRequest(url: url))
        return true
    }

    /// A document that never filled is not evidence that the route is dead: a
    /// slow destination reads the same as a broken one from here. Only answers
    /// the network gave us outright — a refusal or an error status — count
    /// towards locking the app to its native UI, so a run of slow launches can
    /// no longer throw away a working cached route.
    private func failInitialLoadToNative(countsTowardsLock: Bool = true) {
        guard !didFailInitialLoad, !isDetached else { return }
        if retryFromEntryURL() { return }
        didFailInitialLoad = true
        if countsTowardsLock {
            appSession.markMiss()
        }
        readiness?.resume(())
        readiness = nil
        onFailure?()
    }

    /// Retry the original entry if the cached destination failed.
    private func retryFromEntryURL() -> Bool {
        guard !didRetryFromEntry,
              let entry = appSession.clearURLForRetry() else { return false }
        didRetryFromEntry = true
        didLoadMainFrame = false
        probeDeadline = nil
        probeGeneration += 1
        return loadContent(entry)
    }

    @objc private func reloadFromPull() {
        mainWeb.reload()
    }

    /// Reads `html`/`body` background and paints the WKWebView canvas to match.
    /// Whitish/transparent bodies keep `Paint.fallbackColor` so safe-area
    /// bands do not flash system white.
    private func adoptPageBackground() {
        guard mainWeb != nil else { return }
        mainWeb.evaluateJavaScript(Scripts.backgroundColour) { [weak self] value, _ in
            guard let self else { return }
            let parsed = (value as? String).flatMap(Self.colour(fromCSS:))
            let colour: UIColor
            if let parsed, !Self.isWhitish(parsed) {
                colour = parsed
            } else {
                colour = Paint.fallbackColor
            }
            self.view.backgroundColor = colour
            self.mainWeb.backgroundColor = colour
            self.mainWeb.scrollView.backgroundColor = colour
            if #available(iOS 15.0, *) {
                self.mainWeb.underPageBackgroundColor = colour
            }
        }
    }

    /// Immediate adopt, then one retry so late SPA/CSS colour still lands on
    /// the canvas. A newer navigation cancels the pending retry.
    private func scheduleAdoptPageBackground() {
        adoptPageBackground()
        adoptBackgroundRetry?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.adoptPageBackground()
        }
        adoptBackgroundRetry = work
        DispatchQueue.main.asyncAfter(
            deadline: .now() + Tuning.backgroundAdoptRetry,
            execute: work
        )
    }

    /// A fully transparent background says nothing about what is painted over
    /// it, so it is left alone rather than turned into black.
    static func colour(fromCSS css: String) -> UIColor? {
        let text = css.lowercased()
        guard text.hasPrefix("rgb") else { return nil }
        let parts = text
            .components(separatedBy: CharacterSet(charactersIn: "0123456789.").inverted)
            .filter { !$0.isEmpty }
            .compactMap(Double.init)
        guard parts.count >= 3 else { return nil }
        if parts.count >= 4, parts[3] == 0 { return nil }
        return UIColor(red: parts[0] / 255, green: parts[1] / 255, blue: parts[2] / 255, alpha: 1)
    }

    static func isWhitish(_ colour: UIColor) -> Bool {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard colour.getRed(&r, green: &g, blue: &b, alpha: &a) else { return false }
        return r > 0.98 && g > 0.98 && b > 0.98
    }

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if webView === mainWeb { refresher.endRefreshing() }
        guard webView === mainWeb, !didFailInitialLoad else { return }
        scheduleAdoptPageBackground()
        didLoadMainFrame = true

        guard shouldVerifyDocument(webView.url) else {
            commitAndFinish()
            return
        }

        let deadline = probeDeadline ?? Date().addingTimeInterval(Timeouts.contentProbeWindow)
        probeDeadline = deadline
        probeGeneration += 1
        probeForContent(webView, generation: probeGeneration, deadline: deadline)
    }

    /// A JavaScript-rendered destination still has an empty body when the main
    /// frame reports `didFinish`, so a single sample reads a live page as blank.
    /// Sample until content shows up and only give up once the window is spent.
    private func probeForContent(_ webView: WKWebView, generation: Int, deadline: Date) {
        webView.evaluateJavaScript(Scripts.contentProbe) { [weak self] value, _ in
            guard let self,
                  generation == self.probeGeneration,
                  !self.didFailInitialLoad,
                  !self.isDetached else { return }

            let score = value as? Int ?? 0
            self.lastContentScore = score

            if score >= Tuning.minimumContentScore {
                self.commitAndFinish()
                return
            }
            guard Date() < deadline else {
                self.failInitialLoadToNative(countsTowardsLock: false)
                return
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + Tuning.probeInterval) {
                self.probeForContent(webView, generation: generation, deadline: deadline)
            }
        }
    }

    private func shouldVerifyDocument(_ url: URL?) -> Bool {
        guard !isContentReady, let scheme = url?.scheme?.lowercased() else { return false }
        return scheme == "http" || scheme == "https"
    }

    private func commitAndFinish() {
        guard !didFailInitialLoad, !isDetached else { return }
        appSession.markReady()
        keepSavedURLIfNeeded()
        markContentReady()
        scheduleEmptyDocumentCheck()
    }

    /// A page that passed the probe can still fall into a spinner afterwards, so
    /// it gets one more look once it is on screen. One attempt only: a page that
    /// is genuinely wordless must not be reloaded in a loop.
    static func shouldReload(textLength: Int, alreadyReloaded: Bool) -> Bool {
        !alreadyReloaded && textLength < Tuning.readableTextFloor
    }

    private func scheduleEmptyDocumentCheck() {
        guard !didReloadBlank, blankCheck == nil else { return }
        let work = DispatchWorkItem { [weak self] in self?.reloadIfDocumentStillEmpty() }
        blankCheck = work
        DispatchQueue.main.asyncAfter(deadline: .now() + Tuning.blankGrace, execute: work)
    }

    private func reloadIfDocumentStillEmpty() {
        blankCheck = nil
        // A navigation in flight may well be the content arriving.
        guard !isDetached, !didFailInitialLoad, !mainWeb.isLoading else { return }

        mainWeb.evaluateJavaScript(Scripts.textLength) { [weak self] value, _ in
            guard let self,
                  let length = value as? Int,
                  Self.shouldReload(textLength: length, alreadyReloaded: self.didReloadBlank)
            else { return }
            self.didReloadBlank = true
            self.mainWeb.reload()
        }
    }

    /// Keep the first address that actually rendered content.
    private func keepSavedURLIfNeeded() {
        guard acceptsURLUpdates,
              let settled = mainWeb.url?.absoluteString,
              !settled.isEmpty else { return }

        acceptsURLUpdates = false
        if let deadline = urlSaveDeadline, Date() > deadline { return }
        appSession.storeDestination(settled)
    }

    public func webView(_ webView: WKWebView,
                        createWebViewWith config: WKWebViewConfiguration,
                        for navAction: WKNavigationAction,
                        windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard !didFailInitialLoad, !isDetached else { return nil }
        commitAndFinish()
        config.websiteDataStore = Self.websiteDataStore

        // Must build the returned WKWebView with *this* configuration object.
        // Drop the main-chrome gate so gated scripts no-op in the child window.
        config.userContentController.removeScriptMessageHandler(forName: "page")

        let popup = WKWebView(frame: .zero, configuration: config)
        popup.isOpaque = true
        popup.backgroundColor = .black
        popup.scrollView.backgroundColor = .black
        popup.scrollView.contentInsetAdjustmentBehavior = .automatic
        popup.scrollView.showsVerticalScrollIndicator = false
        popup.scrollView.showsHorizontalScrollIndicator = false
        if #available(iOS 15.0, *) {
            popup.underPageBackgroundColor = .black
        }
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

        // Redirects report `.other`; anything else is the user driving, and
        // their taps must not overwrite the route the next launch opens.
        if webView === mainWeb, navigationAction.navigationType != .other {
            acceptsURLUpdates = false
        }

        // WebKit can load only its own schemes. A wallet, phone, or App Store
        // link has to be handed to the system, otherwise the navigation dies
        // quietly and the page is left looking jammed with no way to tell why.
        let scheme = url.scheme?.lowercased() ?? ""
        if !scheme.isEmpty, !Self.webSchemes.contains(scheme) {
            UIApplication.shared.open(url)
            decisionHandler(.cancel)
            // A window opened only to fire this link has nothing to show and is
            // taken down. One that already loaded a page keeps it, because that
            // is the status screen the user comes back to from the bank app.
            if webView === overlayWebView, !didCommitPopup { closeOverlay() }
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
           !didLoadMainFrame {
            decisionHandler(.cancel)
            failInitialLoadToNative()
            return
        }

        decisionHandler(.allow)
    }

    /// `window.open()` with no address commits `about:blank` at once, and a page
    /// that means to fill that blank by script may never come back to it. Only a
    /// real destination counts as a window worth keeping on screen.
    public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        if webView === mainWeb {
            // Drop a stale retry from the previous document, then sample early so
            // in-app navigations do not keep the last page's canvas colour.
            adoptBackgroundRetry?.cancel()
            adoptPageBackground()
            applyChromeInsets(for: webView.url)
            return
        }
        guard webView === overlayWebView else { return }
        let settled = webView.url?.absoluteString ?? ""
        guard !settled.isEmpty, settled != "about:blank" else { return }
        didCommitPopup = true
        popupWatchdog?.cancel()
        popupWatchdog = nil
    }

    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        handleNavigationError(error, for: webView)
    }

    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handleNavigationError(error, for: webView)
    }

    /// A cancelled navigation is almost always one this code replaced itself, so
    /// it is not news. Anything else that dies before the main frame ever loaded
    /// is the route failing.
    private func handleNavigationError(_ error: Error, for webView: WKWebView) {
        let cancelled = (error as NSError).code == NSURLErrorCancelled

        // A window that cannot even reach its destination has nothing to show,
        // so it goes away rather than sitting on the content as a dark pane.
        if webView === overlayWebView {
            if !cancelled { closeOverlay() }
            return
        }

        guard webView === mainWeb else { return }
        refresher.endRefreshing()
        guard !didLoadMainFrame, !cancelled else { return }
        failInitialLoadToNative()
    }

    /// A site that calls `window.close()` on the window it opened expects it to
    /// go away. Without this the overlay stays up and the flow that opened it
    /// looks like it did nothing.
    public func webViewDidClose(_ webView: WKWebView) {
        guard webView === overlayWebView else { return }
        closeOverlay()
    }

    /// WebKit shows no dialog at all when a UI delegate is set but leaves these
    /// unimplemented: `alert` is swallowed, `confirm` answers no and `prompt`
    /// answers nothing. Pages that put a form behind those dialogs would then
    /// take the cancelled branch with no visible reason.
    public func webView(_ webView: WKWebView,
                        runJavaScriptAlertPanelWithMessage message: String,
                        initiatedByFrame frame: WKFrameInfo,
                        completionHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler() })
        present(orRunImmediately: alert, fallback: completionHandler)
    }

    public func webView(_ webView: WKWebView,
                        runJavaScriptConfirmPanelWithMessage message: String,
                        initiatedByFrame frame: WKFrameInfo,
                        completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(false) })
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler(true) })
        present(orRunImmediately: alert) { completionHandler(false) }
    }

    public func webView(_ webView: WKWebView,
                        runJavaScriptTextInputPanelWithPrompt prompt: String,
                        defaultText: String?,
                        initiatedByFrame frame: WKFrameInfo,
                        completionHandler: @escaping (String?) -> Void) {
        let alert = UIAlertController(title: nil, message: prompt, preferredStyle: .alert)
        alert.addTextField { $0.text = defaultText }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(nil) })
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak alert] _ in
            completionHandler(alert?.textFields?.first?.text)
        })
        present(orRunImmediately: alert) { completionHandler(nil) }
    }

    /// A dialog raised while this controller is off-screen, or while something
    /// else is already presented, cannot be shown. Answering the page straight
    /// away keeps its script running instead of leaving it waiting forever.
    private func present(orRunImmediately alert: UIAlertController,
                         fallback: @escaping () -> Void) {
        guard view.window != nil, presentedViewController == nil else {
            fallback()
            return
        }
        present(alert, animated: true)
    }

    private func presentPopupInOverlay(_ popup: WKWebView) {
        if overlayView != nil { closeOverlay() }

        didCommitPopup = false
        let watchdog = DispatchWorkItem { [weak self] in
            guard let self, !self.didCommitPopup else { return }
            self.closeOverlay()
        }
        popupWatchdog = watchdog
        DispatchQueue.main.asyncAfter(deadline: .now() + Tuning.popupFirstByteWindow, execute: watchdog)

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
        popupWatchdog?.cancel()
        popupWatchdog = nil
        didCommitPopup = false
        overlayWebView?.stopLoading()
        overlayView?.removeFromSuperview()
        overlayWebView = nil
        overlayView = nil
    }

    /// Edge-chrome hosts paint their own clock row; other offers leave a top
    /// band — show the system status bar there so the gap is not a dead strip.
    public override var prefersStatusBarHidden: Bool { usesEdgeToEdgeChrome }

    public override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
}
