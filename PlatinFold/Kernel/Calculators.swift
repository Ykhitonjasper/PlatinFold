import Foundation

enum DiluteBottleCalculator {
    struct Input: Codable, Hashable {
        var tankLiters: Double
        var mlPerLiter: Double
    }

    struct Output: Codable, Hashable {
        var concentrateMl: Double
        var waterLiters: Double
    }

    static func compute(_ input: Input) -> Output {
        let tank = max(input.tankLiters, 0)
        let rate = max(input.mlPerLiter, 0)
        return Output(concentrateMl: tank * rate, waterLiters: tank)
    }

    static func summary(_ output: Output) -> String {
        "\(MixMath.ml(output.concentrateMl)) in \(MixMath.liters(output.waterLiters))"
    }
}

enum PerPotPourCalculator {
    struct Input: Codable, Hashable {
        var tankLiters: Double
        var potCount: Double
    }

    struct Output: Codable, Hashable {
        var mlPerPot: Double
        var litersPerPot: Double
    }

    static func compute(_ input: Input) -> Output {
        let pots = max(input.potCount, 1)
        let ml = max(input.tankLiters, 0) * 1000 / pots
        return Output(mlPerPot: ml, litersPerPot: ml / 1000)
    }

    static func summary(_ output: Output) -> String {
        "\(MixMath.ml(output.mlPerPot)) each"
    }
}

enum WeeklyFeedCalculator {
    struct Input: Codable, Hashable {
        var potLiters: Double
        var gramsPerLiter: Double
        var weeks: Double
    }

    struct Output: Codable, Hashable {
        var gramsThisWeek: Double
        var gramsTotal: Double
    }

    static func compute(_ input: Input) -> Output {
        let weekly = max(input.potLiters, 0) * max(input.gramsPerLiter, 0)
        return Output(gramsThisWeek: weekly, gramsTotal: weekly * max(input.weeks, 1))
    }

    static func summary(_ output: Output) -> String {
        MixMath.grams(output.gramsThisWeek)
    }
}

enum TopDressCalculator {
    struct Input: Codable, Hashable {
        var diameterCm: Double
        var gramsPerSqM: Double
    }

    struct Output: Codable, Hashable {
        var surfaceM2: Double
        var grams: Double
    }

    static func compute(_ input: Input) -> Output {
        let radiusM = max(input.diameterCm, 0) / 200
        let area = Double.pi * radiusM * radiusM
        return Output(surfaceM2: area, grams: area * max(input.gramsPerSqM, 0))
    }

    static func summary(_ output: Output) -> String {
        MixMath.grams(output.grams)
    }
}

enum TeaSteepCalculator {
    struct Input: Codable, Hashable {
        var bucketLiters: Double
        var waterParts: Double
        var teaParts: Double
    }

    struct Output: Codable, Hashable {
        var waterLiters: Double
        var teaLiters: Double
    }

    static func compute(_ input: Input) -> Output {
        let parts = max(input.waterParts + input.teaParts, 0.0001)
        let bucket = max(input.bucketLiters, 0)
        return Output(
            waterLiters: bucket * max(input.waterParts, 0) / parts,
            teaLiters: bucket * max(input.teaParts, 0) / parts
        )
    }

    static func summary(_ output: Output) -> String {
        "\(MixMath.liters(output.teaLiters)) tea"
    }
}

enum FlushVolumeCalculator {
    struct Input: Codable, Hashable {
        var potLiters: Double
        var multiplier: Double
    }

    struct Output: Codable, Hashable {
        var flushLiters: Double
    }

    static func compute(_ input: Input) -> Output {
        Output(flushLiters: max(input.potLiters, 0) * max(input.multiplier, 1))
    }

    static func summary(_ output: Output) -> String {
        MixMath.liters(output.flushLiters)
    }
}

enum FoliarMixCalculator {
    struct Input: Codable, Hashable {
        var tankLiters: Double
        var mlPerLiter: Double
    }

    struct Output: Codable, Hashable {
        var concentrateMl: Double
    }

    static func compute(_ input: Input) -> Output {
        Output(concentrateMl: max(input.tankLiters, 0) * max(input.mlPerLiter, 0))
    }

    static func summary(_ output: Output) -> String {
        MixMath.ml(output.concentrateMl)
    }
}

enum SeedlingCutCalculator {
    struct Input: Codable, Hashable {
        var adultMlPerLiter: Double
        var fraction: Double
        var tankLiters: Double
    }

    struct Output: Codable, Hashable {
        var cutMlPerLiter: Double
        var concentrateMl: Double
    }

    static func compute(_ input: Input) -> Output {
        let cut = max(input.adultMlPerLiter, 0) * max(input.fraction, 0)
        return Output(cutMlPerLiter: cut, concentrateMl: cut * max(input.tankLiters, 0))
    }

    static func summary(_ output: Output) -> String {
        "\(MixMath.number(output.cutMlPerLiter, digits: 2)) ml/L"
    }
}
