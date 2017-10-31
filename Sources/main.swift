import Foundation
import TelegramBot
import SwiftyJSON
import Dispatch

typealias Trigger = String
typealias Correction = String
typealias Chat = Int64

let token = readToken(from: "MIAKO_BOT_TOKEN")
let bot = TelegramBot(token: token)
let router = Router(bot: bot)

var allCorrections: [Chat: [Trigger: Correction]] = [:]

fileprivate func loadFromFile(for chat: Chat) {
    let fp = fopen("/var/lib/dsb/\(chat)", "r"); defer {fclose(fp)}
    guard fp != nil else { return }
    var outputString = ""
    let chunkSize = 1024
    let buffer: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer.allocate(capacity: chunkSize); defer {buffer.deallocate(capacity: chunkSize)}
    repeat {
        let count: Int = fread(buffer, 1, chunkSize, fp)
        guard ferror(fp) == 0 else {break}
        if count > 0 {
            outputString += String((0..<count).map ({Character(UnicodeScalar(buffer[$0]))}))
        }
    } while feof(fp) == 0
    
    guard !outputString.isEmpty else { return }
    
    let j = JSON.parse(string: outputString)
    
    allCorrections[chat] = j.dictionaryObject as? [Trigger: Correction]
}

fileprivate func saveToFile(for chat: Chat) {
    guard let correctionsForChat = allCorrections[chat] else { return }
    let j = JSON(correctionsForChat)
    
    guard let jsonString = j.rawString() else { return }
    
    mkdir("var/lib/dsb", 777)
    
    let fp = fopen("/var/lib/dsb/\(chat)", "w")
    var byteArray : [UInt8] = Array(jsonString.utf8)
    let _ = fwrite(&byteArray, 1, byteArray.count, fp)
    fclose(fp)
}

fileprivate func isAdmin(userId user: Int64, chatID chat: Chat) -> Bool {
    guard let chatMember = bot.getChatMemberSync(chat_id: chat, user_id: user) else { return false }
    return chatMember.status == .administrator || chatMember.status == .creator
}

fileprivate func persist(trigger: Trigger, withCorrection correction: Correction, forChat chat: Chat) -> Bool {
    if allCorrections[chat] != nil {
        guard !allCorrections[chat]!.keys.contains(trigger) else {
            bot.sendMessageAsync(chat, "There is already a rule with this trigger! 🔫")
            return false
        }
        allCorrections[chat]![trigger] = correction
    } else {
        allCorrections[chat] = [trigger:correction]
    }
    
    DispatchQueue.main.async {
        saveToFile(for: chat)
    }
    
    return true
}

fileprivate func forget(_ trigger: Trigger, forChat chat: Chat) -> Bool {
    guard let correctionsForChat = allCorrections[chat] else { return false }
    guard !correctionsForChat.isEmpty else { return false }
    
    if correctionsForChat.keys.contains(trigger) {
        allCorrections[chat]!.removeValue(forKey: trigger)
        
        DispatchQueue.main.async {
            saveToFile(for: chat)
        }
        return true
    }
    bot.sendMessageAsync(chat, "I'm dividing by zero! 💥 \nThere is no such rule to remove!")
    return false
}

router["add_rule"] = { context in
    guard   let fromMemberId = context.fromId,
            let fromChatId = context.chatId
    else { return false }
    
    guard (context.privateChat || isAdmin(userId: fromMemberId, chatID: fromChatId)) else {
        bot.sendMessageAsync(fromChatId, "This command is only available to admins and creators ☹️")
        return false
    }
    
    let arguments = context.args.scanWords()
    guard arguments.count == 2 else {
        bot.sendMessageAsync(fromChatId, "Please provide two arguments. [Trigger] [Correction] ☹️")
        return true
    }
    
    if persist(trigger: arguments.first!, withCorrection: arguments.last!, forChat: fromChatId) {
        bot.sendMessageAsync(fromChatId, "Rule added 🎊 : \(arguments.first!)")
        return true
    }
    
    return false
}

router["remove_rule"] = { context in
    guard   let fromMemberId = context.fromId,
            let fromChatId = context.chatId
    else { return false }
    
    guard (context.privateChat || isAdmin(userId: fromMemberId, chatID: fromChatId)) else {
        bot.sendMessageAsync(fromChatId, "This command is only available to admins and creators ☹️")
        return false
    }
    
    let arguments = context.args.scanWords()
    guard arguments.count == 1 else {
        bot.sendMessageAsync(fromChatId, "Please provide an argument. [Trigger] ☹️")
        return true
    }
    
    if forget(arguments.first!, forChat: fromChatId){
        bot.sendMessageAsync(fromChatId, "Rule removed! 🎊 : \(arguments.first!)")
        return true
    }
    
    return false
}

router["list"] = { context in
    guard let chat = context.chatId else { return false }
    
    let correctionsForChat = allCorrections[chat]
    
    if correctionsForChat != nil {
        
        var message: String = " 📏 *Rules for this chat:* 📏 "
        
        correctionsForChat!.forEach({ (trigger,correction) in
            message.append("\n")
            message.append("*\(trigger)* : \(correction)")
        })
        
        bot.sendMessageAsync(chat, message, parse_mode: "Markdown", disable_web_page_preview: false, disable_notification: true, reply_to_message_id: nil, reply_markup: nil, queue: DispatchQueue.main, completion: nil)
        
        return true
    }
    
    bot.sendMessageAsync(chat, "There are no rules set up for this chat.")
    
    return true
}

router["yell"] = { context in
    guard   let fromMemberId = context.fromId,
        let fromChatId = context.chatId
        else { return true }
    
    guard let godIdString = ProcessInfo.processInfo.environment["godId"],
               let chatIdString = ProcessInfo.processInfo.environment["chatId"]
        else { return true }
    
    let godId = Int64(godIdString)
    let chatId = Int64(chatIdString)
    
    guard fromMemberId == godId, fromChatId == godId else { return false }
    
    let text = context.args.scanRestOfString()
    
    bot.sendMessageAsync(chatId!, text)
    
    return true
}

while let update = bot.nextUpdateSync() {
    guard   let chatId = update.message?.chat.id,
        let text = update.message?.text
        else { continue }
    
    if !allCorrections.keys.contains(chatId) {
        loadFromFile(for: chatId)
    }
    
    // For some reason, the router will process all text as a command.
    // So for now, only process commands that truly start with a forward slash.
    if text.starts(with: "/") {
        try router.process(update: update)
        continue
    }

    guard let correctionsForChat = allCorrections[chatId] else { continue }
    guard !correctionsForChat.isEmpty else { continue }

    let processed = text.lowercased()
        .trimmed(set: CharacterSet.illegalCharacters)
        .trimmed(set: CharacterSet.whitespacesAndNewlines)

    guard let triggeredIndex = correctionsForChat.index(where: {processed.contains($0.0)}) else { continue }

    bot.sendMessageAsync(chat_id: chatId, text: "\(correctionsForChat[triggeredIndex].1)*", parse_mode: nil, disable_web_page_preview: nil, disable_notification: true, reply_to_message_id: update.message?.message_id, reply_markup: nil, queue: DispatchQueue.main, completion: nil)
}

fatalError("Server stopped due to error: \(String(describing: bot.lastError))")
