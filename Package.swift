// swift-tools-version:3.1

import PackageDescription

let package = Package(
    name: "miakoBot",
    dependencies: [
        .Package(url: "https://github.com/zmeyc/telegram-bot-swift.git", from: "0.18.0")
    ]
)
