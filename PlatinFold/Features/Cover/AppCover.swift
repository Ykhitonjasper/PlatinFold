import SwiftUI

@MainActor
final class AppCover: ObservableObject {
    /// Long enough to soften the reveal, short enough not to read as a wait.
    static let revealDuration: TimeInterval = 0.2

    @Published private(set) var isCoverVisible = false

    func handleScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .inactive, .background:
            showCover()
        case .active:
            liftCover()
        @unknown default:
            break
        }
    }

    func deactivateImmediately() {
        liftCover()
    }

    /// iOS snapshots the scene for the app switcher right after it resigns
    /// active, so the cover has to be opaque in the very first frame it appears.
    /// Fading it in would hand the snapshot a half-transparent overlay with the
    /// content still legible underneath.
    private func showCover() {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) { isCoverVisible = true }
    }

    /// Nothing gets snapshotted on the way back in, so the cover lifts at once
    /// and only fades to avoid a hard pop.
    private func liftCover() {
        guard isCoverVisible else { return }
        let animation = UIAccessibility.isReduceMotionEnabled
            ? nil
            : Animation.easeInOut(duration: Self.revealDuration)
        withAnimation(animation) { isCoverVisible = false }
    }
}
