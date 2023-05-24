// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "konashi-ios-sdk2",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "Konashi",
            targets: ["Konashi"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/CombineCommunity/CombineExt.git",
            from: "1.0.0"
        ),
        .package(
            url: "https://github.com/krzysztofzablocki/Difference.git",
            from: "1.0.0"
        ),
        .package(
            name: "NordicMesh",
            url: "https://github.com/YUKAI/IOS-nRF-Mesh-Library",
            branch: "main"
        ),
        .package(
            name: "Promises",
            url: "https://github.com/google/promises.git",
            from: "2.1.0"
        )
    ],
    targets: [
        .target(
            name: "Konashi",
            dependencies: [
                "CombineExt",
                "NordicMesh",
                "Promises"
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "KonashiTests",
            dependencies: [
                "Konashi",
                "CombineExt",
                "Difference",
                "NordicMesh",
                "Promises"
            ],
            path: "Tests"
        )
    ]
)
