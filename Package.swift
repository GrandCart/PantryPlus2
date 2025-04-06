// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PantryPlus2",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "PantryPlus2",
            targets: ["PantryPlus2"]),
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", "11.0.0"..<"12.0.0")
    ],
    targets: [
        .target(
            name: "PantryPlus2",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk"),
                .product(name: "FirebaseMessaging", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk")
            ],
            path: "Sources/PantryPlus2",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "PantryPlus2Tests",
            dependencies: ["PantryPlus2"]
        ),
    ]
) 