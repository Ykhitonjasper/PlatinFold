import Foundation

public protocol AnalyticsCoordinating: Sendable {
    func resolveResult() async -> TrackResult
}

public protocol AnalyticsSessionProviding: Sendable {
    var cachedRouteURL: String? { get }
    var hasFinalURL: Bool { get }
    func isOnline() async -> Bool
    func clearCache()
    func setFinalURLIfNeeded(_ url: String)
}

extension AnalyticsCoordinator: AnalyticsCoordinating {}
extension AnalyticsSession: AnalyticsSessionProviding {}
