import Foundation

enum StartupPhase {
    case warming
    case native
    case experiment(ExperimentWebView)

    var isWarming: Bool {
        if case .warming = self { return true }
        return false
    }
}

@MainActor
@Observable
final class StartupRouter {
    private(set) var phase: StartupPhase = .warming

    private var didStart = false
    private var remoteContentFailed = false
    private var prewarmed: ExperimentWebView?
    
    private let coordinator: AnalyticsCoordinating
    private let session: AnalyticsSessionProviding

    init(dependencies: AppDependencies? = nil) {
        self.coordinator = dependencies?.analyticsCoordinator ?? AnalyticsCoordinator.shared
        self.session = dependencies?.analyticsSession ?? AnalyticsSession.shared
    }

    static func previewNative() -> StartupRouter {
        let router = StartupRouter()
        router.didStart = true
        router.phase = .native
        return router
    }

    func start() async {
        guard !didStart else { return }
        didStart = true

        guard !ProcessInfo.processInfo.arguments.contains("UI-Testing") else {
            phase = .native
            return
        }

        AnalyticsBootstrap.startIfNeeded()

        let warmup = Task {
            try? await Task.sleep(nanoseconds: Self.nanoseconds(AnalyticsTracker.minimumWarmup))
        }

        if let known = session.cachedRouteURL,
           await session.isOnline() {
            prewarm(known)
        }

        let decision = await Self.withDeadline(
            AnalyticsTracker.startupDeadline,
            fallback: TrackResult.nativeUI
        ) { [coordinator] in
            await coordinator.resolveResult()
        }

        await warmup.value

        guard case .experiment(let url) = decision, !remoteContentFailed else {
            settleOnNative()
            return
        }

        let webView = prewarm(url)
        await webView.waitUntilContentReady(timeout: AnalyticsTracker.experimentReadyCap)

        if remoteContentFailed {
            settleOnNative()
        } else {
            phase = .experiment(webView)
        }
    }

    func handleRemoteContentFailure() {
        remoteContentFailed = true
        settleOnNative()
    }

    @discardableResult
    private func prewarm(_ url: String) -> ExperimentWebView {
        if let existing = prewarmed, existing.contentURL == url {
            return existing
        }

        let webView = ExperimentWebView()
        webView.contentURL = url
        webView.onFailure = { [weak self] in
            self?.handleRemoteContentFailure()
        }
        webView.loadViewIfNeeded()
        prewarmed = webView
        return webView
    }

    private func settleOnNative() {
        prewarmed = nil
        phase = .native
    }

    private static func nanoseconds(_ seconds: TimeInterval) -> UInt64 {
        UInt64(seconds * 1_000_000_000)
    }

    private static func withDeadline<Value: Sendable>(
        _ seconds: TimeInterval,
        fallback: Value,
        operation: @escaping @Sendable () async -> Value
    ) async -> Value {
        await withTaskGroup(of: Value.self) { group in
            group.addTask { await operation() }
            group.addTask {
                try? await Task.sleep(nanoseconds: nanoseconds(seconds))
                return fallback
            }

            let first = await group.next() ?? fallback
            group.cancelAll()
            return first
        }
    }
}
