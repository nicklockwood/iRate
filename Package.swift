// swift-tools-version:5.6
import PackageDescription

let package = Package(
    name: "iRate",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "iRate",
            targets: ["iRate"]),
    ],
    targets: [
        .target(
            name: "iRate")
    ]
)
