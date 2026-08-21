import SwiftUI

@MainActor
struct MixesHubScreen: View {
    private let dependencies: AppDependencies
    @Bindable private var store: MixStore
    @State private var group: MixGroup = .all
    @State private var showLastTank = false
    @State private var appeared = false

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        store = dependencies.store
    }

    private var tools: [DoseTool] {
        DoseTool.allCases.filter { group == .all || $0.group == group }
    }

    private var bench: BenchItem {
        BenchSeed.bench(id: store.preferredBenchID)
    }

    private var lastLine: MixLineItem? {
        dependencies.projects.lineItems(projectID: bench.id).first
    }

    var body: some View {
        ScreenScaffold {
            ScreenHeader(
                title: bench.name,
                subtitle: "\(AppTheme.displayName) · exact dose for this sill"
            )
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 10)
            .animation(.spring(response: 0.55, dampingFraction: 0.86), value: appeared)

            TodayMixHero(
                bench: bench,
                lastLine: lastLine,
                appeared: appeared,
                onMixTank: { store.path.append(.tool(.diluteBottle)) },
                onLastTank: { showLastTank = true }
            )

            ChipRow {
                ForEach(MixGroup.allCases) { item in
                    FilterChip(title: item.title, isSelected: group == item) {
                        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                            group = item
                        }
                    }
                }
            }

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: AppMetrics.contentSpacing),
                    GridItem(.flexible(), spacing: AppMetrics.contentSpacing),
                ],
                spacing: AppMetrics.contentSpacing
            ) {
                ForEach(Array(tools.enumerated()), id: \.element.id) { index, tool in
                    Button {
                        store.path.append(.tool(tool))
                    } label: {
                        MetricTile(
                            title: tool.verb,
                            value: tool.sampleValue,
                            caption: tool.sampleCaption
                        )
                    }
                    .buttonStyle(SoftPressStyle())
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 16)
                    .scaleEffect(appeared ? 1 : 0.96)
                    .animation(
                        .spring(response: 0.56, dampingFraction: 0.78).delay(0.16 + Double(index) * 0.05),
                        value: appeared
                    )
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.94).combined(with: .opacity),
                        removal: .opacity
                    ))
                    .accessibilityLabel(tool.verb)
                    .accessibilityIdentifier(tool == .diluteBottle ? "smoke.mix.openDilute" : "mix.\(tool.rawValue)")
                }
            }
            .animation(.spring(response: 0.38, dampingFraction: 0.84), value: group)
        }
        .navigationTitle("Mixes")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Bottles") {
                    store.path.append(.recipes)
                }
            }
        }
        .sheet(isPresented: $showLastTank) {
            lastTankSheet
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            withAnimation(.spring(response: 0.62, dampingFraction: 0.84)) {
                appeared = true
            }
        }
        .sensoryFeedback(.selection, trigger: group)
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.7), trigger: showLastTank)
    }

    @ViewBuilder
    private var lastTankSheet: some View {
        ScreenScaffold {
            if let lastLine {
                ScreenHeader(title: lastLine.title, subtitle: "\(lastLine.potLabel) · \(MixDate.short(lastLine.savedAt))")
                SillPotStage(
                    kind: lastTankKind(for: lastLine),
                    caption: lastLine.potLabel,
                    canvasHeight: 148
                )
                ResultCard(
                    title: lastLine.tool.verb,
                    value: lastLine.resultText,
                    lines: [
                        ResultLine(label: "Bench", value: BenchSeed.bench(id: lastLine.projectID).name),
                        ResultLine(label: "Water", value: MixMath.liters(lastLine.waterLiters)),
                    ]
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                CTAButton(title: "Open mix", systemImage: "drop") {
                    showLastTank = false
                    store.path.append(.reopen(lastLine.tool, json: lastLine.detailJSON))
                }
            } else {
                EmptyStateCard(
                    title: "No tank yet",
                    message: "Run Dilute bottle and save the mix onto this bench.",
                    actionTitle: "Dilute bottle"
                ) {
                    showLastTank = false
                    store.path.append(.tool(.diluteBottle))
                }
            }
        }
    }

    private func lastTankKind(for line: MixLineItem) -> BenchPotKind {
        if line.potLabel == "Lemon" { return .lemon }
        if line.tool == .diluteBottle { return .bottle }
        return .basil
    }
}

#Preview {
    NavigationStack {
        MixesHubScreen(dependencies: .preview())
    }
}
