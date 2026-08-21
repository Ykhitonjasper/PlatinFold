import SwiftUI

@MainActor
struct TopDressScreen: View {
    private let payload: MixPayload?
    private let dependencies: AppDependencies
    @State private var diameterText: String
    @State private var rateText: String
    @State private var showSave = false
    @State private var didSave = false

    init(payload: MixPayload?, dependencies: AppDependencies) {
        self.payload = payload
        self.dependencies = dependencies
        let seed = payload ?? .empty(tool: .topDress)
        _diameterText = State(initialValue: MixMath.number(seed.diameterCm, digits: 0))
        _rateText = State(initialValue: MixMath.number(seed.gramsPerSqM, digits: 0))
    }

    private var diameter: Double { MixMath.parse(diameterText) ?? 0 }
    private var rate: Double { MixMath.parse(rateText) ?? 0 }
    private var output: TopDressCalculator.Output {
        TopDressCalculator.compute(.init(diameterCm: diameter, gramsPerSqM: rate))
    }
    private var currentPayload: MixPayload {
        var body = payload ?? .empty(tool: .topDress)
        body.toolRaw = DoseTool.topDress.rawValue
        body.diameterCm = diameter
        body.gramsPerSqM = rate
        body.presetID = "bonemeal"
        return body
    }

    var body: some View {
        ScreenScaffold {
            ScreenHeader(
                title: "Top dress",
                subtitle: "Slow-release grams from pot diameter. 18 cm at 80 g/m² is about 2 g."
            )

            SegmentedPicker(
                title: "Pot",
                options: [
                    SegmentOption("14 cm", id: "14"),
                    SegmentOption("18 cm", id: "18"),
                    SegmentOption("22 cm", id: "22"),
                ],
                selection: $diameterText
            )

            NumberField(title: "Rate", value: $rateText, unit: "g/m²", prompt: "80")

            ResultCard(
                title: "Dress",
                value: MixMath.number(output.grams, digits: 1),
                unit: "g",
                lines: [
                    ResultLine(label: "Surface", value: "\(MixMath.number(output.surfaceM2, digits: 3)) m²"),
                    ResultLine(label: "Diameter", value: "\(MixMath.number(diameter, digits: 0)) cm"),
                ],
                note: "Bone meal on the citrus, 18cm terracotta."
            )

            CTAButton(title: "Save mix", systemImage: "tray.and.arrow.down", isEnabled: diameter > 0) {
                showSave = true
            }
        }
        .navigationTitle("Top dress")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSave) {
            SaveLineItemSheet(
                tool: .topDress,
                title: "Bone meal, \(MixMath.number(diameter, digits: 0)) cm",
                resultText: TopDressCalculator.summary(output),
                payload: currentPayload,
                waterLiters: 0,
                dependencies: dependencies,
                onSaved: { didSave = true }
            )
        }
        .sensoryFeedback(.success, trigger: didSave)
    }
}

#Preview {
    NavigationStack {
        TopDressScreen(payload: nil, dependencies: .preview())
    }
}
