// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Ascend",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "Ascend",
            type: .dynamic,
            targets: ["Ascend"])
    ],
    dependencies: [
        // No external dependencies
    ],
    targets: [
        // Primary target for source distribution
        .target(
            name: "Ascend",
            dependencies: [],
            path: "Sources",
            exclude: [],
            linkerSettings: [
                .linkedFramework("UIKit", .when(platforms: [.iOS])),
                .linkedFramework("SystemConfiguration", .when(platforms: [.iOS])),
                .linkedFramework("CoreLocation", .when(platforms: [.iOS]))
            ]
        ),
        
        // Binary target for compiled distribution (optional)
        // Uncomment when you have a built .xcframework
        // .binaryTarget(
        //     name: "AscendBinary",
        //     url: "https://github.com/dream11/ascend-ios/releases/download/1.0.0/Ascend.xcframework.zip",
        //     checksum: "YOUR_CHECKSUM_HERE"
        // )
    ],
    swiftLanguageVersions: [.v5]
)

