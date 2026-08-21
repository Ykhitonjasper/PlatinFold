import SwiftUI

@MainActor
struct BenchDetailScreen: View {
    let benchID: String
    private let dependencies: AppDependencies
    @Bindable private var store: MixStore

    init(benchID: String, dependencies: AppDependencies) {
        self.benchID = benchID
        self.dependencies = dependencies
        store = dependencies.store
    }

    private var bench: BenchItem {
        dependencies.projects.project(id: benchID) ?? BenchSeed.bench(id: benchID)
    }

    private var lines: [MixLineItem] {
        _ = store.refreshRevision
        return dependencies.projects.lineItems(projectID: benchID)
    }

    var body: some View {
        ScreenScaffold {
            ScreenHeader(
                title: bench.name,
                subtitle: "\(bench.location) · \(bench.potCount) pots · \(bench.note)"
            )

            TileGrid {
                MetricTile(title: "Pots", value: "\(bench.potCount)", caption: bench.location)
                MetricTile(title: "Lines", value: "\(lines.count)", caption: "Saved mixes")
            }

            if lines.isEmpty {
                EmptyStateCard(
                    title: "No lines",
                    message: "Save a dilute or a pour onto this bench.",
                    actionTitle: "Dilute bottle"
                ) {
                    store.path.append(.tool(.diluteBottle))
                }
            } else {
                ForEach(lines) { item in
                    SectionCard(title: item.title, footnote: "\(item.potLabel) · \(MixDate.short(item.savedAt))") {
                        DetailRow(label: item.tool.verb, value: item.resultText, isProminent: true)
                        DetailRow(label: "Water", value: MixMath.liters(item.waterLiters))
                        CTAButton(title: "Open mix", emphasis: .secondary) {
                            store.path.append(.reopen(item.tool, json: item.detailJSON))
                        }
                    }
                }
            }
        }
        .navigationTitle(bench.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        BenchDetailScreen(benchID: "kitchen-sill", dependencies: .preview())
    }
}
