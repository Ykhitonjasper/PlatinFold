import Foundation
import SwiftData

struct AppTab: Hashable, Identifiable {
    let id: String
    let label: String
    let systemImage: String

    static let mixes = AppTab(id: "mixes", label: "Mixes", systemImage: "drop.halffull")
    static let benches = AppTab(id: "benches", label: "Benches", systemImage: "square.grid.3x3")
    static let export = AppTab(id: "export", label: "Export", systemImage: "doc.richtext")
    static let settings = AppTab(id: "settings", label: "Settings", systemImage: "gearshape")
    static let allCases: [AppTab] = [.mixes, .benches, .export, .settings]
}

enum DoseTool: String, CaseIterable, Identifiable, Codable, Hashable {
    case diluteBottle
    case perPotPour
    case weeklyFeed
    case topDress
    case teaSteep
    case flushVolume
    case foliarMix
    case seedlingCut

    var id: String { rawValue }

    var verb: String {
        switch self {
        case .diluteBottle: return "Dilute bottle"
        case .perPotPour: return "Per-pot pour"
        case .weeklyFeed: return "Weekly feed"
        case .topDress: return "Top dress"
        case .teaSteep: return "Tea steep"
        case .flushVolume: return "Flush volume"
        case .foliarMix: return "Foliar mix"
        case .seedlingCut: return "Seedling cut"
        }
    }

    var sampleValue: String {
        switch self {
        case .diluteBottle: return "8 ml"
        case .perPotPour: return "571 ml"
        case .weeklyFeed: return "3 g"
        case .topDress: return "2 g"
        case .teaSteep: return "3.5 L"
        case .flushVolume: return "4.8 L"
        case .foliarMix: return "6 ml"
        case .seedlingCut: return "1 ml"
        }
    }

    var sampleCaption: String {
        switch self {
        case .diluteBottle: return "4 L tank · 2 ml/L"
        case .perPotPour: return "4 L across 7 pots"
        case .weeklyFeed: return "2 L pot · 1.5 g/L"
        case .topDress: return "18 cm · 80 g/m²"
        case .teaSteep: return "14 L bucket · 3:1"
        case .flushVolume: return "1.6 L pot · 3×"
        case .foliarMix: return "1 L sprayer · 6 ml/L"
        case .seedlingCut: return "half of 2 ml/L"
        }
    }

    var group: MixGroup {
        switch self {
        case .diluteBottle, .teaSteep, .foliarMix: return .mix
        case .weeklyFeed, .topDress, .seedlingCut: return .feed
        case .perPotPour, .flushVolume: return .rinse
        }
    }
}

enum MixGroup: String, CaseIterable, Identifiable {
    case all
    case mix
    case feed
    case rinse

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "All"
        case .mix: return "Mix"
        case .feed: return "Feed"
        case .rinse: return "Rinse"
        }
    }
}

struct FeedPreset: Identifiable, Hashable {
    let id: String
    let name: String
    let group: MixGroup
    let mlPerLiter: Double
    let gramsPerLiter: Double
    let waterParts: Double
    let teaParts: Double
    let note: String
}

struct MixPayload: Codable, Hashable {
    var toolRaw: String
    var tankLiters: Double
    var rate: Double
    var pots: Double
    var weeks: Double
    var diameterCm: Double
    var waterParts: Double
    var teaParts: Double
    var multiplier: Double
    var fraction: Double
    var potLiters: Double
    var gramsPerLiter: Double
    var gramsPerSqM: Double
    var presetID: String

    static func empty(tool: DoseTool) -> MixPayload {
        MixPayload(
            toolRaw: tool.rawValue,
            tankLiters: 4,
            rate: 2,
            pots: 7,
            weeks: 1,
            diameterCm: 18,
            waterParts: 3,
            teaParts: 1,
            multiplier: 3,
            fraction: 0.5,
            potLiters: 2,
            gramsPerLiter: 1.5,
            gramsPerSqM: 80,
            presetID: "floragro"
        )
    }
}

struct BenchItem: Identifiable, Hashable {
    let id: String
    let name: String
    let note: String
    let potCount: Int
    let location: String
    let createdAt: Date
    let potNames: [String]
}

struct MixLineItem: Identifiable, Hashable {
    let id: String
    let projectID: String
    let calculatorType: String
    let title: String
    let resultText: String
    let detailJSON: String
    let savedAt: Date
    let potLabel: String
    let waterLiters: Double

    var tool: DoseTool {
        DoseTool(rawValue: calculatorType) ?? .diluteBottle
    }
}

@Model
final class Project {
    @Attribute(.unique) var id: String
    var name: String
    var note: String
    var potCount: Int
    var location: String
    var createdAt: Date
    var potNamesJSON: String

    init(item: BenchItem) {
        id = item.id
        name = item.name
        note = item.note
        potCount = item.potCount
        location = item.location
        createdAt = item.createdAt
        potNamesJSON = SnapshotJSON.encode(item.potNames)
    }

    func item() -> BenchItem {
        BenchItem(
            id: id,
            name: name,
            note: note,
            potCount: potCount,
            location: location,
            createdAt: createdAt,
            potNames: SnapshotJSON.decode([String].self, from: potNamesJSON) ?? []
        )
    }
}

@Model
final class LineItem {
    @Attribute(.unique) var id: String
    var projectID: String
    var calculatorType: String
    var title: String
    var resultText: String
    var detailJSON: String
    var savedAt: Date
    var potLabel: String
    var waterLiters: Double

    init(item: MixLineItem) {
        id = item.id
        projectID = item.projectID
        calculatorType = item.calculatorType
        title = item.title
        resultText = item.resultText
        detailJSON = item.detailJSON
        savedAt = item.savedAt
        potLabel = item.potLabel
        waterLiters = item.waterLiters
    }

    func item() -> MixLineItem {
        MixLineItem(
            id: id,
            projectID: projectID,
            calculatorType: calculatorType,
            title: title,
            resultText: resultText,
            detailJSON: detailJSON,
            savedAt: savedAt,
            potLabel: potLabel,
            waterLiters: waterLiters
        )
    }
}

enum SnapshotJSON {
    static func encode<T: Encodable>(_ value: T) -> String {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(value), let text = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return text
    }

    static func decode<T: Decodable>(_ type: T.Type, from text: String) -> T? {
        guard let data = text.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
