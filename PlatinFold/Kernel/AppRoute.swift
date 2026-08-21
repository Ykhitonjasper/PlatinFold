import Foundation

enum AppRoute: Hashable {
    case tool(DoseTool)
    case reopen(DoseTool, json: String)
    case bench(String)
    case recipes
    case calendar
}
