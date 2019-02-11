// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "ssh-kit",
    products: [
        .library(name: "SSHKit", targets: ["SSHKit"]),
    ],
    dependencies: [ ],
    targets: [
        .systemLibrary(
            name: "CSSHKit",
            pkgConfig: "libssh",
            providers: [
                .apt(["libssh"]),
                .brew(["libssh"]),
            ]
        ),
        .target(name: "SSHKit", dependencies: ["CSSHKit"]),
        .testTarget(name: "SSHKitTests", dependencies: ["SSHKit"]),
    ]
)
