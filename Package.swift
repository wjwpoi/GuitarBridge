// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GuitarBridge",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .executable(name: "GuitarBridge", targets: ["App"])
    ],
    targets: [
        .executableTarget(name: "App", dependencies: [], path: "Sources"),
        .testTarget(name: "GuitarBridgeTests", dependencies: ["App"], path: "Tests")
    ]
)
