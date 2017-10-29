import Foundation
import TelegramBot

let token = readToken(from: "MIAKO_BOT_TOKEN")
let bot = TelegramBot(token: token)
let router = Router(bot: bot)

var allCorrections: [Int64:[Correction]] = [:]

fileprivate func isAdmin(userId user: Int64, chatID chat: Int64) -> Bool {
    guard let chatMember = bot.getChatMemberSync(chat_id: chat, user_id: user) else { return false }
    return chatMember.status == .administrator || chatMember.status == .creator
}

fileprivate func persistCorrection(_ correction: Correction) {

    if allCorrections.keys.contains(correction.group) {
        allCorrections[correction.group]!.append(correction)
        return
    }
    
    allCorrections[correction.group] = [correction]
}

router["add_correction"] = { context in
    guard   let fromMemberId = context.fromId,
            let fromChatId = context.chatId,
            (context.privateChat || isAdmin(userId: fromMemberId, chatID: fromChatId))
    else { return false }
    guard context.slash else { return true }

    let arguments = context.args.scanWords()
    guard arguments.count == 2 else { return true }

    let newCorrection = Correction(trigger: arguments.first!, correction: arguments.last!, group: fromChatId)

    persistCorrection(newCorrection)

    return true
}

while let update = bot.nextUpdateSync() {
    guard   let chatId = update.message?.chat.id,
            let text = update.message?.text
    else { continue }
    
    // For some reason, the router will process all text as a command.
    // So for now, only process commands that truly start with a forward slash.
    if text.starts(with: "/") {
        try router.process(update: update)
        continue
    }

    guard allCorrections.keys.contains(chatId) else { continue }
    
    guard let correctionsForChat = allCorrections[chatId] else { continue }
    guard !correctionsForChat.isEmpty else { continue }

    let processed = text.lowercased()
                        .trimmed(set: CharacterSet.illegalCharacters)
                        .trimmed(set: CharacterSet.whitespacesAndNewlines)
 
    guard let triggeredIndex = correctionsForChat.index(where: {processed.contains($0.trigger)}) else { continue }
    
    bot.sendMessageAsync(chat_id: chatId, text: "\(correctionsForChat[triggeredIndex].correction)*", parse_mode: nil, disable_web_page_preview: nil, disable_notification: true, reply_to_message_id: update.message?.message_id, reply_markup: nil, queue: DispatchQueue.main, completion: nil)
}

fatalError("Server stopped due to error: \(String(describing: bot.lastError))")
