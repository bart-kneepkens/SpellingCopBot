//
//  MiakoBot.swift
//  miakoBot
//
//  Created by Bart Kneepkens on 05/11/2017.
//

import Foundation
import TelegramBot

/// `MiakoBot` is the main class that encloses the functionality for this bot, which is to provide chat members with specified
/// corrections when they send a message containing a specified trigger.
class MiakoBot {
    fileprivate let token: String
    fileprivate let bot: TelegramBot
    fileprivate let router: Router
    
    init() {
        token = readToken(from: "MIAKO_BOT_TOKEN")
        bot = TelegramBot(token: token)
        router = Router(bot: bot, setup: { router in
            router[CommandName.addRule.rawValue, .slashRequired] = addRuleCommandHandler
            router[CommandName.removeRule.rawValue, .slashRequired] = removeRuleCommandHandler
            router[CommandName.listRules.rawValue, .slashRequired] = listCommandHandler
            router[CommandName.broadcastMessage.rawValue, .slashRequired] = broadcastCommandHandler
            router.unmatched = nil  // Removes the default 'unsupported command' message if some text is unmatched.
        })
    }
    
    /// Starts polling the chats containing MiakoBot for updates indefinitely, or until an error is reported.
    func start() {
        while let update = bot.nextUpdateSync() {
            self.onUpdate(update)
        }
        fatalError("Server stopped due to error: \(String(describing: bot.lastError))")
    }
}

// MARK: - Private helpers
extension MiakoBot {
    
    /// Handles every update for every chat that MiakoBot has been added to.
    ///
    /// - Parameter update: The object containing all the update information. (From `TelegramBot`)
    fileprivate func onUpdate(_ update: Update) {
        guard
            let chatId = update.message?.chat.id,
            let text = update.message?.text
            else { return }
        
        RuleBook.shared.loadRulesIfNeeded(for: chatId)
        
        guard !text.hasPrefix("/") else {
            do { try router.process(update: update) } catch { return }
            return
        }
        
        guard
            let rulesForChat = RuleBook.shared.rules(for: chatId),
            !rulesForChat.isEmpty
            else { return }
        
        let processed = text.lowercased()
            .trimmed(set: CharacterSet.illegalCharacters)
            .trimmed(set: CharacterSet.whitespacesAndNewlines)
        
        guard
            let triggeredIndex = rulesForChat.index(where: {processed.contains($0.0.lowercased())})
            else { return }
        
        bot.sendMessageAsync(chat_id: chatId,
                             text: "\(rulesForChat[triggeredIndex].1)*",
                             parse_mode: nil, disable_web_page_preview: nil,
                             disable_notification: true,
                             reply_to_message_id: update.message?.message_id,
                             reply_markup: nil,
                             queue: DispatchQueue.main,
                             completion: nil)
    }
}
