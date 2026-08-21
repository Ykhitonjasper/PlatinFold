import SwiftUI

@MainActor
struct FlushVolumeScreen: View {
    private let payload: MixPayload?
    private let dependencies: AppDependencies
    @State private var potText: String
    @State private var multiplierID: String
    @State private var showSave = false
    @State private var didSave = false

    init(payload: MixPayload?, dependencies: AppDependencies) {
        self.payload = payload
        self.dependencies = dependencies
        let seed = payload ?? .empty(tool: .flushVolume)
        _potText = State(initialValue: MixMath.number(seed.potLiters, digits: 2))
        _multiplierID = State(initialValue: MixMath.number(seed.multiplier, digits: 0))
    }

    private var potLiters: Double { MixMath.parse(potText) ?? 0 }
    private var multiplier: Double { MixMath.parse(multiplierID) ?? 3 }
    private var output: FlushVolumeCalculator.Output {
        FlushVolumeCalculator.compute(.init(potLiters: potLiters, multiplier: multiplier))
    }
    private var currentPayload: MixPayload {
        var body = payload ?? .empty(tool: .flushVolume)
        body.toolRaw = DoseTool.flushVolume.rawValue
        body.potLiters = potLiters
        body.multiplier = multiplier
        return body
    }

    var body: some View {
        ScreenScaffold {
            ScreenHeader(
                title: "Flush volume",
                subtitle: "Salt flush. 1.6 L pot × 3 is 4.8 L through the saucer."
            )

            NumberField(title: "Pot volume", value: $potText, unit: "L", prompt: "1.6")

            SegmentedPicker(
                title: "Pass",
                options: [
                    SegmentOption("2×", id: "2"),
                    SegmentOption("3×", id: "3"),
                    SegmentOption("4×", id: "4"),
                ],
                selection: $multiplierID
            )

            ResultCard(
                title: "Flush",
                value: MixMath.number(output.flushLiters, digits: 1),
                unit: "L",
                lines: [
                    ResultLine(label: "Pot", value: MixMath.liters(potLiters)),
                    ResultLine(label: "Pass", value: "\(MixMath.number(multiplier, digits: 0))×"),
                ],
                note: "Keep going until the runoff is clear."
            )

            CTAButton(title: "Save mix", systemImage: "tray.and.arrow.down", isEnabled: potLiters > 0) {
                showSave = true
            }
        }
        .navigationTitle("Flush volume")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSave) {
            SaveLineItemSheet(
                tool: .flushVolume,
                title: "\(MixMath.liters(potLiters)) pot × \(MixMath.number(multiplier, digits: 0))",
                resultText: FlushVolumeCalculator.summary(output),
                payload: currentPayload,
                waterLiters: output.flushLiters,
                dependencies: dependencies,
                onSaved: { didSave = true }
            )
        }
        .sensoryFeedback(.success, trigger: didSave)
    }
}

#Preview {
    NavigationStack {
        FlushVolumeScreen(payload: nil, dependencies: .preview())
    }
}
