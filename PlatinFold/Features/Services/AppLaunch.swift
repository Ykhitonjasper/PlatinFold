import Foundation

enum LaunchPhase {
    case loading(LaunchTier)
    case native
    case web(WebViewController)

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
}

/// How the launch cover is drawn while web warms underneath.
enum LaunchCoverStyle: Equatable {
    case branded
    case warm
    case scrim
    case invisible
}

@MainActor
@Observable
final class AppLaunch {
    private(set) var phase: LaunchPhase = .native
    private(set) var tier: LaunchTier = .cold
    private(set) var loaderProgress: Double = 0
    private(set) var loaderStage: LaunchLoaderStage = .idle
    private(set) var coverStyle: LaunchCoverStyle = .branded
    /// 1 = cover opaque, 0 = fully revealing web underneath.
    private(set) var coverOpacity: Double = 1

    /// Web view already loading under the splash so we never flash native tabs.
    private(set) var pendingWeb: WebViewController?

    private var didStart = false
    private var remoteContentFailed = false
    private var progressTicker: Task<Void, Never>?

    private let client: AppClientType
    private let session: AppSessionType

    init(dependencies: AppDependencies? = nil) {
        self.client = dependencies?.appClient ?? AppClient.shared
        self.session = dependencies?.appSession ?? AppSession.shared
        if session.isLocalOnly {
            phase = .native
            coverOpacity = 0
        } else {
            holdLoader()
        }
    }

    private func holdLoader() {
        tier = LaunchTier.resolve(
            cachedURL: session.cachedURL,
            launchCount: session.launchCount
        )
        coverStyle = Self.coverStyle(for: tier)
        phase = .loading(tier)
        coverOpacity = coverStyle == .invisible ? 0 : 1
        loaderStage = .starting
        loaderProgress = 0.08
    }

    private static func coverStyle(for tier: LaunchTier) -> LaunchCoverStyle {
        switch tier {
        case .cold: .branded
        case .warmFirst: .warm
        case .warmHot: .scrim
        }
    }

    static func previewNative() -> AppLaunch {
        let launch = AppLaunch()
        launch.didStart = true
        launch.phase = .native
        launch.coverOpacity = 0
        return launch
    }

    func start() async {
        guard !didStart else { return }
        didStart = true

        guard !ProcessInfo.processInfo.arguments.contains("UI-Testing") else {
            phase = .native
            coverOpacity = 0
            return
        }


        if session.isLocalOnly {
            showLocal()
            return
        }

        tier = LaunchTier.resolve(
            cachedURL: session.cachedURL,
            launchCount: session.launchCount
        )
        coverStyle = Self.coverStyle(for: tier)
        phase = .loading(tier)
        coverOpacity = 1
        loaderStage = .starting
        loaderProgress = max(loaderProgress, 0.08)

        Task.detached(priority: .utility) {
            DeviceInfo.prefetchAttributionToken()
        }

        let began = Date()
        let cached = session.cachedURL

        // One smooth bar for the whole boot — not tied to decide/probe steps.
        startSmoothProgress(since: began)

        loaderStage = .deciding

        guard await session.isOnline() else {
            await transitionToNative(began: began)
            session.recordLaunch()
            return
        }

        if let known = cached {
            pendingWeb = preload(known)
        }

        let client = self.client
        let decision = await Task.detached(priority: .utility) {
            await Self.withDeadline(
                Timeouts.decisionDeadline,
                fallback: LoadResult.local,
                operation: { await client.resolveResult() },
                onLateResult: { [weak self] late in
                    Task { @MainActor in self?.applyLateResult(late) }
                }
            )
        }.value


        guard case .web(let url) = decision, !remoteContentFailed else {
            await transitionToNative(began: began)
            session.recordLaunch()
            return
        }

        loaderStage = .loadingRoute
        let webView = preload(url)
        pendingWeb = webView

        let probeBegan = Date()
        let ready = await waitForContentReady(
            webView: webView,
            began: began
        )
        let probeElapsed = Date().timeIntervalSince(probeBegan)

        loaderStage = .finishing

        if remoteContentFailed {
            await transitionToNative(began: began)
            session.recordLaunch()
            return
        }

        guard ready else {
            await transitionToNative(began: began)
            session.recordLaunch()
            return
        }

        await revealWeb(webView, probeElapsed: probeElapsed, began: began)
        session.recordLaunch()
    }

    func handleRemoteContentFailure() {
        remoteContentFailed = true
        Task { @MainActor in
            stopProgressTicker()
            await transitionToNative(began: Date())
        }
    }

    // MARK: - Smooth splash progress (decoupled from network)

    /// Creep 8% → 85% over `coldSplashFeel` / warm cap, then ease toward 92% until finish.
    private func startSmoothProgress(since began: Date) {
        stopProgressTicker()
        let feel: TimeInterval =
            tier == .cold ? Timeouts.coldSplashFeel : max(tier.loaderMax * 0.55, 0.6)
        let hardCap = tier.loaderMax

        progressTicker = Task { @MainActor in
            while !Task.isCancelled {
                let elapsed = Date().timeIntervalSince(began)
                let primary = min(1, elapsed / max(feel, 0.01))
                let easedPrimary = 1 - pow(1 - primary, 1.55)
                var target = 0.08 + 0.77 * easedPrimary // → ~0.85

                if elapsed > feel {
                    let extra = min(1, (elapsed - feel) / max(hardCap - feel, 0.5))
                    target = 0.85 + 0.07 * (1 - pow(1 - extra, 1.4)) // → ~0.92
                }

                loaderProgress = max(loaderProgress, min(0.92, target))
                try? await Task.sleep(nanoseconds: 50_000_000)
            }
        }
    }

    private func stopProgressTicker() {
        progressTicker?.cancel()
        progressTicker = nil
    }

    private func honorMinimumSplash(began: Date) async {
        let floor = tier.loaderMin
        let elapsed = Date().timeIntervalSince(began)
        let remaining = floor - elapsed
        guard remaining > 0 else { return }
        try? await Task.sleep(nanoseconds: Self.nanoseconds(remaining))
    }

    // MARK: - Transitions

    private func transitionToNative(began: Date) async {
        stopProgressTicker()
        await honorMinimumSplash(began: began)

        if pendingWeb?.isPriming != true {
            pendingWeb?.detach()
        }
        pendingWeb = nil

        loaderStage = .complete
        loaderProgress = 1
        try? await Task.sleep(nanoseconds: Self.nanoseconds(0.15))

        phase = .native
        coverOpacity = 0
        try? await Task.sleep(nanoseconds: Self.nanoseconds(Timeouts.revealCrossfade))
        loaderStage = .idle
        loaderProgress = 0
    }

    private func revealWeb(
        _ webView: WebViewController,
        probeElapsed: TimeInterval,
        began: Date
    ) async {
        guard !remoteContentFailed else {
            await transitionToNative(began: began)
            return
        }

        pendingWeb = webView
        stopProgressTicker()
        await honorMinimumSplash(began: began)

        let instant =
            tier == .warmHot
            && probeElapsed < Timeouts.warm3InstantThreshold

        if instant {
            coverStyle = .invisible
            loaderProgress = 1
            coverOpacity = 0
            phase = .web(webView)
            pendingWeb = nil
            loaderStage = .idle
            return
        }

        if tier == .warmHot {
            coverStyle = .scrim
        }

        loaderStage = .complete
        loaderProgress = 1

        let fade: TimeInterval = {
            switch tier {
            case .warmHot: return Timeouts.warm3ScrimMax
            case .warmFirst: return Timeouts.warmRevealCrossfade
            case .cold: return Timeouts.revealCrossfade
            }
        }()

        coverOpacity = 0
        try? await Task.sleep(nanoseconds: Self.nanoseconds(fade))
        guard !remoteContentFailed else {
            await transitionToNative(began: began)
            return
        }

        phase = .web(webView)
        pendingWeb = nil
        loaderStage = .idle
    }

    private func waitForContentReady(
        webView: WebViewController,
        began: Date
    ) async -> Bool {
        let loaderMax = tier.loaderMax
        let probeBudget = tier.contentProbeWindow

        loaderStage = .preparingContent
        // Smooth ticker already running from start — don't restart/reset.

        let ready = await webView.waitUntilContentReady(timeout: probeBudget)
        if ready { return true }

        let elapsed = Date().timeIntervalSince(began)
        let remaining = loaderMax - elapsed
        guard remaining > 0 else { return false }

        return await webView.waitUntilContentReady(timeout: remaining)
    }

    // MARK: - Preload

    @discardableResult
    private func preload(_ url: String) -> WebViewController {
        if let existing = pendingWeb, existing.contentURL == url {
            return existing
        }
        pendingWeb?.detach()

        let webView = WebViewController(session: session)
        webView.contentURL = url
        webView.onFailure = { [weak self] in
            self?.handleRemoteContentFailure()
        }
        webView.loadViewIfNeeded()
        pendingWeb = webView
        return webView
    }

    private func applyLateResult(_ decision: LoadResult) {
        guard case .web(let url) = decision,
              !session.isLocalOnly else { return }

        let webView = WebViewController(session: session)
        webView.contentURL = url
        webView.loadViewIfNeeded()
        webView.primeInBackground()
    }

    private func showLocal() {
        stopProgressTicker()
        if pendingWeb?.isPriming != true {
            pendingWeb?.detach()
        }
        pendingWeb = nil
        phase = .native
        coverOpacity = 0
        loaderStage = .idle
        loaderProgress = 0
    }

    private static func withDeadline<Value: Sendable>(
        _ seconds: TimeInterval,
        fallback: Value,
        operation: @escaping @Sendable () async -> Value,
        onLateResult: @escaping @Sendable (Value) -> Void = { _ in }
    ) async -> Value {
        await withCheckedContinuation { (continuation: CheckedContinuation<Value, Never>) in
            let box = OneShotContinuation(continuation)
            Task.detached {
                let value = await operation()
                if !box.tryResume(value) { onLateResult(value) }
            }
            Task.detached {
                try? await Task.sleep(nanoseconds: nanoseconds(seconds))
                box.resume(fallback)
            }
        }
    }

    private static func nanoseconds(_ seconds: TimeInterval) -> UInt64 {
        UInt64(seconds * 1_000_000_000)
    }
}
