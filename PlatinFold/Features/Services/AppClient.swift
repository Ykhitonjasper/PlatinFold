import Foundation

public protocol AppClientType: Sendable {
    func resolveResult() async -> LoadResult
}

public final class AppClient: @unchecked Sendable {
    public static let shared = AppClient()

    private let session: AppSessionType
    private let serviceURL: String

    public init(session: AppSessionType = AppSession.shared,
                serviceURL: String = AppConfig.serviceURL) {
        self.session = session
        self.serviceURL = serviceURL
    }

    public func resolveResult() async -> LoadResult {
        if session.isLocalOnly {
            return .local
        }
        if let cached = session.cachedURL {
            return await session.isOnline() ? .web(url: cached) : .local
        }
        guard !serviceURL.isEmpty, await session.isOnline() else { return .local }

        return await session.resolve(url: serviceURL)
    }
}

extension AppClient: AppClientType {}
