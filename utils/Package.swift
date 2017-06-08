// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "PatchUtils",
    products: [
        .library(name: "PatchUtils", targets: [ "PatchUtils" ]),
        .executable(name: "mkdiskimg", targets: [ "mkdiskimg" ]),
        .executable(name: "efi_patch", targets: [ "efi_patch" ]),
        .executable(name: "foverride", targets: [ "foverride" ])
    ],
    targets: [
        .target(
            name: "PatchUtils"),
        .target(
            name: "mkdiskimg",
            dependencies: [ "PatchUtils" ]),
        .target(
            name: "efi_patch",
            dependencies: [ "PatchUtils" ]),
        .target(
            name: "foverride",
            dependencies: [ "PatchUtils" ])
    ]
)
