import SwiftUI

@MainActor
struct TeaSteepScreen: View {
    private let payload: MixPayload?
    private let dependencies: AppDependencies
    @State private var bucketText: String
    @State private var waterText: String
    @State private var teaText: String
    @State private var presetID: String
    @State private var showSave = false
    @State private var didSave = false

    init(payload: MixPayload?, dependencies: AppDependencies) {
        self.payload = payload
        self.dependencies = dependencies
        let seed = payload ?? .empty(tool: .teaSteep)
        _bucketText = State(initialValue: MixMath.number(seed.tankLiters, digits: 1))
        _waterText = State(initialValue: MixMath.number(seed.waterParts, digits: 0))
        _teaText = State(initialValue: MixMath.number(seed.teaParts, digits: 0))
        _presetID = State(initialValue: seed.presetID)
    }

    private var bucket: Double { MixMath.parse(bucketText) ?? 0 }
    private var waterParts: Double { MixMath.parse(waterText) ?? 0 }
    private var teaParts: Double { MixMath.parse(teaText) ?? 0 }
    private var output: TeaSteepCalculator.Output {
        TeaSteepCalculator.compute(.init(bucketLiters: bucket, waterParts: waterParts, teaParts: teaParts))
    }
    private var currentPayload: MixPayload {
        var body = payload ?? .empty(tool: .teaSteep)
        body.toolRaw = DoseTool.teaSteep.rawValue
        body.tankLiters = bucket
        body.waterParts = waterParts
        body.teaParts = teaParts
        body.presetID = presetID
        return body
    }

    var body: some View {
        ScreenScaffold {
            ScreenHeader(
                title: "Tea steep",
                subtitle: "Bucket: 14L, mix ratio 3:1. Tea solids versus water."
            )

            ChipRow {
                ForEach(BenchSeed.feedPresets.filter { $0.teaParts > 0 }) { preset in
                    FilterChip(title: preset.name, isSelected: presetID == preset.id) {
                        presetID = preset.id
                        waterText = MixMath.number(preset.waterParts, digits: 0)
                        teaText = MixMath.number(preset.teaParts, digits: 0)
                    }
                }
            }

            NumberField(title: "Bucket", value: $bucketText, unit: "L", prompt: "14")
            NumberField(title: "Water parts", value: $waterText, unit: "parts", prompt: "3")
            NumberField(title: "Tea parts", value: $teaText, unit: "parts", prompt: "1")

            ResultCard(
                title: "Tea solids",
                value: MixMath.number(output.teaLiters, digits: 2),
                unit: "L",
                lines: [
                    ResultLine(label: "Water", value: MixMath.liters(output.waterLiters)),
                    ResultLine(label: "Ratio", value: "\(MixMath.number(waterParts, digits: 0)):\(MixMath.number(teaParts, digits: 0))"),
                ],
                note: BenchSeed.preset(id: presetID).note
            )

            CTAButton(title: "Save mix", systemImage: "tray.and.arrow.down", isEnabled: bucket > 0) {
                showSave = true
            }
        }
        .navigationTitle("Tea steep")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSave) {
            SaveLineItemSheet(
                tool: .teaSteep,
                title: "\(BenchSeed.preset(id: presetID).name), \(MixMath.liters(bucket))",
                resultText: TeaSteepCalculator.summary(output),
                payload: currentPayload,
                waterLiters: bucket,
                dependencies: dependencies,
                onSaved: { didSave = true }
            )
        }
        .sensoryFeedback(.success, trigger: didSave)
    }
}

#Preview {
    NavigationStack {
        TeaSteepScreen(payload: nil, dependencies: .preview())
    }
}
