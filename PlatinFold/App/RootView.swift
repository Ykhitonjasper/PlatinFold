import SwiftUI

struct RootView: View {
    private let dependencies: AppDependencies
    @Bindable private var store: MixStore
    @State private var router: StartupRouter

    @State private var warmupMessageIndex = 0
    private let warmupMessages = ["Preparing workspace...", "Loading preferences...", "Almost ready..."]

    @MainActor
    init(dependencies: AppDependencies, router: StartupRouter? = nil) {
        self.dependencies = dependencies
        store = dependencies.store
        _router = State(initialValue: router ?? StartupRouter(dependencies: dependencies))
    }

    var body: some View {
        Group {
            switch router.phase {
            case .warming:
                warmupScreen
            case .native:
                if store.hasCompletedOnboarding {
                    tabShell
                } else {
                    OnboardingScreen(dependencies: dependencies)
                }
            case .experiment(let webView):
                ExperimentWebViewWrapper(webView: webView)
                    .ignoresSafeArea()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: router.phase.isWarming)
        .environment(store)
        .tint(AppTheme.accent)
        .sensoryFeedback(.impact(weight: .light), trigger: router.phase.isWarming)
        .task { await router.start() }
    }

    private var warmupScreen: some View {
        ZStack {
            AppTheme.bgBase.ignoresSafeArea()

            VStack(spacing: 40) {
                Image(systemName: "square.grid.3x3.fill")
                    .font(.system(size: 72))
                    .foregroundColor(AppTheme.accent)

                VStack(spacing: 12) {
                    Text(warmupMessages[warmupMessageIndex])
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                        .id(warmupMessageIndex)
                        .transition(.opacity)

                    ProgressView()
                        .tint(AppTheme.accent)
                }
            }
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 800_000_000)
                guard !Task.isCancelled else { return }
                withAnimation {
                    warmupMessageIndex = (warmupMessageIndex + 1) % warmupMessages.count
                }
            }
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
    RootView(dependencies: .freshOnboarding(), router: .previewNative())
}
