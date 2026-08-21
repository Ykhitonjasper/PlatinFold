import SwiftUI

@MainActor
struct PerPotPourScreen: View {
    private let payload: MixPayload?
    private let dependencies: AppDependencies
    @State private var tankText: String
    @State private var potsText: String
    @State private var showSave = false
    @State private var didSave = false

    init(payload: MixPayload?, dependencies: AppDependencies) {
        self.payload = payload
        self.dependencies = dependencies
        let seed = payload ?? .empty(tool: .perPotPour)
        _tankText = State(initialValue: MixMath.number(seed.tankLiters, digits: 2))
        _potsText = State(initialValue: MixMath.number(seed.pots, digits: 0))
    }

    private var tank: Double { MixMath.parse(tankText) ?? 0 }
    private var pots: Double { MixMath.parse(potsText) ?? 0 }
    private var output: PerPotPourCalculator.Output {
        PerPotPourCalculator.compute(.init(tankLiters: tank, potCount: pots))
    }
    private var currentPayload: MixPayload {
        var body = payload ?? .empty(tool: .perPotPour)
        body.toolRaw = DoseTool.perPotPour.rawValue
        body.tankLiters = tank
        body.pots = pots
        return body
    }

    var body: some View {
        ScreenScaffold {
            ScreenHeader(
                title: "Per-pot pour",
                subtitle: "Split a 4 L can across the sill. Seven pots drink 571 ml each."
            )

            NumberField(title: "Tank", value: $tankText, unit: "L", prompt: "4")
            NumberField(title: "Pots", value: $potsText, unit: "count", prompt: "7")

            ResultCard(
                title: "Each pot",
                value: MixMath.number(output.mlPerPot, digits: 0),
                unit: "ml",
                lines: [
                    ResultLine(label: "Per pot", value: MixMath.liters(output.litersPerPot)),
                    ResultLine(label: "Tank", value: MixMath.liters(tank)),
                ],
                note: pots <= 0 ? "Need at least one pot." : "Same pour for every terracotta."
            )

            CTAButton(title: "Save mix", systemImage: "tray.and.arrow.down", isEnabled: tank > 0 && pots > 0) {
                showSave = true
            }
        }
        .navigationTitle("Per-pot pour")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSave) {
            SaveLineItemSheet(
                tool: .perPotPour,
                title: "\(MixMath.liters(tank)) across \(MixMath.number(pots, digits: 0)) pots",
                resultText: PerPotPourCalculator.summary(output),
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
        PerPotPourScreen(payload: nil, dependencies: .preview())
    }
}
