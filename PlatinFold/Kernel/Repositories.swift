import Foundation
import SwiftData

protocol ProjectStoring: AnyObject {
    func allProjects() -> [BenchItem]
    func project(id: String) -> BenchItem?
    func allLineItems() -> [MixLineItem]
    func lineItems(projectID: String) -> [MixLineItem]
    func saveLine(_ item: MixLineItem)
    func deleteAll()
}

final class SeededProjectStore: ProjectStoring {
    private var benches: [BenchItem]
    private var lines: [MixLineItem]

    init(benches: [BenchItem] = BenchSeed.seedBenches, lines: [MixLineItem] = BenchSeed.seedLineItems) {
        self.benches = benches
        self.lines = lines
    }

    func allProjects() -> [BenchItem] {
        benches.sorted { $0.createdAt < $1.createdAt }
    }

    func project(id: String) -> BenchItem? {
        benches.first(where: { $0.id == id })
    }

    func allLineItems() -> [MixLineItem] {
        lines.sorted { $0.savedAt > $1.savedAt }
    }

    func lineItems(projectID: String) -> [MixLineItem] {
        lines.filter { $0.projectID == projectID }.sorted { $0.savedAt > $1.savedAt }
    }

    func saveLine(_ item: MixLineItem) {
        lines.removeAll { $0.id == item.id }
        lines.append(item)
    }

    func deleteAll() {
        benches.removeAll()
        lines.removeAll()
    }
}

@MainActor
final class SwiftDataProjectStore: ProjectStoring {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func allProjects() -> [BenchItem] {
        let descriptor = FetchDescriptor<Project>(sortBy: [SortDescriptor(\.createdAt)])
        let rows = (try? context.fetch(descriptor)) ?? []
        return rows.map { $0.item() }
    }

    func project(id: String) -> BenchItem? {
        allProjects().first(where: { $0.id == id })
    }

    func allLineItems() -> [MixLineItem] {
        let descriptor = FetchDescriptor<LineItem>(sortBy: [SortDescriptor(\.savedAt, order: .reverse)])
        let rows = (try? context.fetch(descriptor)) ?? []
        return rows.map { $0.item() }
    }

    func lineItems(projectID: String) -> [MixLineItem] {
        allLineItems().filter { $0.projectID == projectID }
    }

    func saveLine(_ item: MixLineItem) {
        if let existing = fetchLine(id: item.id) {
            context.delete(existing)
        }
        context.insert(LineItem(item: item))
        try? context.save()
    }

    func deleteAll() {
        let benches = (try? context.fetch(FetchDescriptor<Project>())) ?? []
        benches.forEach { context.delete($0) }
        let lines = (try? context.fetch(FetchDescriptor<LineItem>())) ?? []
        lines.forEach { context.delete($0) }
        try? context.save()
    }

    private func fetchLine(id: String) -> LineItem? {
        let rows = (try? context.fetch(FetchDescriptor<LineItem>())) ?? []
        return rows.first(where: { $0.id == id })
    }
}
