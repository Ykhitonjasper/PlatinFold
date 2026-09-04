// swift-tools-version: 6.3
// Alamofire 5.12.0, vendored locally. Unused header helpers trimmed from this copy.
// MIT: see LICENSE. Original: https://github.com/Alamofire/Alamofire

import PackageDescription

let package = Package(
    name: "Alamofire",
    platforms: [
        .macOS(.v10_13),
        .iOS(.v12),
        .tvOS(.v12),
        .watchOS(.v4)
    ],
    products: [
        .library(name: "Alamofire", targets: ["Alamofire"])
    ],
    targets: [
        .target(
            name: "Alamofire",
            path: "Source",
            exclude: [
                "Info.plist"
            ],
            resources: [.process("PrivacyInfo.xcprivacy")],
            swiftSettings: [.enableUpcomingFeature("ExistentialAny")],
            linkerSettings: [
                .linkedFramework(
                    "CFNetwork",
                    .when(platforms: [.iOS, .macOS, .tvOS, .watchOS])
                )
            ]
        )
    ],
    swiftLanguageModes: [.v5]
)
