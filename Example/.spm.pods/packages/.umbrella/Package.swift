// swift-tools-version:5.7
import PackageDescription

let package = Package(
  name: "_umbrella_",
  dependencies: [
    .package(url: "git@github.com:pagopa/cie-sdk-ios.git", branch: "feature/refactoring")
  ]
)
