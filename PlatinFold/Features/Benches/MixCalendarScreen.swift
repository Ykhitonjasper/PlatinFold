import SwiftUI

@MainActor
struct MixCalendarScreen: View {
    private let dependencies: AppDependencies
    @Bindable private var store: MixStore
    @State private var selectedDay: Date = MixDate.day("2026-08-18")

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        store = dependencies.store
    }

    private var selectedEvents: [PourEvent] {
        ScheduleSeed.events(on: selectedDay)
    }

    var body: some View {
        ScreenScaffold {
            ScreenHeader(
                title: "August pours",
                subtitle: "Marked days on the three benches. Tap a chip, then open the mix."
            )

            ChipRow {
                ForEach(ScheduleSeed.markedDays(), id: \.self) { day in
                    FilterChip(title: MixDate.short(day), isSelected: Calendar(identifier: .gregorian).isDate(day, inSameDayAs: selectedDay)) {
                        withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                            selectedDay = day
                        }
                    }
                }
            }

            SectionLabel(title: MixDate.short(selectedDay), detail: "\(selectedEvents.count)")

            if selectedEvents.isEmpty {
                EmptyStateCard(
                    title: "Dry day",
                    message: "No pour on this date. Pick a marked day or open Dilute bottle.",
                    actionTitle: "Dilute bottle"
                ) {
                    store.path.append(.tool(.diluteBottle))
                }
            } else {
                ForEach(selectedEvents) { event in
                    SectionCard(title: event.title, footnote: event.note) {
                        DetailRow(label: "Bench", value: event.benchName, isProminent: true)
                        DetailRow(label: "Pot", value: event.potLabel)
                        DetailRow(label: "Job", value: event.tool.verb)
                        DetailRow(label: "Water", value: MixMath.liters(event.liters))
                        CTAButton(title: "Open mix", emphasis: .secondary) {
                            store.path.append(.tool(event.tool))
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity
                    ))
                }
            }
        }
        .navigationTitle("August pours")
        .navigationBarTitleDisplayMode(.inline)
        .animation(.spring(response: 0.4, dampingFraction: 0.84), value: selectedDay)
    }
}

#Preview {
    NavigationStack {
        MixCalendarScreen(dependencies: .preview())
    }
}
