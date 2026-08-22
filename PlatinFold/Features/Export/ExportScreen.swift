import SwiftUI
import UIKit

@MainActor
struct ExportScreen: View {
    private let dependencies: AppDependencies
    @Bindable private var store: MixStore
    @State private var benchID: String
    @State private var pdfReady = false
    @State private var copied = false

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        store = dependencies.store
        _benchID = State(initialValue: dependencies.store.preferredBenchID)
    }

    private var benches: [BenchItem] {
        _ = store.refreshRevision
        let live = dependencies.projects.allProjects()
        return live.isEmpty ? BenchSeed.seedBenches : live
    }

    private var bench: BenchItem {
        benches.first(where: { $0.id == benchID }) ?? benches[0]
    }

    private var lines: [MixLineItem] {
        dependencies.projects.lineItems(projectID: bench.id)
    }

    var body: some View {
        ScreenScaffold {
            ScreenHeader(
                title: "Mix sheet",
                subtitle: "Keep every mix for this sill — one page PDF."
            )

            SectionCard(title: "\(AppTheme.displayName) sheet", footnote: bench.note) {
                HStack(alignment: .top, spacing: AppMetrics.contentSpacing) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(bench.name)
                            .font(.headline)
                            .foregroundStyle(AppTheme.textPrimary)
                        Text(bench.location)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    Spacer(minLength: 0)

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(bench.potCount) pots")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppTheme.textMono)
                        Text("\(lines.count) mixes")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
            }

            SectionCard(title: "Bench") {
                Picker("Bench", selection: $benchID) {
                    ForEach(benches) { item in
                        Text(item.name).tag(item.id)
                    }
                }
                .labelsHidden()
                .tint(AppTheme.textMono)
            }

            SectionCard(title: "Lines") {
                if lines.isEmpty {
                    Text("No saved mixes on this bench.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                } else {
                    VStack(spacing: AppMetrics.contentSpacing) {
                        ForEach(lines) { item in
                            DetailRow(label: item.tool.verb, value: item.resultText)
                        }
                    }
                }
            }

            SectionCard(title: "Export") {
                VStack(spacing: AppMetrics.contentSpacing) {
                    CTAButton(
                        title: "Write PDF",
                        systemImage: "doc.richtext",
                        hint: "Builds a one-page mix sheet for this bench"
                    ) {
                        _ = BenchPDF.make(bench: bench, lines: lines)
                        pdfReady = true
                    }

                    CTAButton(
                        title: "Copy text",
                        systemImage: "doc.on.doc",
                        emphasis: .secondary,
                        hint: "Copies the mix list to the pasteboard"
                    ) {
                        UIPasteboard.general.string = BenchPDF.textList(bench: bench, lines: lines)
                        copied = true
                    }
                }
            }

            if pdfReady {
                SectionCard(title: "PDF ready") {
                    DetailRow(label: "Page", value: "1")
                    DetailRow(label: "Bench", value: bench.name, isProminent: true)
                    DetailRow(label: "Rows", value: "\(lines.count)")
                }
            }
        }
        .sensoryFeedback(.success, trigger: copied)
        .sensoryFeedback(.success, trigger: pdfReady)
        .onAppear {
            if benches.contains(where: { $0.id == store.preferredBenchID }) {
                benchID = store.preferredBenchID
            }
        }
    }
}

#Preview {
    NavigationStack {
        ExportScreen(dependencies: .preview())
    }
}
