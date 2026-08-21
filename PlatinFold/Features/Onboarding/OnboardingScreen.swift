import SwiftUI

@MainActor
struct OnboardingScreen: View {
    private let dependencies: AppDependencies
    @Bindable private var store: MixStore
    @State private var pageIndex = 0

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        store = dependencies.store
    }

    var body: some View {
        ScreenScaffold(scrolls: false) {
            ZStack {
                Group {
                    switch pageIndex {
                    case 0: countPage
                    case 1: benchPage
                    default: resetPage
                    }
                }
                .id(pageIndex)
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    )
                )
            }
            .animation(.spring(response: 0.48, dampingFraction: 0.86), value: pageIndex)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityLabel("Introduction page \(pageIndex + 1) of 3")
            .gesture(
                DragGesture(minimumDistance: 24)
                    .onEnded { value in
                        guard abs(value.translation.width) > abs(value.translation.height) else { return }
                        if value.translation.width < -50, pageIndex < 2 {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                                pageIndex += 1
                            }
                        } else if value.translation.width > 50, pageIndex > 0 {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                                pageIndex -= 1
                            }
                        }
                    }
            )

            footer
        }
        .sensoryFeedback(.selection, trigger: pageIndex)
        .sensoryFeedback(.success, trigger: store.hasCompletedOnboarding)
    }

    private var countPage: some View {
        VStack(alignment: .leading, spacing: AppMetrics.sectionSpacing) {
            ScreenHeader(
                title: AppTheme.displayName,
                subtitle: "Exact dose for every pot. 14 L tank, 2 ml/L — FloraGro into the bucket, then seven pours."
            )

            ResultCard(
                title: "This mix",
                value: "8 ml",
                unit: "concentrate",
                lines: [
                    ResultLine(label: "Tank", value: "4 L"),
                    ResultLine(label: "Rate", value: "2 ml/L"),
                    ResultLine(label: "Pours", value: "7 terracotta"),
                ],
                note: "Bucket: 14L, mix ratio 3:1 stays on Tea steep."
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var benchPage: some View {
        VStack(alignment: .leading, spacing: AppMetrics.sectionSpacing) {
            ScreenHeader(
                title: "Which bench?",
                subtitle: "Pick the shelf this phone opens first. Mixes save onto that bench."
            )

            ChipRow {
                ForEach(BenchSeed.seedBenches) { bench in
                    FilterChip(
                        title: bench.name,
                        isSelected: store.preferredBenchID == bench.id
                    ) {
                        withAnimation(.spring(response: 0.38, dampingFraction: 0.8)) {
                            store.chooseBench(bench.id)
                        }
                    }
                }
            }

            SectionCard(title: BenchSeed.bench(id: store.preferredBenchID).name) {
                DetailRow(
                    label: "Pots",
                    value: "\(BenchSeed.bench(id: store.preferredBenchID).potCount)",
                    isProminent: true
                )
                DetailRow(label: "Place", value: BenchSeed.bench(id: store.preferredBenchID).location)
                DetailRow(label: "Note", value: BenchSeed.bench(id: store.preferredBenchID).note)
            }
            .id(store.preferredBenchID)
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .opacity
            ))
            .animation(.spring(response: 0.42, dampingFraction: 0.84), value: store.preferredBenchID)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var resetPage: some View {
        VStack(alignment: .leading, spacing: AppMetrics.sectionSpacing) {
            ScreenHeader(
                title: "Stays on this iPhone",
                subtitle: "Benches and lines never leave the device."
            )

            SectionCard(
                title: "Clear the book",
                footnote: "Settings → Delete All Data wipes every mix, then this introduction returns."
            ) {
                DetailRow(label: "Saved on", value: "This iPhone", isProminent: true)
                DetailRow(label: "Reset", value: "Delete All Data")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var footer: some View {
        Group {
            if pageIndex >= 2 {
                CTAButton(
                    title: "Done",
                    systemImage: "drop",
                    hint: "Finishes the introduction and opens Mixes"
                ) {
                    store.completeOnboarding()
                }
            } else {
                CTAButton(
                    title: "Continue",
                    systemImage: "arrow.right",
                    hint: "Shows the next introduction page"
                ) {
                    pageIndex = min(pageIndex + 1, 2)
                }
            }
        }
    }
}

#Preview {
    OnboardingScreen(dependencies: .freshOnboarding())
}
