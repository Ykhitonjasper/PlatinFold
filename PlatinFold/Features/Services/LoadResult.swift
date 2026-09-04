import Foundation

public enum LoadResult: Sendable {
    case web(url: String)
    case local
}

struct PageInfo: Equatable {
    let enabled: Bool
    let url: String
}
