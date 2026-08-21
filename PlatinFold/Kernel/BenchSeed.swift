import Foundation

enum BenchSeed {
    static let feedPresets: [FeedPreset] = [
        FeedPreset(id: "floragro", name: "FloraGro 2ml/L", group: .mix, mlPerLiter: 2, gramsPerLiter: 0, waterParts: 0, teaParts: 0, note: "4 L tank on the sill"),
        FeedPreset(id: "growbig", name: "Grow Big 4ml/L", group: .mix, mlPerLiter: 4, gramsPerLiter: 0, waterParts: 0, teaParts: 0, note: "Leafy start on the balcony"),
        FeedPreset(id: "jacks", name: "Jack's 20-20-20", group: .feed, mlPerLiter: 0, gramsPerLiter: 1.5, waterParts: 0, teaParts: 0, note: "One teaspoon in 2 L"),
        FeedPreset(id: "allpurpose", name: "All-purpose 24-8-16", group: .feed, mlPerLiter: 0, gramsPerLiter: 1.2, waterParts: 0, teaParts: 0, note: "Blue crystals, half scoop"),
        FeedPreset(id: "fish", name: "Fish emulsion 5-1-1", group: .mix, mlPerLiter: 5, gramsPerLiter: 0, waterParts: 0, teaParts: 0, note: "After a rain on the rail"),
        FeedPreset(id: "seaweed", name: "Seaweed 2ml/L", group: .mix, mlPerLiter: 2, gramsPerLiter: 0, waterParts: 0, teaParts: 0, note: "Soft leave-on drench"),
        FeedPreset(id: "wormtea", name: "Worm tea 1:4", group: .mix, mlPerLiter: 0, gramsPerLiter: 0, waterParts: 4, teaParts: 1, note: "Bucket from the worm tray"),
        FeedPreset(id: "compost", name: "Compost tea 1:10", group: .mix, mlPerLiter: 0, gramsPerLiter: 0, waterParts: 10, teaParts: 1, note: "14 L bucket, coarse bag"),
        FeedPreset(id: "calmag", name: "Cal-Mag 1ml/L", group: .mix, mlPerLiter: 1, gramsPerLiter: 0, waterParts: 0, teaParts: 0, note: "RO jug from the tap filter"),
        FeedPreset(id: "epsom", name: "Epsom 1g/L", group: .feed, mlPerLiter: 0, gramsPerLiter: 1, waterParts: 0, teaParts: 0, note: "Yellowing lower leaves"),
        FeedPreset(id: "bloom", name: "Bloom 10-30-20", group: .feed, mlPerLiter: 0, gramsPerLiter: 1.8, waterParts: 0, teaParts: 0, note: "Tomato A first truss"),
        FeedPreset(id: "tomato", name: "Tomato 18-18-21", group: .feed, mlPerLiter: 0, gramsPerLiter: 1.6, waterParts: 0, teaParts: 0, note: "Two fruiting pots"),
        FeedPreset(id: "orchid", name: "Orchid weekly", group: .feed, mlPerLiter: 1, gramsPerLiter: 0.5, waterParts: 0, teaParts: 0, note: "Bark mix, bathroom ledge"),
        FeedPreset(id: "succulent", name: "Succulent quarter", group: .feed, mlPerLiter: 0.5, gramsPerLiter: 0.4, waterParts: 0, teaParts: 0, note: "Once a month, dry mix"),
        FeedPreset(id: "citrus", name: "Citrus 5-2-6", group: .feed, mlPerLiter: 0, gramsPerLiter: 2, waterParts: 0, teaParts: 0, note: "Lemon on the sill"),
        FeedPreset(id: "herb", name: "Herb 3-1-2", group: .feed, mlPerLiter: 0, gramsPerLiter: 1, waterParts: 0, teaParts: 0, note: "Basil and thyme"),
        FeedPreset(id: "seedling", name: "Seedling half", group: .feed, mlPerLiter: 1, gramsPerLiter: 0.6, waterParts: 0, teaParts: 0, note: "Pepper starts in 9 cm"),
        FeedPreset(id: "rocal", name: "RO CalMag plus", group: .mix, mlPerLiter: 1.5, gramsPerLiter: 0, waterParts: 0, teaParts: 0, note: "Before FloraGro"),
        FeedPreset(id: "vinegar", name: "Vinegar pH down", group: .rinse, mlPerLiter: 0.4, gramsPerLiter: 0, waterParts: 0, teaParts: 0, note: "A few drops in 4 L"),
        FeedPreset(id: "lemon", name: "Lemon pH down", group: .rinse, mlPerLiter: 0.3, gramsPerLiter: 0, waterParts: 0, teaParts: 0, note: "Kitchen bottle, not the tree"),
        FeedPreset(id: "molasses", name: "Molasses microbe", group: .mix, mlPerLiter: 2, gramsPerLiter: 0, waterParts: 0, teaParts: 0, note: "With compost tea"),
        FeedPreset(id: "silica", name: "Silica 0.5ml/L", group: .mix, mlPerLiter: 0.5, gramsPerLiter: 0, waterParts: 0, teaParts: 0, note: "First into the tank"),
        FeedPreset(id: "kelp", name: "Kelp powder", group: .feed, mlPerLiter: 0, gramsPerLiter: 0.8, waterParts: 0, teaParts: 0, note: "Stirred into 2 L"),
        FeedPreset(id: "bonemeal", name: "Bone meal dress", group: .feed, mlPerLiter: 0, gramsPerLiter: 0, waterParts: 0, teaParts: 0, note: "Top dress, 18 cm pot"),
    ]

    static let seedBenches: [BenchItem] = [
        BenchItem(
            id: "kitchen-sill",
            name: "Kitchen sill",
            note: "East glass, 7 terracotta, 14L tank under the sink.",
            potCount: 7,
            location: "East window",
            createdAt: MixDate.day("2026-07-15"),
            potNames: ["Basil", "Mint", "Lemon", "Pepper", "Thyme", "Chive", "Oregano"]
        ),
        BenchItem(
            id: "balcony-rack",
            name: "Balcony rack",
            note: "South rail, 12 pots, 8L can by the door.",
            potCount: 12,
            location: "South rail",
            createdAt: MixDate.day("2026-07-18"),
            potNames: ["Tomato A", "Tomato B", "Chile", "Citrus", "Fig", "Sage", "Rosemary", "Lavender", "Geranium", "Petunia", "Coleus", "Ivy"]
        ),
        BenchItem(
            id: "bathroom-ledge",
            name: "Bathroom ledge",
            note: "Five ferns on the tub ledge, 2L jug.",
            potCount: 5,
            location: "Tub ledge",
            createdAt: MixDate.day("2026-08-01"),
            potNames: ["Maidenhair", "Boston", "Bird nest", "Pothos", "Nerve"]
        ),
    ]

    static let seedLineItems: [MixLineItem] = [
        line(
            id: "sill-dilute",
            projectID: "kitchen-sill",
            tool: .diluteBottle,
            title: "FloraGro 2ml/L, 4L tank",
            resultText: DiluteBottleCalculator.summary(.init(concentrateMl: 8, waterLiters: 4)),
            saved: "2026-08-02",
            potLabel: "Basil",
            waterLiters: 4,
            payload: payload(tool: .diluteBottle, tank: 4, rate: 2, preset: "floragro")
        ),
        line(
            id: "sill-pour",
            projectID: "kitchen-sill",
            tool: .perPotPour,
            title: "4L across 7 terracotta",
            resultText: PerPotPourCalculator.summary(.init(mlPerPot: 571.4, litersPerPot: 0.571)),
            saved: "2026-08-04",
            potLabel: "Mint",
            waterLiters: 4,
            payload: payload(tool: .perPotPour, tank: 4, pots: 7)
        ),
        line(
            id: "sill-weekly",
            projectID: "kitchen-sill",
            tool: .weeklyFeed,
            title: "Herb 3-1-2 on basil",
            resultText: WeeklyFeedCalculator.summary(.init(gramsThisWeek: 2, gramsTotal: 2)),
            saved: "2026-08-06",
            potLabel: "Basil",
            waterLiters: 2,
            payload: payload(tool: .weeklyFeed, potLiters: 2, gramsPerLiter: 1, weeks: 1, preset: "herb")
        ),
        line(
            id: "sill-tea",
            projectID: "kitchen-sill",
            tool: .teaSteep,
            title: "Worm tea 1:4, 8L",
            resultText: TeaSteepCalculator.summary(.init(waterLiters: 6.4, teaLiters: 1.6)),
            saved: "2026-08-09",
            potLabel: "Lemon",
            waterLiters: 8,
            payload: payload(tool: .teaSteep, tank: 8, waterParts: 4, teaParts: 1, preset: "wormtea")
        ),
        line(
            id: "sill-foliar",
            projectID: "kitchen-sill",
            tool: .foliarMix,
            title: "Seaweed 2ml/L, 1L sprayer",
            resultText: FoliarMixCalculator.summary(.init(concentrateMl: 2)),
            saved: "2026-08-11",
            potLabel: "Pepper",
            waterLiters: 1,
            payload: payload(tool: .foliarMix, tank: 1, rate: 2, preset: "seaweed")
        ),
        line(
            id: "sill-seedling",
            projectID: "kitchen-sill",
            tool: .seedlingCut,
            title: "Pepper starts at half of 2ml/L",
            resultText: SeedlingCutCalculator.summary(.init(cutMlPerLiter: 1, concentrateMl: 1)),
            saved: "2026-08-14",
            potLabel: "Pepper",
            waterLiters: 1,
            payload: payload(tool: .seedlingCut, tank: 1, rate: 2, fraction: 0.5, preset: "seedling")
        ),
        line(
            id: "rack-dress",
            projectID: "balcony-rack",
            tool: .topDress,
            title: "Bone meal on citrus, 18cm",
            resultText: TopDressCalculator.summary(TopDressCalculator.compute(.init(diameterCm: 18, gramsPerSqM: 80))),
            saved: "2026-07-28",
            potLabel: "Citrus",
            waterLiters: 0,
            payload: payload(tool: .topDress, gramsPerSqM: 80, diameter: 18, preset: "bonemeal")
        ),
        line(
            id: "rack-dilute",
            projectID: "balcony-rack",
            tool: .diluteBottle,
            title: "Grow Big 4ml/L, 8L can",
            resultText: DiluteBottleCalculator.summary(.init(concentrateMl: 32, waterLiters: 8)),
            saved: "2026-08-01",
            potLabel: "Tomato A",
            waterLiters: 8,
            payload: payload(tool: .diluteBottle, tank: 8, rate: 4, preset: "growbig")
        ),
        line(
            id: "rack-flush",
            projectID: "balcony-rack",
            tool: .flushVolume,
            title: "Tomato A, 1.6L pot × 3",
            resultText: FlushVolumeCalculator.summary(.init(flushLiters: 4.8)),
            saved: "2026-08-05",
            potLabel: "Tomato A",
            waterLiters: 4.8,
            payload: payload(tool: .flushVolume, potLiters: 1.6, multiplier: 3)
        ),
        line(
            id: "rack-weekly",
            projectID: "balcony-rack",
            tool: .weeklyFeed,
            title: "Bloom 10-30-20, Tomato B",
            resultText: WeeklyFeedCalculator.summary(.init(gramsThisWeek: 3.6, gramsTotal: 3.6)),
            saved: "2026-08-08",
            potLabel: "Tomato B",
            waterLiters: 2,
            payload: payload(tool: .weeklyFeed, potLiters: 2, gramsPerLiter: 1.8, weeks: 1, preset: "bloom")
        ),
        line(
            id: "rack-foliar",
            projectID: "balcony-rack",
            tool: .foliarMix,
            title: "Silica 0.5ml/L, 2L",
            resultText: FoliarMixCalculator.summary(.init(concentrateMl: 1)),
            saved: "2026-08-12",
            potLabel: "Fig",
            waterLiters: 2,
            payload: payload(tool: .foliarMix, tank: 2, rate: 0.5, preset: "silica")
        ),
        line(
            id: "rack-pour",
            projectID: "balcony-rack",
            tool: .perPotPour,
            title: "8L across 12 pots",
            resultText: PerPotPourCalculator.summary(.init(mlPerPot: 666.7, litersPerPot: 0.667)),
            saved: "2026-08-15",
            potLabel: "Sage",
            waterLiters: 8,
            payload: payload(tool: .perPotPour, tank: 8, pots: 12)
        ),
        line(
            id: "ledge-tea",
            projectID: "bathroom-ledge",
            tool: .teaSteep,
            title: "Compost tea 1:10, 4L",
            resultText: TeaSteepCalculator.summary(.init(waterLiters: 3.64, teaLiters: 0.36)),
            saved: "2026-08-18",
            potLabel: "Boston",
            waterLiters: 4,
            payload: payload(tool: .teaSteep, tank: 4, waterParts: 10, teaParts: 1, preset: "compost")
        ),
        line(
            id: "ledge-flush",
            projectID: "bathroom-ledge",
            tool: .flushVolume,
            title: "Maidenhair 1.2L × 2",
            resultText: FlushVolumeCalculator.summary(.init(flushLiters: 2.4)),
            saved: "2026-08-22",
            potLabel: "Maidenhair",
            waterLiters: 2.4,
            payload: payload(tool: .flushVolume, potLiters: 1.2, multiplier: 2)
        ),
    ]

    static func bench(id: String) -> BenchItem {
        seedBenches.first(where: { $0.id == id }) ?? seedBenches[0]
    }

    static func preset(id: String) -> FeedPreset {
        feedPresets.first(where: { $0.id == id }) ?? feedPresets[0]
    }

    private static func line(
        id: String,
        projectID: String,
        tool: DoseTool,
        title: String,
        resultText: String,
        saved: String,
        potLabel: String,
        waterLiters: Double,
        payload: MixPayload
    ) -> MixLineItem {
        MixLineItem(
            id: id,
            projectID: projectID,
            calculatorType: tool.rawValue,
            title: title,
            resultText: resultText,
            detailJSON: SnapshotJSON.encode(payload),
            savedAt: MixDate.day(saved),
            potLabel: potLabel,
            waterLiters: waterLiters
        )
    }

    private static func payload(
        tool: DoseTool,
        tank: Double = 4,
        rate: Double = 2,
        pots: Double = 7,
        potLiters: Double = 2,
        gramsPerLiter: Double = 1.5,
        gramsPerSqM: Double = 80,
        weeks: Double = 1,
        diameter: Double = 18,
        waterParts: Double = 3,
        teaParts: Double = 1,
        multiplier: Double = 3,
        fraction: Double = 0.5,
        preset: String = "floragro"
    ) -> MixPayload {
        MixPayload(
            toolRaw: tool.rawValue,
            tankLiters: tank,
            rate: rate,
            pots: pots,
            weeks: weeks,
            diameterCm: diameter,
            waterParts: waterParts,
            teaParts: teaParts,
            multiplier: multiplier,
            fraction: fraction,
            potLiters: potLiters,
            gramsPerLiter: gramsPerLiter,
            gramsPerSqM: gramsPerSqM,
            presetID: preset
        )
    }
}
