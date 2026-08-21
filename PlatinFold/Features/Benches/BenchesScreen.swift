import SwiftUI

@MainActor
struct BenchesScreen: View {
    private let dependencies: AppDependencies
    @Bindable private var store: MixStore
    @State private var appeared = false

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        store = dependencies.store
    }

    private var benches: [BenchItem] {
        _ = store.refreshRevision
        return dependencies.projects.allProjects()
    }

    var body: some View {
        ScreenScaffold {
            ScreenHeader(
                title: "Benches",
                subtitle: "Every sill under your watch. Tap a pot row to open saved mixes."
            )

            CTAButton(
                title: "August pours",
                systemImage: "calendar",
                emphasis: .secondary,
                hint: "Opens the marked mix days"
            ) {
                store.path.append(.calendar)
            }

            if benches.isEmpty {
                EmptyStateCard(
                    title: "No benches",
                    message: "Delete All Data cleared the shelves. Mix and save onto a bench after the introduction.",
                    actionTitle: "Open mixes"
                ) {
                    store.selectedTab = .mixes
                }
            } else {
                ForEach(Array(benches.enumerated()), id: \.element.id) { index, bench in
                    shelf(bench)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 14)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.84).delay(Double(index) * 0.06),
                            value: appeared
                        )
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
                appeared = true
            }
        }
    }

    private func shelf(_ bench: BenchItem) -> some View {
        let lines = dependencies.projects.lineItems(projectID: bench.id)
        return SectionCard(
            title: bench.name,
            footnote: "\(bench.location) · \(lines.count) saved lines"
        ) {
            ChipCloud(spacing: AppMetrics.tightSpacing) {
                ForEach(Array(bench.potNames.enumerated()), id: \.offset) { index, name in
                    TagChip(title: name, systemImage: "leaf")
                        .fixedSize(horizontal: true, vertical: false)
                        .opacity(appeared ? 1 : 0)
                        .scaleEffect(appeared ? 1 : 0.9)
                        .animation(
                            .spring(response: 0.45, dampingFraction: 0.82).delay(0.08 + Double(index) * 0.02),
                            value: appeared
                        )
                }
            }

            CTAButton(
                title: "Open \(bench.name)",
                systemImage: "square.grid.3x3",
                emphasis: .secondary,
                hint: "\(lines.count) saved lines"
            ) {
                store.path.append(.bench(bench.id))
            }
        }
    }
}

private struct ChipCloud: Layout {
    var spacing: CGFloat = AppMetrics.tightSpacing

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        flow(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for (subview, origin) in zip(subviews, flow(proposal: proposal, subviews: subviews).origins) {
            subview.place(
                at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y),
                proposal: .unspecified
            )
        }
    }

    private func flow(proposal: ProposedViewSize, subviews: Subviews) -> (origins: [CGPoint], size: CGSize) {
        let limit = proposal.width ?? .infinity
        var origins: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var usedWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > limit {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            origins.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            usedWidth = max(usedWidth, x - spacing)
        }

        return (origins, CGSize(width: usedWidth, height: y + rowHeight))
    }
}

#Preview {
    NavigationStack {
        BenchesScreen(dependencies: .preview())
    }
}
