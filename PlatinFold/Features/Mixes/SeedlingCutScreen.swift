import SwiftUI

@MainActor
struct SeedlingCutScreen: View {
    private let payload: MixPayload?
    private let dependencies: AppDependencies
    @State private var adultText: String
    @State private var tankText: String
    @State private var fractionID: String
    @State private var showSave = false
    @State private var didSave = false

    init(payload: MixPayload?, dependencies: AppDependencies) {
        self.payload = payload
        self.dependencies = dependencies
        let seed = payload ?? .empty(tool: .seedlingCut)
        _adultText = State(initialValue: MixMath.number(seed.rate, digits: 2))
        _tankText = State(initialValue: MixMath.number(seed.tankLiters, digits: 2))
        let fraction = seed.fraction == 0.25 ? "0.25" : "0.5"
        _fractionID = State(initialValue: fraction)
    }

    private var adult: Double { MixMath.parse(adultText) ?? 0 }
    private var tank: Double { MixMath.parse(tankText) ?? 0 }
    private var fraction: Double { MixMath.parse(fractionID) ?? 0.5 }
    private var output: SeedlingCutCalculator.Output {
        SeedlingCutCalculator.compute(.init(adultMlPerLiter: adult, fraction: fraction, tankLiters: tank))
    }
    private var currentPayload: MixPayload {
        var body = payload ?? .empty(tool: .seedlingCut)
        body.toolRaw = DoseTool.seedlingCut.rawValue
        body.rate = adult
        body.tankLiters = tank
        body.fraction = fraction
        body.presetID = "seedling"
        return body
    }

    var body: some View {
        ScreenScaffold {
            ScreenHeader(
                title: "Seedling cut",
                subtitle: "Half of an adult 2 ml/L in a 1 L jug is 1 ml."
            )

            NumberField(title: "Adult rate", value: $adultText, unit: "ml/L", prompt: "2")
            NumberField(title: "Jug", value: $tankText, unit: "L", prompt: "1")

            SegmentedPicker(
                title: "Cut",
                options: [
                    SegmentOption("Quarter", id: "0.25"),
                    SegmentOption("Half", id: "0.5"),
                ],
                selection: $fractionID
            )

            ResultCard(
                title: "Cut rate",
                value: MixMath.number(output.cutMlPerLiter, digits: 2),
                unit: "ml/L",
                lines: [
                    ResultLine(label: "Draw", value: MixMath.ml(output.concentrateMl)),
                    ResultLine(label: "Jug", value: MixMath.liters(tank)),
                ],
                note: "Pepper starts in 9 cm. First true leaves."
            )

            CTAButton(title: "Save mix", systemImage: "tray.and.arrow.down", isEnabled: adult > 0 && tank > 0) {
                showSave = true
            }
        }
        .navigationTitle("Seedling cut")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSave) {
            SaveLineItemSheet(
                tool: .seedlingCut,
                title: "Seedling half of \(MixMath.number(adult, digits: 1)) ml/L",
                resultText: SeedlingCutCalculator.summary(output),
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
        SeedlingCutScreen(payload: nil, dependencies: .preview())
    }
}
