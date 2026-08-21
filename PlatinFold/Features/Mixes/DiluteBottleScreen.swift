import SwiftUI

@MainActor
struct DiluteBottleScreen: View {
    private let payload: MixPayload?
    private let dependencies: AppDependencies
    @State private var tankText: String
    @State private var rateText: String
    @State private var presetID: String
    @State private var showLines = false
    @State private var showSave = false
    @State private var didSave = false
    @State private var readoutPulse = 0

    init(payload: MixPayload?, dependencies: AppDependencies) {
        self.payload = payload
        self.dependencies = dependencies
        let seed = payload ?? .empty(tool: .diluteBottle)
        _tankText = State(initialValue: MixMath.number(seed.tankLiters, digits: 2))
        _rateText = State(initialValue: MixMath.number(seed.rate, digits: 2))
        _presetID = State(initialValue: seed.presetID)
    }

    private var tank: Double { MixMath.parse(tankText) ?? 0 }
    private var rate: Double { MixMath.parse(rateText) ?? 0 }
    private var input: DiluteBottleCalculator.Input {
        DiluteBottleCalculator.Input(tankLiters: tank, mlPerLiter: rate)
    }
    private var output: DiluteBottleCalculator.Output { DiluteBottleCalculator.compute(input) }
    private var currentPayload: MixPayload {
        var body = payload ?? .empty(tool: .diluteBottle)
        body.toolRaw = DoseTool.diluteBottle.rawValue
        body.tankLiters = tank
        body.rate = rate
        body.presetID = presetID
        return body
    }

    private var tankError: String? {
        tank <= 0 ? "Tank must be above 0 L" : nil
    }

    private let tankPresets: [Double] = [2, 4, 8, 14]

    var body: some View {
        ScreenScaffold {
            ScreenHeader(
                title: "Dilute bottle",
                subtitle: "Exact dose for this tank. Set liters and ml/L — one clear number."
            )

            ChipRow {
                ForEach(Array(BenchSeed.feedPresets.filter { $0.mlPerLiter > 0 }.prefix(6))) { preset in
                    FilterChip(title: preset.name, isSelected: presetID == preset.id) {
                        withAnimation(.spring(response: 0.36, dampingFraction: 0.82)) {
                            presetID = preset.id
                            rateText = MixMath.number(preset.mlPerLiter, digits: 2)
                            readoutPulse += 1
                        }
                    }
                }
            }

            SectionCard(title: "Tank size") {
                ChipRow {
                    ForEach(tankPresets, id: \.self) { liters in
                        FilterChip(
                            title: "\(MixMath.number(liters, digits: 0)) L",
                            isSelected: abs(tank - liters) < 0.05
                        ) {
                            withAnimation(.spring(response: 0.34, dampingFraction: 0.8)) {
                                tankText = MixMath.number(liters, digits: 0)
                                readoutPulse += 1
                            }
                        }
                    }
                }
                NumberField(
                    title: "Tank",
                    value: $tankText,
                    unit: "L",
                    prompt: "4",
                    error: tankError
                )
            }

            SectionCard(title: "Rate") {
                HStack(spacing: AppMetrics.contentSpacing) {
                    nudgeButton(title: "−0.5", systemImage: "minus") {
                        nudgeRate(by: -0.5)
                    }
                    NumberField(title: "Rate", value: $rateText, unit: "ml/L", prompt: "2")
                    nudgeButton(title: "+0.5", systemImage: "plus") {
                        nudgeRate(by: 0.5)
                    }
                }
            }

            ResultCard(
                title: "Exact dose",
                value: MixMath.number(output.concentrateMl, digits: 1),
                unit: "ml",
                lines: [
                    ResultLine(label: "Water", value: MixMath.liters(output.waterLiters)),
                    ResultLine(label: "Rate", value: "\(MixMath.number(rate, digits: 2)) ml/L"),
                ],
                note: BenchSeed.preset(id: presetID).note
            )
            .overlay {
                FormulaHalo(pulse: readoutPulse)
            }
            .contentTransition(.numericText())
            .animation(.spring(response: 0.42, dampingFraction: 0.78), value: output.concentrateMl)
            .animation(.spring(response: 0.42, dampingFraction: 0.78), value: presetID)
            .sensoryFeedback(.selection, trigger: readoutPulse)
            .accessibilityIdentifier("smoke.mix.diluteCard")

            CTAButton(title: "Save mix", systemImage: "tray.and.arrow.down", isEnabled: tank > 0) {
                showSave = true
            }
            .accessibilityIdentifier("smoke.mix.saveMix")

            CTAButton(
                title: "Tank lines",
                systemImage: "list.bullet",
                emphasis: .secondary
            ) {
                withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
                    showLines = true
                }
            }
            .accessibilityIdentifier("smoke.mix.showLines")

            if showLines {
                SectionCard(title: "Tank lines", footnote: "One bottle into this volume.") {
                    DetailRow(label: "Bottle", value: BenchSeed.preset(id: presetID).name, isProminent: true)
                    DetailRow(label: "Draw", value: MixMath.ml(output.concentrateMl))
                    DetailRow(label: "Fill", value: MixMath.liters(output.waterLiters))
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 0.98)),
                    removal: .opacity
                ))
                .accessibilityIdentifier("smoke.mix.tankLines")
            }
        }
        .navigationTitle("Dilute bottle")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSave) {
            SaveLineItemSheet(
                tool: .diluteBottle,
                title: "\(BenchSeed.preset(id: presetID).name), \(MixMath.liters(tank)) tank",
                resultText: DiluteBottleCalculator.summary(output),
                payload: currentPayload,
                waterLiters: output.waterLiters,
                dependencies: dependencies,
                onSaved: { didSave = true }
            )
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.84), value: showLines)
        .sensoryFeedback(.success, trigger: didSave)
    }

    private func nudgeRate(by delta: Double) {
        let next = max(0, rate + delta)
        withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
            rateText = MixMath.number(next, digits: 2)
            readoutPulse += 1
        }
    }

    private func nudgeButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                Text(title)
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(AppTheme.textPrimary)
            .frame(width: 56)
            .padding(.vertical, AppMetrics.contentSpacing)
            .background(AppTheme.bgElevated, in: RoundedRectangle(cornerRadius: AppMetrics.controlRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AppMetrics.controlRadius, style: .continuous)
                    .stroke(AppTheme.hairline, lineWidth: AppMetrics.hairlineWidth)
            }
        }
        .buttonStyle(SoftPressStyle())
        .accessibilityLabel(title)
    }
}

#Preview {
    NavigationStack {
        DiluteBottleScreen(payload: nil, dependencies: .preview())
    }
}
