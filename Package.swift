// swift-tools-version:4.2

// -----------------------------------------------------------------------------
//    Copyright (C) 2019 Yauheni Lychkouski.
//
//    This program is free software: you can redistribute it and/or modify
//    it under the terms of the GNU General Public License as published by
//    the Free Software Foundation, either version 3 of the License, or
//    (at your option) any later version.
//
//    This program is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//    GNU General Public License for more details.
//
//    You should have received a copy of the GNU General Public License
//    along with this program.  If not, see <http://www.gnu.org/licenses/>.
// -----------------------------------------------------------------------------

import PackageDescription

let package = Package(
    name: "LifeServer",
    products: [
        .library(name: "LifeServerCore", targets: ["LifeServerCore"]),
        .executable(name: "LifeServer", targets: ["LifeServer"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "1.0.0"),
        .package(url: "https://github.com/ReactiveX/RxSwift.git", "4.0.0" ..< "5.0.0"),
        .package(url: "https://github.com/IBM-Swift/Swift-Kuery-SQLite.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "LifeServerCore",
            dependencies: ["NIO",
                           "NIOFoundationCompat",
                           "RxSwift",
                           "RxCocoa",
                           "SwiftKuerySQLite",
                           ]),
        .testTarget(
            name: "LifeServerTests",
            dependencies: ["LifeServerCore"]),
        .target(
            name: "LifeServer",
            dependencies: ["LifeServerCore"]),
    ]
)
