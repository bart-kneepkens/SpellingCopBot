//
//  ListCommandHandler.swift
//  miakoBot
//
//  Created by Bart Kneepkens on 05/11/2017.
//

import Foundation
import TelegramBot
import Dispatch

/// Handles a `list rules` command.
///
/// - Parameter context: The context containing information on the command call
/// - Returns: `true` if the command matcher should stop, `false` if the command matcher should try other paths (From TelegramBot)
func listCommandHandler(context: Context) -> Bool {
    guard let chat = context.chatId else { return false }
    
    guard
        let rulesForChat = RuleBook.shared.rules(for: chat),
        !rulesForChat.isEmpty
    else {
        context.bot.sendMessageAsync(chat: chat, text: "There are no rules set up for this chat.",
                                     replyTo: context.message?.message_id)
        return false
    }
    
    var message: String = " 📏 <b>Rules for this chat:</b> 📏 "
    rulesForChat.sorted(by: {(lhs, rhs) in return lhs.key.lowercased() < rhs.key.lowercased() })
        .forEach({ (trigger, correction) in
            message.append("\n <b>\(trigger)</b> : \(correction)")
        })
    
    context.bot.sendMessageAsync(chat_id: chat, text: message, parse_mode: "HTML", disable_notification: true, reply_to_message_id: context.message?.message_id)
    return true
}
