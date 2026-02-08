// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "OpenClawDesktop",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "OpenClawDesktop",
            path: "Sources",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "OpenClawDesktopTests",
            dependencies: ["OpenClawDesktop"],
            path: "Tests"
        )
    ]
)
