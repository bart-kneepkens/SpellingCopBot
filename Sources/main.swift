import Foundation
import TelegramBot
import SwiftyJSON
import Dispatch

typealias Trigger = String
typealias Correction = String
typealias Chat = Int64

fileprivate let token = readToken(from: "MIAKO_BOT_TOKEN")
fileprivate let bot = TelegramBot(token: token)
fileprivate let router = Router(bot: bot)
let ruleBook = RuleBook()

router["add_rule"] = addRuleCommandHandler

router["remove_rule"] = removeRuleCommandHandler

router["list"] = listCommandHandler

router["yell"] = broadcastCommandHandler

// Dirty, dirty hack. telegram-bot-swift has an issue which makes the app un-responding after a while of inactivity.
// This way, it will stay alive.
let timer = DispatchSource.makeTimerSource()
fileprivate func keepMeAlive() {
    timer.scheduleRepeating(deadline: .now(), interval: .seconds(10))
    timer.setEventHandler(handler: {})
    timer.resume()
}

keepMeAlive()

while var update = bot.nextUpdateSync() {
    guard   let chatId = update.message?.chat.id,
        let text = update.message?.text
        else { continue }
    
    ruleBook.loadRulesIfNeeded(for: chatId)
    
    // For some reason, the router will process all text as a command.
    // So for now, only process commands that truly start with a forward slash.
    guard !text.hasPrefix("/") else {
        if text.contains("@MiakoBot") {
            update.message?.text = text.replacingOccurrences(of: "@MiakoBot", with: "")
        }
        try router.process(update: update)
        continue
    }

    guard let correctionsForChat = ruleBook.rules(for: chatId) else { continue }
    guard !correctionsForChat.isEmpty else { continue }

    let processed = text.lowercased()
        .trimmed(set: CharacterSet.illegalCharacters)
        .trimmed(set: CharacterSet.whitespacesAndNewlines)

    guard let triggeredIndex = correctionsForChat.index(where: {processed.contains($0.0.lowercased())}) else { continue }

    bot.sendMessageAsync(chat_id: chatId, text: "\(correctionsForChat[triggeredIndex].1)*", parse_mode: nil, disable_web_page_preview: nil, disable_notification: true, reply_to_message_id: update.message?.message_id, reply_markup: nil, queue: DispatchQueue.main, completion: nil)
}

fatalError("Server stopped due to error: \(String(describing: bot.lastError))")
