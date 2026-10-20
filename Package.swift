// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "WebKitTestWorkarounds",
    platforms: [
        .iOS("17.0"),
        .macOS("14.0"),
    ],
    products: [
        .library(
            name: "WebKitTestWorkarounds",
            targets: ["WebKitTestWorkarounds"]
        ),
    ],
    targets: [
        .target(
            name: "WebKitTestWorkaroundsRuntime",
            linkerSettings: [.linkedFramework("WebKit")]
        ),
        .target(
            name: "WebKitTestWorkarounds",
            dependencies: ["WebKitTestWorkaroundsRuntime"],
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ],
        ),
        .testTarget(
            name: "WebKitTestWorkaroundsTests",
            dependencies: ["WebKitTestWorkarounds"],
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ],
        ),
    ]
)
