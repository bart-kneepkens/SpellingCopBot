//
//  MiakoBot.swift
//  miakoBot
//
//  Created by Bart Kneepkens on 05/11/2017.
//

import Foundation
import TelegramBot

class MiakoBot {
    fileprivate let token: String
    fileprivate let bot: TelegramBot
    fileprivate let router: Router
    
    init() {
        token = readToken(from: "MIAKO_BOT_TOKEN")
        bot = TelegramBot(token: token)
        router = Router(bot: bot, setup: { router in
            router["addrule"] = addRuleCommandHandler
            router["remove_rule"] = removeRuleCommandHandler
            router["list"] = listCommandHandler
            router["yell"] = broadcastCommandHandler
        })
        while let update = bot.nextUpdateSync() {
            self.onUpdate(update)
        }
    }
    
    private func onUpdate(_ update: Update) {
        guard   let chatId = update.message?.chat.id,
                let text = update.message?.text
                else { return }
        
        RuleBook.shared.loadRulesIfNeeded(for: chatId)
        
        // For some reason, the router will process all text as a command, resulting in an automated message
        // explaining that the command couldn't be found.
        // So for now, only process commands that truly start with a forward slash.
        guard !text.hasPrefix("/") else {
            do { try router.process(update: update) }
            catch { return }
            return
        }
        
        guard let rulesForChat = RuleBook.shared.rules(for: chatId),
            !rulesForChat.isEmpty
            else { return }
        
        let processed = text.lowercased()
            .trimmed(set: CharacterSet.illegalCharacters)
            .trimmed(set: CharacterSet.whitespacesAndNewlines)
        
        guard let triggeredIndex = rulesForChat.index(where: {processed.contains($0.0.lowercased())}) else { return }
        
        bot.sendMessageAsync(chat_id: chatId, text: "\(rulesForChat[triggeredIndex].1)*", parse_mode: nil, disable_web_page_preview: nil, disable_notification: true, reply_to_message_id: update.message?.message_id, reply_markup: nil, queue: DispatchQueue.main, completion: nil)
    }
    
}
