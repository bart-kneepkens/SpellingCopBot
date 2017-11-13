//
//  MiakoBot.swift
//  miakoBot
//
//  Created by Bart Kneepkens on 05/11/2017.
//

import Foundation
import TelegramBot
import Dispatch

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
            let text = update.message?.text,
            let messageId = update.message?.message_id
        else { return }
        
        RuleBook.shared.loadRulesIfNeeded(for: chatId)
        
        guard !update.containsCommand else {
            do { try router.process(update: update) } catch { return }
            return
        }
        
        guard
            let rulesForChat = RuleBook.shared.rules(for: chatId),
            !rulesForChat.isEmpty
        else { return }
        
        // Rule matching might take a significant amount of time if the input and/or rules collection are big.
        // Therefore, dispatch it asynchronous, so the main thread is able to do something else in the meantime.
        DispatchQueue.main.async {
            text.match(with: rulesForChat, onCompletion: { matchedRules in
                let response = self.responseMessage(from: text, replacing: matchedRules)
                self.bot.sendMessageAsync(chatId,
                                          response,
                                          parse_mode: "HTML",
                                          disable_notification: true,
                                          reply_to_message_id: messageId)
            })
        }
    }
    
    
    /// Generates a response message from an original message and rules that were triggered in it.
    ///
    /// - Parameters:
    ///   - text: The original message that was sent by a chat member
    ///   - rules: The rules that were triggered by the original message
    /// - Returns: A formatted message where the triggering parts of the message are replaced by the respective correction
    fileprivate func responseMessage(from text: String, replacing rules: [(trigger: Trigger, correction: Correction)]) -> String {
        var response = text, intermediateString = text
        
        rules.forEach { rule in
            guard let range = intermediateString.lowercased()
                .range(of: rule.trigger.lowercased()) ?? intermediateString.range(of: rule.trigger) else { return }
            
            let insertedCorrection = (rule.correction.isUsernameTag || rule.correction.isUrl) ? rule.correction
                : "<code>\(rule.correction)</code>*"
            response.replaceSubrange(range, with: insertedCorrection)
            let whiteSpaceReplacement = String(repeatElement(" ", count: insertedCorrection.utf16.count))
            intermediateString.replaceSubrange(range, with: whiteSpaceReplacement)
        }
        return response
    }
}
