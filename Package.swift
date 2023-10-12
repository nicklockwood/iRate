// swift-tools-version:5.7.1
import PackageDescription

let package = Package(
	name: "iRate",
	defaultLocalization: "en",
	platforms: [
		.iOS(.v13), // Adjust as needed
	],
	products: [
		// Products define the executables and libraries produced by a package, and make them visible to other packages.
		.library(
			name: "iRate",
			targets: ["iRate"]),
	],
	dependencies: [
		// Dependencies declare other packages that this package depends on.
		// .package(url: /* package url */, from: "1.0.0"),
	],
	targets: [
		// Targets are the basic building blocks of a package. A target can define a module or a test suite.
		// Targets can depend on other targets in this package, and on products in packages this package depends on.
		.target(
			name: "iRate",
			dependencies: [],
			path: "iRate"),
	]
)
