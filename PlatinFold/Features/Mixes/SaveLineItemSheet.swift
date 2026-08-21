import SwiftUI

@MainActor
struct SaveLineItemSheet: View {
    let tool: DoseTool
    let title: String
    let resultText: String
    let payload: MixPayload
    let waterLiters: Double
    let dependencies: AppDependencies
    var onSaved: () -> Void

    @Bindable private var store: MixStore
    @State private var benchID: String
    @State private var potLabel: String
    @Environment(\.dismiss) private var dismiss

    init(
        tool: DoseTool,
        title: String,
        resultText: String,
        payload: MixPayload,
        waterLiters: Double,
        dependencies: AppDependencies,
        onSaved: @escaping () -> Void
    ) {
        self.tool = tool
        self.title = title
        self.resultText = resultText
        self.payload = payload
        self.waterLiters = waterLiters
        self.dependencies = dependencies
        self.onSaved = onSaved
        store = dependencies.store
        let preferred = dependencies.store.preferredBenchID
        _benchID = State(initialValue: preferred)
        let firstPot = BenchSeed.bench(id: preferred).potNames.first ?? "Basil"
        _potLabel = State(initialValue: firstPot)
    }

    private var bench: BenchItem {
        dependencies.projects.project(id: benchID) ?? BenchSeed.bench(id: benchID)
    }

    var body: some View {
        ScreenScaffold {
            ScreenHeader(
                title: "Save mix",
                subtitle: "\(tool.verb) · \(resultText)"
            )

            ChipRow {
                ForEach(dependencies.projects.allProjects()) { item in
                    FilterChip(title: item.name, isSelected: benchID == item.id) {
                        benchID = item.id
                        potLabel = item.potNames.first ?? potLabel
                    }
                }
            }

            SectionLabel(title: "Pot on \(bench.name)", detail: "\(bench.potCount)")

            ChipRow {
                ForEach(bench.potNames, id: \.self) { name in
                    FilterChip(title: name, isSelected: potLabel == name) {
                        potLabel = name
                    }
                }
            }

            ResultCard(
                title: tool.verb,
                value: resultText,
                lines: [
                    ResultLine(label: "Bench", value: bench.name),
                    ResultLine(label: "Pot", value: potLabel),
                ]
            )
            .accessibilityIdentifier("smoke.mix.saveSheet")

            CTAButton(title: "Keep on bench", systemImage: "tray.and.arrow.down") {
                let item = MixLineItem(
                    id: store.nextLineID(tool: tool),
                    projectID: benchID,
                    calculatorType: tool.rawValue,
                    title: title,
                    resultText: resultText,
                    detailJSON: SnapshotJSON.encode(payload),
                    savedAt: Date(),
                    potLabel: potLabel,
                    waterLiters: waterLiters
                )
                dependencies.projects.saveLine(item)
                store.chooseBench(benchID)
                store.refreshRevision += 1
                onSaved()
                dismiss()
            }
        }
        .navigationTitle("Save mix")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SaveLineItemSheet(
        tool: .diluteBottle,
        title: "FloraGro 2ml/L, 4L tank",
        resultText: "8 ml in 4 L",
        payload: .empty(tool: .diluteBottle),
        waterLiters: 4,
        dependencies: .preview(),
        onSaved: {}
    )
}
