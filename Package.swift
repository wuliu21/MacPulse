// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "MacPulse",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "MacPulse", targets: ["MacPulse"])
    ],
    targets: [
        .executableTarget(
            name: "MacPulse",
            path: "Sources/MacPulse",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI"),
                .linkedFramework("IOKit"),
                .linkedFramework("CoreGraphics")
            ]
        )
    ]
)
