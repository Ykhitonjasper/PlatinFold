import SwiftUI

@MainActor
struct RecipeBookScreen: View {
    private let dependencies: AppDependencies
    @Bindable private var store: MixStore
    @State private var group: MixGroup = .all

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        store = dependencies.store
    }

    private var recipes: [FeedPreset] {
        BenchSeed.feedPresets.filter { group == .all || $0.group == group }
    }

    var body: some View {
        ScreenScaffold {
            ScreenHeader(
                title: "Bottles",
                subtitle: "Twenty-four named feeds. Tap a row to open the matching mix."
            )

            ChipRow {
                ForEach(MixGroup.allCases) { item in
                    FilterChip(title: item.title, isSelected: group == item) {
                        withAnimation(.spring(response: 0.36, dampingFraction: 0.82)) {
                            group = item
                        }
                    }
                }
            }

            ForEach(recipes) { preset in
                recipeCard(preset)
            }
        }
        .navigationTitle("Bottles")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func recipeCard(_ preset: FeedPreset) -> some View {
        let sample = RecipeMath.sample(for: preset)
        return SectionCard(title: preset.name, footnote: preset.note) {
            DetailRow(label: sample.label, value: sample.value, isProminent: true)
            DetailRow(label: "Group", value: preset.group.title)
            if preset.mlPerLiter > 0 {
                DetailRow(label: "ml/L", value: MixMath.number(preset.mlPerLiter, digits: 2))
            }
            if preset.gramsPerLiter > 0 {
                DetailRow(label: "g/L", value: MixMath.number(preset.gramsPerLiter, digits: 2))
            }
            if preset.teaParts > 0 {
                DetailRow(
                    label: "Ratio",
                    value: "\(MixMath.number(preset.waterParts, digits: 0)):\(MixMath.number(preset.teaParts, digits: 0))"
                )
            }
            CTAButton(title: "Open \(RecipeMath.tool(for: preset).verb)", emphasis: .secondary) {
                store.path.append(.reopen(RecipeMath.tool(for: preset), json: SnapshotJSON.encode(RecipeMath.payload(for: preset))))
            }
        }
    }
}

#Preview {
    NavigationStack {
        RecipeBookScreen(dependencies: .preview())
    }
}
