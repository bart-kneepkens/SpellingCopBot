import Foundation
import TelegramBot

let token = readToken(from: "HELLO_BOT_TOKEN")
let bot = TelegramBot(token: token)

while let update = bot.nextUpdateSync() {
    print("Received something")
    if let message = update.message, let from = message.from, let text = message.text {
        print(message.chat)
        print(text)
        
        if text.lowercased().replacingOccurrences(of:" ", with:"").contains("maiko") {
            bot.sendMessageAsync(chat_id: message.chat.id,
                                 text: "Miako*")
        }
    }
}

fatalError("Server stopped due to error: \(String(describing: bot.lastError))")
