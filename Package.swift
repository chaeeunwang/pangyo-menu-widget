// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "PangyoMenuWidget",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "MenuWidgetCore", targets: ["MenuWidgetCore"])
    ],
    targets: [
        .target(name: "MenuWidgetCore"),
        .testTarget(
            name: "MenuWidgetCoreTests",
            dependencies: ["MenuWidgetCore"]
        )
    ],
    swiftLanguageModes: [.v5]
)
