// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "ExperimentsBoard",
    platforms: [.iOS(.v14), .tvOS(.v14), .watchOS(.v7), .macOS(.v11)],
    products: [
        .library(
            name: "ExperimentsBoard",
            targets: ["ExperimentsBoard"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.4.3"),
    ],
    targets: [
        .target(
            name: "ExperimentsBoard",
            swiftSettings: [
                /* Uncomment this to build as if SwiftUI was not available (e.g., to test building for Linux or WASI).
                   You must define this if EXPERIMENT_BOARD_DO_NOT_USE_OBSERVATION is set and SwiftUI is available. */
                // .define("EXPERIMENT_BOARD_DO_NOT_USE_SWIFTUI")
                
                /* Uncomment this to build as if Observation was not available (e.g., to test building for WASI). */
                // .define("EXPERIMENT_BOARD_DO_NOT_USE_OBSERVATION")
            ]
        ),
        .testTarget(
            name: "ExperimentsBoardTests",
            dependencies: ["ExperimentsBoard"]
        ),
    ],
    swiftLanguageVersions: [.v5, .version("6.0")]
)
