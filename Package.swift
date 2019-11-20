// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "SwifQLTester",
    products: [
        .library(name: "SwifQLTester", targets: ["App"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0"),
        .package(url: "https://github.com/vapor/fluent-mysql.git", from: "3.0.0"),
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "1.0.0"),
        .package(url: "https://github.com/MihaelIsaev/SwifQL.git", from:"0.20.1")
    ],
    targets: [
        .target(name: "App", dependencies: ["FluentMySQL", "FluentPostgreSQL", "SwifQL", "SwifQLVapor", "Vapor"]),
        .target(name: "Run", dependencies: ["App"]),
        .testTarget(name: "AppTests", dependencies: ["App"])
    ]
)

