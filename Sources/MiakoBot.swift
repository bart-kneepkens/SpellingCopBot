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
        
        guard !text.hasPrefix("/") else {
            do { try router.process(update: update) } catch { return }
            return
        }
        
        guard
            let rulesForChat = RuleBook.shared.rules(for: chatId),
            !rulesForChat.isEmpty
        else { return }
        
        DispatchQueue.main.async {
            text.match(with: rulesForChat, onCompletion: { matchedRules in
                let response = self.responseMessage(from: text, replacing: matchedRules)
                self.bot.sendMessageAsync(chatId, response, parse_mode: "Markdown", disable_notification: true, reply_to_message_id: messageId)
            })
        }
    }
    
    fileprivate func responseMessage(from text: String, replacing rules: [(Range<String.Index> , (Trigger, Correction))]) -> String {
        var response = text
//        rules.forEach { rule in
//            guard let range = response.range(of: rule.key) ?? response.lowercased().range(of: rule.key.lowercased())
//            else { return }
//            response.replaceSubrange(range, with: "`\(rule.value)` \\*")
//        }
        var excludedRanges: [Range<String.Index>] = []
        
        rules.forEach { tuple in
            var interm = response
            
            excludedRanges.forEach({ range in
                var replaceString = String()
//                for _ in 0..<  {
//                    replaceString = replaceString + " "
//                }
//                interm.replaceSubrange(range, with: replaceString)
                
                let count = response.substring(with: range).characters.count
                
                for _ in 1 ... count {
                    replaceString = replaceString + " "
                }
                interm.replaceSubrange(range, with: replaceString)
                
            })
            
            if let range = interm.lowercased().range(of: tuple.1.0.lowercased()) {
                response.replaceSubrange(range, with: "`\(tuple.1.1)` \\*")
                excludedRanges.append(tuple.0)
            }
            
            
//            response.replaceSubrange(tuple.0, with: "`\(tuple.1.1)` \\*")
        }
        return response
    }
}
