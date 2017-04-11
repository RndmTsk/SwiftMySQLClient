import PackageDescription

let package = Package(
	name: "SwiftMySQLClient",
	dependencies: [
		.Package(url: "https://github.com/IBM-Swift/BlueSocket.git", majorVersion: 0, minor: 12),
		.Package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", Version(0, 6, 8)),
		.Package(url: "https://github.com/antitypical/Result.git",
		         majorVersion: 3)
	]
)
