// swift-tools-version:3.1

import PackageDescription

let package = Package(
    name: "miakoBot",
    targets: [
        Target(name: "miakoBot"),
        Target(name: "miakoBotTests")
    ],
    dependencies: [
        .Package(url: "https://github.com/zmeyc/telegram-bot-swift.git", majorVersion: 0),
        .Package(url: "https://github.com/vadymmarkov/Rexy.git", versions: Version(0,1,0)..<Version(1,0,0))
    ]
)
