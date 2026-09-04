import SwiftData
import SwiftUI

@main
struct PlatinFoldApp: App {
    private let dependencies = AppDependencies.app()

    var body: some Scene {
        WindowGroup {
            Group {
                if let container = dependencies.benchContainer?.container {
                    RootView(dependencies: dependencies)
                        .environment(dependencies.store)
                        .modelContainer(container)
                } else {
                    RootView(dependencies: dependencies)
                        .environment(dependencies.store)
                }
            }
        }
    }
}
