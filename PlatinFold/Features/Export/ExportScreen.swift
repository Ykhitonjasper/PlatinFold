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
        VStack(alignment: .leading, spacing: 0) {
            ScreenHeader(
                title: "Mix sheet",
                subtitle: "Keep every mix for this sill — one page PDF."
            )
            .padding(.horizontal, AppMetrics.screenPadding)
            .padding(.top, AppMetrics.screenPadding)
            .padding(.bottom, AppMetrics.tightSpacing)

            Form {
            Section {
                HStack(spacing: AppMetrics.contentSpacing) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(bench.name)
                            .font(.headline)
                            .foregroundStyle(AppTheme.textPrimary)
                        Text(bench.location)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(bench.potCount) pots")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppTheme.textMono)
                        Text("\(lines.count) mixes")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
            } header: {
                Text("\(AppTheme.displayName) sheet")
            } footer: {
                Text(bench.note)
            }

            Section {
                Picker("Bench", selection: $benchID) {
                    ForEach(benches) { item in
                        Text(item.name).tag(item.id)
                    }
                }
            }

            Section("Lines") {
                if lines.isEmpty {
                    Text("No saved mixes on this bench.")
                        .foregroundStyle(AppTheme.textSecondary)
                } else {
                    ForEach(lines) { item in
                        HStack {
                            Text(item.tool.verb)
                                .foregroundStyle(AppTheme.textPrimary)
                            Spacer()
                            Text(item.resultText)
                                .font(.body.monospacedDigit())
                                .foregroundStyle(AppTheme.textMono)
                        }
                    }
                }
            }

            Section {
                Button {
                    _ = BenchPDF.make(bench: bench, lines: lines)
                    pdfReady = true
                } label: {
                    Label("Write PDF", systemImage: "doc.richtext")
                }
                Button {
                    UIPasteboard.general.string = BenchPDF.textList(bench: bench, lines: lines)
                    copied = true
                } label: {
                    Label("Copy text", systemImage: "doc.on.doc")
                }
            }

            if pdfReady {
                Section("PDF ready") {
                    LabeledContent("Page", value: "1")
                    LabeledContent("Bench", value: bench.name)
                    LabeledContent("Rows", value: "\(lines.count)")
                }
            }
            }
            .scrollContentBackground(.hidden)
        }
        .background(AppBackground())
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
