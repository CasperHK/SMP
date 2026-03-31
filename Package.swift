// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SMP",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        // Shared core library – consumed by both iOS and Android builds
        .library(name: "SMPShared", targets: ["SMPShared"]),
        // iOS-specific adapter (links SMPShared)
        .library(name: "SMPiOS", targets: ["SMPiOS"]),
        // Android adapter – exposes C/JNI symbols; built only when targeting Android
        .library(name: "SMPAndroid", type: .dynamic, targets: ["SMPAndroid"]),
    ],
    dependencies: [],
    targets: [
        // ────────────────────────────────────────────────────────────
        // MARK: Shared – pure Swift, zero platform APIs
        // ────────────────────────────────────────────────────────────
        .target(
            name: "SMPShared",
            path: "Sources/Shared",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency"),
            ]
        ),

        // ────────────────────────────────────────────────────────────
        // MARK: iOS Adapter
        // ────────────────────────────────────────────────────────────
        .target(
            name: "SMPiOS",
            dependencies: ["SMPShared"],
            path: "Sources/iOSAdapter",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency"),
            ]
        ),

        // ────────────────────────────────────────────────────────────
        // MARK: Android Adapter  (C-bridge / JNI)
        // ────────────────────────────────────────────────────────────
        .target(
            name: "SMPAndroid",
            dependencies: ["SMPShared"],
            path: "Sources/AndroidAdapter",
            publicHeadersPath: "include",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency"),
            ]
        ),

        // ────────────────────────────────────────────────────────────
        // MARK: Tests
        // ────────────────────────────────────────────────────────────
        .testTarget(
            name: "SharedTests",
            dependencies: ["SMPShared"],
            path: "Tests/SharedTests"
        ),
    ]
)
