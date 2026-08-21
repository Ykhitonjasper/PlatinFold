import SwiftUI

@MainActor
struct SettingsScreen: View {
    private let dependencies: AppDependencies
    private var store: MixStore { dependencies.store }
    @Environment(\.openURL) private var openURL
    @State private var confirmDelete = false

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
    }

    var body: some View {
        ScreenScaffold {
            ScreenHeader(
                title: "Settings",
                subtitle: "About \(AppTheme.displayName), legal pages, and a full reset of this iPhone copy."
            )

            SectionCard(title: "About") {
                DetailRow(label: "App", value: AppTheme.displayName, isProminent: true)
                DetailRow(label: "Version", value: bundleVersion)
                DetailRow(label: "Desk", value: "Container feed mixes")
                DetailRow(label: "Benches", value: "\(dependencies.projects.allProjects().count)")
                DetailRow(label: "Storage", value: "On this iPhone")
            }

            VStack(spacing: AppMetrics.contentSpacing) {
                NavigationRow(
                    title: "Privacy",
                    subtitle: "How this app treats mixes stored on this iPhone",
                    systemImage: "hand.raised",
                    hint: "Opens the privacy page"
                ) {
                    if let url = Legal.privacy {
                        openURL(url)
                    }
                }

                NavigationRow(
                    title: "Terms",
                    subtitle: "The terms that apply to this local mix book",
                    systemImage: "doc.plaintext",
                    hint: "Opens the terms page"
                ) {
                    if let url = Legal.terms {
                        openURL(url)
                    }
                }
            }

            SectionCard(
                title: "Local records",
                footnote: "Clears benches and lines, then returns you to the introduction."
            ) {
                CTAButton(
                    title: "Delete All Data",
                    systemImage: "trash",
                    emphasis: .secondary,
                    hint: "Asks for confirmation before clearing this iPhone copy"
                ) {
                    confirmDelete = true
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Delete All Data",
            isPresented: $confirmDelete,
            titleVisibility: .visible
        ) {
            Button("Delete All Data", role: .destructive) {
                dependencies.projects.deleteAll()
                store.resetAll()
            }
            Button("Keep Records", role: .cancel) {}
        } message: {
            Text("This removes every local mix, then returns to the introduction.")
        }
        .sensoryFeedback(.warning, trigger: confirmDelete)
    }

    private var bundleVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let trimmed = (version ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "1.0" : trimmed
    }
}

#Preview {
    NavigationStack {
        SettingsScreen(dependencies: .preview())
    }
}
