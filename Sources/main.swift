import Foundation
import TelegramBot

typealias Trigger = String
typealias Correction = String
typealias Chat = Int64

let token = readToken(from: "MIAKO_BOT_TOKEN")
let bot = TelegramBot(token: token)
let router = Router(bot: bot)

var allCorrections: [Chat: [Trigger: Correction]] = [:]

fileprivate func isAdmin(userId user: Int64, chatID chat: Chat) -> Bool {
    guard let chatMember = bot.getChatMemberSync(chat_id: chat, user_id: user) else { return false }
    return chatMember.status == .administrator || chatMember.status == .creator
}

fileprivate func persist(trigger: Trigger, withCorrection correction: Correction, forChat chat: Chat) {
    if allCorrections[chat] != nil {
        allCorrections[chat]![trigger] = correction
        return
    }
    
    allCorrections[chat] = [trigger:correction]
}

fileprivate func forget(_ trigger: Trigger, forChat chat: Chat ) {
    guard let correctionsForChat = allCorrections[chat] else { return }
    guard !correctionsForChat.isEmpty else { return }
    
    if correctionsForChat.keys.contains(trigger) {
        allCorrections[chat]!.removeValue(forKey: trigger)
    }
}

router["add_correction"] = { context in
    guard   let fromMemberId = context.fromId,
            let fromChatId = context.chatId,
            (context.privateChat || isAdmin(userId: fromMemberId, chatID: fromChatId))
    else { return false }
    guard context.slash else { return true }
    
    let arguments = context.args.scanWords()
    guard arguments.count == 2 else { return true }
    
    persist(trigger: arguments.first!, withCorrection: arguments.last!, forChat: fromChatId)
    
    return true
}

router["remove_correction"] = { context in
    guard   let fromMemberId = context.fromId,
            let fromChatId = context.chatId,
            (context.privateChat || isAdmin(userId: fromMemberId, chatID: fromChatId))
    else { return false }
    
    guard context.slash else { return true }
    
    let arguments = context.args.scanWords()
    guard arguments.count == 1 else { return true }
    
    forget(arguments.first!, forChat: fromChatId)
    
    return true
}

router["list"] = { context in
    guard let chat = context.chatId else { return false }
    
    guard context.slash else { return true }
    
    let correctionsForChat = allCorrections[chat]
    
    if correctionsForChat != nil {
        
        var message: String = "Trigger : Correction \n ---------------"
        
        correctionsForChat!.forEach({ (trigger,correction) in
            message.append("\n")
            message.append("\(trigger) : \(correction)")
        })
        
        bot.sendMessageAsync(chat, message)
        
        return true
    }
    
    bot.sendMessageAsync(chat, "There are no rules set up for this chat.")
    
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
    
    guard let triggeredIndex = correctionsForChat.index(where: {processed.contains($0.0)}) else { continue }
    
    bot.sendMessageAsync(chat_id: chatId, text: "\(correctionsForChat[triggeredIndex].1)*", parse_mode: nil, disable_web_page_preview: nil, disable_notification: true, reply_to_message_id: update.message?.message_id, reply_markup: nil, queue: DispatchQueue.main, completion: nil)
}

fatalError("Server stopped due to error: \(String(describing: bot.lastError))")
