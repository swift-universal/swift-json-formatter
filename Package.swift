// swift-tools-version:6.2
import Foundation
import PackageDescription

let useLocalDeps: Bool = {
  guard let raw = ProcessInfo.processInfo.environment["SPM_USE_LOCAL_DEPS"] else { return true }
  let v = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
  return !(v == "0" || v == "false" || v == "no")
}()

func localOrRemote(
  name: String, path: String, remote: () -> Package.Dependency
) -> Package.Dependency {
  if useLocalDeps { return .package(name: name, path: path) }
  return remote()
}

let package = Package(
  name: "swift-json-formatter",
  platforms: [
    .macOS(.v15)
  ],
  products: [
    .library(name: "SwiftJSONFormatter", targets: ["SwiftJSONFormatter"]),
    .executable(name: "swift-json-formatter", targets: ["SwiftJSONFormatterCLI"]),
  ],
  dependencies: [
    .package(url: "https://github.com/swift-universal/swift-formatting-core.git", from: "0.0.1"),
    localOrRemote(
      name: "wrkstrm-foundation",
      path: "../../../../../../../wrkstrm/spm/universal/domain/system/wrkstrm-foundation",
      remote: { .package(url: "https://github.com/wrkstrm/wrkstrm-foundation.git", from: "3.0.0") }),
    localOrRemote(
      name: "common-log",
      path: "../../../../../../../swift-universal/public/spm/universal/domain/system/common-log",
      remote: { .package(url: "https://github.com/swift-universal/common-log.git", from: "3.0.0") }),
    localOrRemote(
      name: "common-cli",
      path: "../../../../../../../swift-universal/public/spm/universal/domain/system/common-cli",
      remote: { .package(url: "https://github.com/swift-universal/swift-common-cli.git", from: "0.1.0") }),
    localOrRemote(
      name: "common-shell",
      path: "../../../../../../../swift-universal/public/spm/universal/domain/system/common-shell",
      remote: { .package(url: "https://github.com/swift-universal/common-shell.git", from: "0.0.1") }),
    localOrRemote(
      name: "wrkstrm-main",
      path: "../../../../../../../wrkstrm/spm/universal/domain/system/wrkstrm-main",
      remote: { .package(url: "https://github.com/wrkstrm/wrkstrm-main.git", from: "3.0.0") }),
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.6.0"),
  ],
  targets: [
    .target(
      name: "SwiftJSONFormatter",
      dependencies: [
        .product(name: "SwiftFormattingCore", package: "swift-formatting-core"),
        .product(name: "WrkstrmFoundation", package: "wrkstrm-foundation"),
        .product(name: "WrkstrmMain", package: "wrkstrm-main"),
      ],
      path: "sources/swift-json-formatter"
    ),
    .executableTarget(
      name: "SwiftJSONFormatterCLI",
      dependencies: [
        "SwiftJSONFormatter",
        .product(name: "SwiftFormattingCore", package: "swift-formatting-core"),
        .product(name: "SwiftFormattingCoreCLI", package: "swift-formatting-core"),
        .product(name: "CommonLog", package: "common-log"),
        .product(name: "CommonCLI", package: "common-cli"),
        .product(name: "CommonShell", package: "common-shell"),
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
      path: "sources/swift-json-formatter-cli"
    ),
    .testTarget(
      name: "SwiftJSONFormatterTests",
      dependencies: ["SwiftJSONFormatter"],
      path: "tests/swift-json-formatter-tests"
    ),
  ]
)
