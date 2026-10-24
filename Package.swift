// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "SwiftXMLParser",
    platforms: [
        .iOS("8.0"),
        .macOS("10.9"),
        .tvOS("9.0"),
        .watchOS("2.0")
    ],
    products: [
        .library(name: "SwiftXMLParser", targets: ["SwiftXMLParser"])
    ],
    targets: [
        .target(
            name: "SwiftXMLParser",
            path: "Sources"
        ),
        .testTarget(
            name: "SwiftXMLParserTests",
            dependencies: ["SwiftXMLParser"],
            path: "Tests/SwiftXMLParserTests"
        )
    ],
    swiftLanguageVersions: [.v5]
)
