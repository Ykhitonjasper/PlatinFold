import SwiftUI

struct RootView: View {
    private let dependencies: AppDependencies
    @Bindable private var store: MixStore
    @State private var launch: AppLaunch
    @StateObject private var appCover = AppCover()
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @MainActor
    init(dependencies: AppDependencies, launch: AppLaunch? = nil) {
        self.dependencies = dependencies
        store = dependencies.store
        _launch = State(initialValue: launch ?? AppLaunch(dependencies: dependencies))
    }

    var body: some View {
        ZStack {
            if let webView = displayedWeb {
                coveredWebView(webView)
                    .scaleEffect(webSettleScale)
            } else if case .native = launch.phase {
                if store.hasCompletedOnboarding {
                    tabShell
                } else {
                    OnboardingScreen(dependencies: dependencies)
                }
            } else {
                AppTheme.bgBase.ignoresSafeArea()
            }
        }
        .overlay {
            loaderOverlay
        }
        .environment(store)
        .tint(AppTheme.accent)
        .sensoryFeedback(.impact(weight: .medium), trigger: launch.loaderProgress >= 1)
        .task { await launch.start() }
    }

    /// Page sits slightly large under the cover, then settles as the veil lifts.
    private var webSettleScale: CGFloat {
        guard launch.phase.isLoading || launch.coverOpacity > 0.02 else { return 1 }
        return 1 + CGFloat(launch.coverOpacity) * 0.018
    }

    /// Same WKWebView instance from preload through reveal — no remount flash.
    private var displayedWeb: WebViewController? {
        if case .web(let webView) = launch.phase { return webView }
        return launch.pendingWeb
    }

    private var revealAnimation: Animation? {
        guard !reduceMotion else { return nil }
        return .timingCurve(0.16, 1.0, 0.3, 1.0, duration: revealDuration)
    }

    private var revealDuration: TimeInterval {
        switch launch.coverStyle {
        case .scrim: return Timeouts.warm3ScrimMax
        case .warm: return Timeouts.warmRevealCrossfade
        case .branded, .invisible: return Timeouts.revealCrossfade
        }
    }

    @ViewBuilder
    private var loaderOverlay: some View {
        let veil = launch.coverOpacity
        Group {
            switch launch.phase {
            case .loading:
                switch launch.coverStyle {
                case .branded:
                    BrandedSplash(progress: launch.loaderProgress, veil: veil)
                case .warm:
                    WarmOverlay(progress: launch.loaderProgress, veil: veil)
                case .scrim:
                    WarmScrim(progress: launch.loaderProgress, veil: veil)
                case .invisible:
                    Color.clear
                }
            default:
                EmptyView()
            }
        }
        .animation(revealAnimation, value: veil)
    }

    private func coveredWebView(_ webView: WebViewController) -> some View {
        ZStack {
            WebViewScreen(webView: webView)

            if appCover.isCoverVisible {
                MixCover()
                    .transition(.opacity)
                    .contentShape(Rectangle())
                    .onTapGesture { appCover.deactivateImmediately() }
            }
        }
        .ignoresSafeArea()
        .animation(revealAnimation, value: launch.coverOpacity)
        .onDisappear {
            appCover.deactivateImmediately()
        }
        .onChange(of: scenePhase) { _, phase in
            appCover.handleScenePhase(phase)
        }
    }

    private var tabShell: some View {
        NavigationStack(path: $store.path) {
            TabView(selection: $store.selectedTab) {
                MixesHubScreen(dependencies: dependencies)
                    .tabItem { Label("Mixes", systemImage: "drop.halffull") }
                    .tag(AppTab.mixes)

                BenchesScreen(dependencies: dependencies)
                    .tabItem { Label("Benches", systemImage: "square.grid.3x3") }
                    .tag(AppTab.benches)

                ExportScreen(dependencies: dependencies)
                    .tabItem { Label("Export", systemImage: "doc.richtext") }
                    .tag(AppTab.export)

                SettingsScreen(dependencies: dependencies)
                    .tabItem { Label("Settings", systemImage: "gearshape") }
                    .tag(AppTab.settings)
            }
            .sensoryFeedback(.selection, trigger: store.selectedTab)
            .toolbar(store.path.isEmpty ? .hidden : .automatic, for: .navigationBar)
            .navigationDestination(for: AppRoute.self, destination: destination(for:))
        }
        .background(AppTheme.bgBase)
    }

    @ViewBuilder
    private func destination(for route: AppRoute) -> some View {
        switch route {
        case .tool(let tool):
            ToolRouter.screen(tool, payload: nil, dependencies: dependencies)
        case .reopen(let tool, let json):
            ToolRouter.screen(tool, payload: SnapshotJSON.decode(MixPayload.self, from: json), dependencies: dependencies)
        case .bench(let id):
            BenchDetailScreen(benchID: id, dependencies: dependencies)
        case .recipes:
            RecipeBookScreen(dependencies: dependencies)
        case .calendar:
            MixCalendarScreen(dependencies: dependencies)
        }
    }
}

#Preview {
    RootView(dependencies: .freshOnboarding(), launch: .previewNative())
}
