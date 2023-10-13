// swift-tools-version:5.7.1
import PackageDescription

let package = Package(
	name: "iRate",
	defaultLocalization: "en",
	platforms: [.iOS(.v13)],
	products: [
		.library(
			name: "iRate",
			targets: ["iRate"]),
	],
	targets: [
		.target(
			name: "iRate",
			path: "Sources",
			publicHeadersPath: ""),
	]
)
