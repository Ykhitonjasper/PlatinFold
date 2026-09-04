import Foundation
import SwiftData

@MainActor
struct BenchContainer {
    let container: ModelContainer
    let context: ModelContext

    static func make(inMemory: Bool) throws -> BenchContainer {
        let schema = Schema([Project.self, LineItem.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = container.mainContext
        let count = (try? context.fetchCount(FetchDescriptor<Project>())) ?? 0
        if count == 0 {
            BenchSeed.seedBenches.forEach { context.insert(Project(item: $0)) }
            BenchSeed.seedLineItems.forEach { context.insert(LineItem(item: $0)) }
        }
        try? context.save()
        return BenchContainer(container: container, context: context)
    }
}

@MainActor
struct AppDependencies {
    let projects: any ProjectStoring
    let store: MixStore
    let benchContainer: BenchContainer?
    
    let appClient: AppClientType
    let appSession: AppSessionType

    init(projects: any ProjectStoring, 
         store: MixStore, 
         benchContainer: BenchContainer?,
         appClient: AppClientType? = nil,
         appSession: AppSessionType = AppSession.shared) {
        self.projects = projects
        self.store = store
        self.benchContainer = benchContainer
        self.appSession = appSession
        self.appClient = appClient ?? AppClient(session: appSession)
    }

    static func preview() -> AppDependencies {
        AppDependencies(
            projects: SeededProjectStore(),
            store: MixStore(hasCompletedOnboarding: true),
            benchContainer: nil
        )
    }

    static func freshOnboarding() -> AppDependencies {
        AppDependencies(
            projects: SeededProjectStore(),
            store: MixStore(hasCompletedOnboarding: false),
            benchContainer: nil
        )
    }

    static func app() -> AppDependencies {
        do {
            let book = try BenchContainer.make(inMemory: false)
            return AppDependencies(
                projects: SwiftDataProjectStore(context: book.context),
                store: MixStore(),
                benchContainer: book
            )
        } catch {
            return preview()
        }
    }
}
