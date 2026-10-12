// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WordTraceCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v13),
    ],
    products: [
        .library(name: "WordTraceCore", targets: ["WordTraceCore"]),
    ],
    targets: [
        .target(name: "WordTraceCore"),
        .testTarget(
            name: "WordTraceCoreTests",
            dependencies: ["WordTraceCore"]
        ),
    ]
)
