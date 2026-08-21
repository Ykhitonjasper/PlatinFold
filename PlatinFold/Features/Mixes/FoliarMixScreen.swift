import SwiftUI

@MainActor
struct FoliarMixScreen: View {
    private let payload: MixPayload?
    private let dependencies: AppDependencies
    @State private var tankText: String
    @State private var rateText: String
    @State private var presetID: String
    @State private var showSave = false
    @State private var didSave = false

    init(payload: MixPayload?, dependencies: AppDependencies) {
        self.payload = payload
        self.dependencies = dependencies
        let seed = payload ?? .empty(tool: .foliarMix)
        _tankText = State(initialValue: MixMath.number(seed.tankLiters, digits: 2))
        _rateText = State(initialValue: MixMath.number(seed.rate, digits: 2))
        _presetID = State(initialValue: seed.presetID)
    }

    private var tank: Double { MixMath.parse(tankText) ?? 0 }
    private var rate: Double { MixMath.parse(rateText) ?? 0 }
    private var output: FoliarMixCalculator.Output {
        FoliarMixCalculator.compute(.init(tankLiters: tank, mlPerLiter: rate))
    }
    private var currentPayload: MixPayload {
        var body = payload ?? .empty(tool: .foliarMix)
        body.toolRaw = DoseTool.foliarMix.rawValue
        body.tankLiters = tank
        body.rate = rate
        body.presetID = presetID
        return body
    }

    var body: some View {
        ScreenScaffold {
            ScreenHeader(
                title: "Foliar mix",
                subtitle: "Sprayer tank. 1 L at 6 ml/L is 6 ml of seaweed."
            )

            ChipRow {
                ForEach(["seaweed", "silica", "calmag", "fish"], id: \.self) { id in
                    FilterChip(title: BenchSeed.preset(id: id).name, isSelected: presetID == id) {
                        presetID = id
                        rateText = MixMath.number(BenchSeed.preset(id: id).mlPerLiter, digits: 2)
                    }
                }
            }

            NumberField(title: "Sprayer", value: $tankText, unit: "L", prompt: "1")
            NumberField(title: "Rate", value: $rateText, unit: "ml/L", prompt: "6")

            ResultCard(
                title: "Draw",
                value: MixMath.number(output.concentrateMl, digits: 1),
                unit: "ml",
                lines: [
                    ResultLine(label: "Tank", value: MixMath.liters(tank)),
                    ResultLine(label: "Bottle", value: BenchSeed.preset(id: presetID).name),
                ],
                note: "Mist at dusk. Underside of the leaf."
            )

            CTAButton(title: "Save mix", systemImage: "tray.and.arrow.down", isEnabled: tank > 0) {
                showSave = true
            }
        }
        .navigationTitle("Foliar mix")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSave) {
            SaveLineItemSheet(
                tool: .foliarMix,
                title: "\(BenchSeed.preset(id: presetID).name), \(MixMath.liters(tank)) sprayer",
                resultText: FoliarMixCalculator.summary(output),
                payload: currentPayload,
                waterLiters: tank,
                dependencies: dependencies,
                onSaved: { didSave = true }
            )
        }
        .sensoryFeedback(.success, trigger: didSave)
    }
}

#Preview {
    NavigationStack {
        FoliarMixScreen(payload: nil, dependencies: .preview())
    }
}
