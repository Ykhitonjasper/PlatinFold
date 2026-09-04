import Foundation

/// Which launch path to take: cold branded splash, first warm overlay, or hot crossfade.
enum LaunchTier: Equatable {
    case cold
    case warmFirst
    case warmHot

    var showsBrandedSplash: Bool {
        if case .cold = self { return true }
        return false
    }

    var showsWarmOverlay: Bool {
        if case .warmFirst = self { return true }
        return false
    }

    var loaderMin: TimeInterval {
        switch self {
        case .cold: Timeouts.coldLoaderMin
        case .warmFirst: Timeouts.warm2OverlayMin
        case .warmHot: Timeouts.warm3OverlayMin
        }
    }

    var loaderMax: TimeInterval {
        switch self {
        case .cold: Timeouts.coldLoaderMax
        case .warmFirst: Timeouts.warm2OverlayMax
        case .warmHot: Timeouts.warm3LoaderMax
        }
    }

    var contentProbeWindow: TimeInterval {
        switch self {
        case .cold: Timeouts.coldContentProbe
        case .warmFirst: Timeouts.warm2ContentProbe
        case .warmHot: Timeouts.warm3ContentProbe
        }
    }

    static func resolve(cachedURL: String?, launchCount: Int) -> LaunchTier {
        guard cachedURL != nil else { return .cold }
        if launchCount < 1 { return .warmFirst }
        return .warmHot
    }
}

/// Internal milestones only — UI copy must NOT mirror network steps.
enum LaunchLoaderStage: String, Equatable {
    case idle
    case starting
    case deciding
    case loadingRoute
    case preparingContent
    case finishing
    case complete
}

/// Neutral app-boot copy driven by progress %, never by decide/probe.
enum LaunchSplashCopy {
    static func message(for progress: Double) -> String {
        switch progress {
        case ..<0.40:
            return "Preparing workspace..."
        case ..<0.78:
            return "Loading preferences..."
        case ..<1.0:
            return "Almost ready..."
        default:
            return "Ready"
        }
    }
}
