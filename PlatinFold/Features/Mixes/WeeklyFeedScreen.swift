import SwiftUI

@MainActor
struct WeeklyFeedScreen: View {
    private let payload: MixPayload?
    private let dependencies: AppDependencies
    @State private var potText: String
    @State private var gramsText: String
    @State private var weeksText: String
    @State private var presetID: String
    @State private var showSave = false
    @State private var didSave = false

    init(payload: MixPayload?, dependencies: AppDependencies) {
        self.payload = payload
        self.dependencies = dependencies
        let seed = payload ?? .empty(tool: .weeklyFeed)
        _potText = State(initialValue: MixMath.number(seed.potLiters, digits: 2))
        _gramsText = State(initialValue: MixMath.number(seed.gramsPerLiter, digits: 2))
        _weeksText = State(initialValue: MixMath.number(seed.weeks, digits: 0))
        _presetID = State(initialValue: seed.presetID)
    }

    private var potLiters: Double { MixMath.parse(potText) ?? 0 }
    private var gramsPerLiter: Double { MixMath.parse(gramsText) ?? 0 }
    private var weeks: Double { MixMath.parse(weeksText) ?? 1 }
    private var output: WeeklyFeedCalculator.Output {
        WeeklyFeedCalculator.compute(.init(potLiters: potLiters, gramsPerLiter: gramsPerLiter, weeks: weeks))
    }
    private var currentPayload: MixPayload {
        var body = payload ?? .empty(tool: .weeklyFeed)
        body.toolRaw = DoseTool.weeklyFeed.rawValue
        body.potLiters = potLiters
        body.gramsPerLiter = gramsPerLiter
        body.weeks = weeks
        body.presetID = presetID
        return body
    }

    var body: some View {
        ScreenScaffold {
            ScreenHeader(
                title: "Weekly feed",
                subtitle: "Dry grams for one pot. 2 L at 1.5 g/L is 3 g."
            )

            ChipRow {
                ForEach(Array(BenchSeed.feedPresets.filter { $0.gramsPerLiter > 0 }.prefix(6))) { preset in
                    FilterChip(title: preset.name, isSelected: presetID == preset.id) {
                        presetID = preset.id
                        gramsText = MixMath.number(preset.gramsPerLiter, digits: 2)
                    }
                }
            }

            NumberField(title: "Pot volume", value: $potText, unit: "L", prompt: "2")
            NumberField(title: "Rate", value: $gramsText, unit: "g/L", prompt: "1.5")
            NumberField(title: "Weeks", value: $weeksText, unit: "count", prompt: "1")

            ResultCard(
                title: "This week",
                value: MixMath.number(output.gramsThisWeek, digits: 1),
                unit: "g",
                lines: [
                    ResultLine(label: "Bag draw", value: MixMath.grams(output.gramsTotal)),
                    ResultLine(label: "Preset", value: BenchSeed.preset(id: presetID).name),
                ],
                note: BenchSeed.preset(id: presetID).note
            )

            CTAButton(title: "Save mix", systemImage: "tray.and.arrow.down", isEnabled: potLiters > 0) {
                showSave = true
            }
        }
        .navigationTitle("Weekly feed")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSave) {
            SaveLineItemSheet(
                tool: .weeklyFeed,
                title: "\(BenchSeed.preset(id: presetID).name), \(MixMath.liters(potLiters)) pot",
                resultText: WeeklyFeedCalculator.summary(output),
                payload: currentPayload,
                waterLiters: potLiters,
                dependencies: dependencies,
                onSaved: { didSave = true }
            )
        }
        .sensoryFeedback(.success, trigger: didSave)
    }
}

#Preview {
    NavigationStack {
        WeeklyFeedScreen(payload: nil, dependencies: .preview())
    }
}
