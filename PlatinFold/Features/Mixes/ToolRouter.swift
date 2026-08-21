import SwiftUI

@MainActor
enum ToolRouter {
    @ViewBuilder
    static func screen(_ tool: DoseTool, payload: MixPayload?, dependencies: AppDependencies) -> some View {
        switch tool {
        case .diluteBottle:
            DiluteBottleScreen(payload: payload, dependencies: dependencies)
        case .perPotPour:
            PerPotPourScreen(payload: payload, dependencies: dependencies)
        case .weeklyFeed:
            WeeklyFeedScreen(payload: payload, dependencies: dependencies)
        case .topDress:
            TopDressScreen(payload: payload, dependencies: dependencies)
        case .teaSteep:
            TeaSteepScreen(payload: payload, dependencies: dependencies)
        case .flushVolume:
            FlushVolumeScreen(payload: payload, dependencies: dependencies)
        case .foliarMix:
            FoliarMixScreen(payload: payload, dependencies: dependencies)
        case .seedlingCut:
            SeedlingCutScreen(payload: payload, dependencies: dependencies)
        }
    }
}
