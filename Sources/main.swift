import Foundation
import TelegramBot

let token = readToken(from: "HELLO_BOT_TOKEN")
let bot = TelegramBot(token: token)

while let update = bot.nextUpdateSync() {
    if let message = update.message, let text = message.text {
        if text.lowercased().replacingOccurrences(of:" ", with:"").contains("maiko") {
            bot.sendMessageAsync(chat_id: message.chat.id, text: "Miako*")
        }
    }
}

fatalError("Server stopped due to error: \(String(describing: bot.lastError))")
