import Foundation

enum Timeouts {
    // Shared budgets
    public static let startup: TimeInterval = 5.5
    public static let coldStart: TimeInterval = 8.0
    public static let primingWindow: TimeInterval = 6.0
    /// Fail-closed decide cap — short so splash never "waits on the network".
    public static let decisionDeadline: TimeInterval = 2.5
    public static let minimumReadyWindow: TimeInterval = 1.5
    public static let networkTimeout: TimeInterval = 3.0
    public static let networkProbeTimeout: TimeInterval = 0.4
    public static let networkProbeCacheTTL: TimeInterval = 2.0
    public static let coverFadeOut: TimeInterval = 0.2
    public static let nativeFlashMax: TimeInterval = 0.3

    /// Splash → web dissolve after content is ready (chrome exits, then veil).
    public static let revealCrossfade: TimeInterval = 0.48
    /// Warm #2 dissolve — slightly snappier than cold, still staged.
    public static let warmRevealCrossfade: TimeInterval = 0.36

    // Content probe — first visible frame requires score ≥ 15 (see WebViewController.Tuning)
    public static let contentProbeMinScore = 15

    // Cold launch #1 — short enough for review, covers typical ~4.5s ready
    public static let coldLoaderMin: TimeInterval = 1.4
    public static let coldLoaderMax: TimeInterval = 4.9
    public static let coldContentProbe: TimeInterval = 4.4
    public static let coldGracefulFade: TimeInterval = 0.35
    /// Smooth bar reaches ~85% over this window regardless of decide/probe.
    public static let coldSplashFeel: TimeInterval = 1.6

    // Warm launch #2 — short overlay, small headroom over probe
    public static let warm2OverlayMin: TimeInterval = 0.25
    public static let warm2OverlayMax: TimeInterval = 3.0
    public static let warm2ContentProbe: TimeInterval = 2.5

    // Warm launch #3+ — scrim; probe == max (no tail after first wait)
    public static let warm3OverlayMin: TimeInterval = 0.0
    public static let warm3LoaderMax: TimeInterval = 2.5
    public static let warm3ContentProbe: TimeInterval = 2.5
    /// Probe ready within this → skip scrim UI, opacity-only handoff.
    public static let warm3InstantThreshold: TimeInterval = 0.2
    public static let warm3ScrimMax: TimeInterval = 0.32

    // Legacy alias kept for tests that still reference the old floor
    public static let minimumWarmup: TimeInterval = warm2OverlayMin
    public static let contentProbeWindow: TimeInterval = coldContentProbe
    public static let warm3OverlayFallback: TimeInterval = warm3ScrimMax
}
