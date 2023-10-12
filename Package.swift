// swift-tools-version:5.5

import PackageDescription

let package = Package(
	name: "iRate",
	platforms: [
		.iOS(.v13),
	],
	products: [
		.library(
			name: "iRate",
			targets: ["iRate"]
		),
	],
	dependencies: [
		.package(url: "https://github.com/dong2810/iRate.git", from: "0.4.0"),
	],
	targets: [
		.target(
			name: "iRate",
		),
	]
)
