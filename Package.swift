// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "WebKitScreenTimeWorkaround",
    platforms: [
        .iOS("26.1"),
    ],
    products: [
        .library(
            name: "WebKitScreenTimeWorkaround",
            targets: ["WebKitScreenTimeWorkaround"]
        ),
    ],
    targets: [
        .target(
            name: "WebKitScreenTimeWorkaroundRuntime",
            linkerSettings: [.linkedFramework("WebKit")]
        ),
        .target(
            name: "WebKitScreenTimeWorkaround",
            dependencies: ["WebKitScreenTimeWorkaroundRuntime"],
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ],
        ),
        .testTarget(
            name: "WebKitScreenTimeWorkaroundTests",
            dependencies: ["WebKitScreenTimeWorkaround"],
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ],
        ),
    ]
)
