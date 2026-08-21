import Foundation

struct PourEvent: Identifiable, Hashable {
    let id: String
    let benchID: String
    let potLabel: String
    let toolRaw: String
    let title: String
    let day: Date
    let liters: Double
    let note: String

    var tool: DoseTool {
        DoseTool(rawValue: toolRaw) ?? .diluteBottle
    }

    var benchName: String {
        BenchSeed.bench(id: benchID).name
    }
}

enum ScheduleSeed {
    static let pourEvents: [PourEvent] = [
        event("sill-jul28", bench: "kitchen-sill", pot: "Lemon", tool: .topDress, title: "Bone meal on the lemon", day: "2026-07-28", liters: 0, note: "18 cm terracotta, dry dress before a rain."),
        event("rack-jul30", bench: "balcony-rack", pot: "Tomato A", tool: .diluteBottle, title: "Grow Big into the 8L can", day: "2026-07-30", liters: 8, note: "4 ml/L, first truss just set."),
        event("sill-aug02", bench: "kitchen-sill", pot: "Basil", tool: .diluteBottle, title: "FloraGro 2ml/L, 4L", day: "2026-08-02", liters: 4, note: "East glass, morning pour."),
        event("ledge-aug03", bench: "bathroom-ledge", pot: "Boston", tool: .teaSteep, title: "Compost tea 1:10", day: "2026-08-03", liters: 4, note: "Tub ledge, 2L jug filled twice."),
        event("sill-aug04", bench: "kitchen-sill", pot: "Mint", tool: .perPotPour, title: "4L across seven pots", day: "2026-08-04", liters: 4, note: "571 ml each, saucers emptied."),
        event("rack-aug05", bench: "balcony-rack", pot: "Tomato A", tool: .flushVolume, title: "Tomato A 3× flush", day: "2026-08-05", liters: 4.8, note: "White crust on the rim."),
        event("sill-aug06", bench: "kitchen-sill", pot: "Basil", tool: .weeklyFeed, title: "Herb 3-1-2", day: "2026-08-06", liters: 2, note: "2 g into 2 L, basil only."),
        event("rack-aug08", bench: "balcony-rack", pot: "Tomato B", tool: .weeklyFeed, title: "Bloom 10-30-20", day: "2026-08-08", liters: 2, note: "Second truss, 3.6 g."),
        event("sill-aug09", bench: "kitchen-sill", pot: "Lemon", tool: .teaSteep, title: "Worm tea 1:4, 8L", day: "2026-08-09", liters: 8, note: "Bucket from the worm tray."),
        event("sill-aug11", bench: "kitchen-sill", pot: "Pepper", tool: .foliarMix, title: "Seaweed 2ml/L", day: "2026-08-11", liters: 1, note: "Dusk mist, underside of the leaf."),
        event("rack-aug12", bench: "balcony-rack", pot: "Fig", tool: .foliarMix, title: "Silica 0.5ml/L", day: "2026-08-12", liters: 2, note: "New leaves on the fig."),
        event("sill-aug14", bench: "kitchen-sill", pot: "Pepper", tool: .seedlingCut, title: "Pepper starts at half", day: "2026-08-14", liters: 1, note: "First true leaves, 9 cm pots."),
        event("rack-aug15", bench: "balcony-rack", pot: "Sage", tool: .perPotPour, title: "8L across twelve pots", day: "2026-08-15", liters: 8, note: "667 ml each, south rail."),
        event("ledge-aug18", bench: "bathroom-ledge", pot: "Maidenhair", tool: .flushVolume, title: "Maidenhair 2×", day: "2026-08-18", liters: 2.4, note: "Tap salt after a week of tap water."),
        event("sill-aug20", bench: "kitchen-sill", pot: "Thyme", tool: .weeklyFeed, title: "Jack's 20-20-20", day: "2026-08-20", liters: 1.5, note: "Next Thursday, 2.2 g."),
        event("rack-aug22", bench: "balcony-rack", pot: "Citrus", tool: .diluteBottle, title: "Citrus 5-2-6 into 6L", day: "2026-08-22", liters: 6, note: "After the next flush."),
        event("ledge-aug24", bench: "bathroom-ledge", pot: "Pothos", tool: .teaSteep, title: "Worm tea quarter jug", day: "2026-08-24", liters: 2, note: "Bathroom, no fish emulsion."),
        event("sill-aug26", bench: "kitchen-sill", pot: "Oregano", tool: .foliarMix, title: "Cal-Mag 1ml/L", day: "2026-08-26", liters: 1, note: "RO jug week."),
    ]

    static func events(on day: Date) -> [PourEvent] {
        let cal = Calendar(identifier: .gregorian)
        return pourEvents.filter { cal.isDate($0.day, inSameDayAs: day) }
    }

    static func events(benchID: String) -> [PourEvent] {
        pourEvents.filter { $0.benchID == benchID }.sorted { $0.day < $1.day }
    }

    static func markedDays() -> [Date] {
        var seen = Set<TimeInterval>()
        return pourEvents.map(\.day).filter { day in
            seen.insert(day.timeIntervalSince1970).inserted
        }
        .sorted()
    }

    static func monthDays(year: Int, month: Int) -> [Date] {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        components.timeZone = TimeZone(secondsFromGMT: 0)
        let cal = Calendar(identifier: .gregorian)
        guard let start = cal.date(from: components),
              let range = cal.range(of: .day, in: .month, for: start)
        else {
            return []
        }
        return range.compactMap { day in
            var next = components
            next.day = day
            return cal.date(from: next)
        }
    }

    static func weekdayIndex(_ date: Date) -> Int {
        let cal = Calendar(identifier: .gregorian)
        let weekday = cal.component(.weekday, from: date)
        return (weekday + 5) % 7
    }

    private static func event(
        _ id: String,
        bench: String,
        pot: String,
        tool: DoseTool,
        title: String,
        day: String,
        liters: Double,
        note: String
    ) -> PourEvent {
        PourEvent(
            id: id,
            benchID: bench,
            potLabel: pot,
            toolRaw: tool.rawValue,
            title: title,
            day: MixDate.day(day),
            liters: liters,
            note: note
        )
    }
}

enum RecipeMath {
    static func sample(for preset: FeedPreset) -> (label: String, value: String, detail: String) {
        switch preset.group {
        case .mix:
            if preset.teaParts > 0 {
                let out = TeaSteepCalculator.compute(
                    .init(bucketLiters: 14, waterParts: preset.waterParts, teaParts: preset.teaParts)
                )
                return ("14 L bucket", TeaSteepCalculator.summary(out), MixMath.liters(out.waterLiters) + " water")
            }
            let out = DiluteBottleCalculator.compute(
                .init(tankLiters: 4, mlPerLiter: preset.mlPerLiter)
            )
            return ("4 L tank", DiluteBottleCalculator.summary(out), "\(MixMath.number(preset.mlPerLiter, digits: 2)) ml/L")
        case .feed:
            if preset.gramsPerLiter > 0 {
                let out = WeeklyFeedCalculator.compute(
                    .init(potLiters: 2, gramsPerLiter: preset.gramsPerLiter, weeks: 1)
                )
                return ("2 L pot", WeeklyFeedCalculator.summary(out), preset.note)
            }
            let out = FoliarMixCalculator.compute(.init(tankLiters: 1, mlPerLiter: max(preset.mlPerLiter, 0.5)))
            return ("1 L sprayer", FoliarMixCalculator.summary(out), preset.note)
        case .rinse:
            let out = DiluteBottleCalculator.compute(
                .init(tankLiters: 4, mlPerLiter: max(preset.mlPerLiter, 0.3))
            )
            return ("4 L tank", DiluteBottleCalculator.summary(out), preset.note)
        case .all:
            return ("Tank", "—", preset.note)
        }
    }

    static func tool(for preset: FeedPreset) -> DoseTool {
        if preset.teaParts > 0 { return .teaSteep }
        if preset.group == .feed && preset.gramsPerLiter > 0 { return .weeklyFeed }
        if preset.group == .rinse { return .diluteBottle }
        if preset.mlPerLiter > 0 && preset.mlPerLiter <= 1 { return .foliarMix }
        return .diluteBottle
    }

    static func payload(for preset: FeedPreset) -> MixPayload {
        var body = MixPayload.empty(tool: tool(for: preset))
        body.presetID = preset.id
        body.rate = preset.mlPerLiter
        body.gramsPerLiter = preset.gramsPerLiter
        body.waterParts = preset.waterParts
        body.teaParts = preset.teaParts
        if preset.teaParts > 0 {
            body.tankLiters = 14
        }
        return body
    }
}
