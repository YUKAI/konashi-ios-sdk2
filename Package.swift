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
        ),
        .library(
            name: "KonashiUI",
            targets: ["KonashiUI"]
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
            url: "https://github.com/NordicSemiconductor/IOS-nRF-Mesh-Library",
            from: "3.2.0"
        ),
        .package(
            url: "https://github.com/JonasGessner/JGProgressHUD.git",
            from: "2.0.0"
        )
    ],
    targets: [
        .target(
            name: "Konashi",
            dependencies: [
                "CombineExt",
                "NordicMesh"
            ],
            path: "Sources/Konashi"
        ),
        .testTarget(
            name: "KonashiTests",
            dependencies: [
                "Konashi",
                "Difference"
            ],
            path: "Tests/KonashiTests"
        ),
        .target(
            name: "KonashiUI",
            dependencies: [
                "Konashi",
                "JGProgressHUD"
            ],
            path: "Sources/KonashiUI"
        ),
        .testTarget(
            name: "KonashiUITests",
            dependencies: ["KonashiUI"],
            path: "Tests/KonashiUITests"
        )
    ]
)
