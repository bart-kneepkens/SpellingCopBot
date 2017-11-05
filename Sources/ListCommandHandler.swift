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
    
    var message: String = " 📏 *Rules for this chat:* 📏 "
    rulesForChat.forEach({ (trigger, correction) in
        message.append("\n*\(trigger)* : \(correction)")
    })
    
    context.bot.sendMessageAsync(chat: chat, text: message, replyTo: context.message?.message_id, markdown: true)
    return true
}
