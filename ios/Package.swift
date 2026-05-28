// swift-tools-version: 5.9
// Required for Flutter Swift Package Manager support.
// Flutter's build system automatically injects the Flutter.xcframework
// binary target when building, so it does not need to be listed here.

import PackageDescription

let package = Package(
    name: "flutter_keyboard_controller",
    platforms: [
        .iOS("13.0"),
    ],
    products: [
        .library(
            name: "flutter_keyboard_controller",
            targets: ["flutter_keyboard_controller"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "flutter_keyboard_controller",
            dependencies: [],
            path: "Classes"
        ),
    ]
)
