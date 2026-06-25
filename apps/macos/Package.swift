// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ZacksBar",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "ZacksBarCore", targets: ["ZacksBarCore"]),
        .executable(name: "zacksbar-native-host", targets: ["ZacksBarNativeHost"]),
        .executable(name: "ZacksBarApp", targets: ["ZacksBarApp"])
    ],
    targets: [
        .target(name: "ZacksBarCore"),
        .executableTarget(name: "ZacksBarNativeHost", dependencies: ["ZacksBarCore"]),
        .executableTarget(name: "ZacksBarApp", dependencies: ["ZacksBarCore"]),
        .testTarget(name: "ZacksBarCoreTests", dependencies: ["ZacksBarCore"]),
        .testTarget(name: "ZacksBarAppTests", dependencies: ["ZacksBarApp", "ZacksBarCore"])
    ]
)
