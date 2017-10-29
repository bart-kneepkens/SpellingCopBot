// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "miakoBot",
    dependencies: [
        .Package(url: "https://github.com/zmeyc/telegram-bot-swift.git", from: "0.16.1")
    ]
)
