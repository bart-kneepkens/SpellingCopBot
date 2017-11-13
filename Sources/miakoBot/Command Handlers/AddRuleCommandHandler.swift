//
//  AddRuleHandler.swift
//  miakoBot
//
//  Created by Bart Kneepkens on 05/11/2017.
//

import Foundation
import TelegramBot

/// Handles a 'add rule' command.
///
/// - Parameter context: The context containing information on the command call
/// - Returns: `true` if the command matcher should stop, `false` if the command matcher should try other paths (From TelegramBot)
func addRuleCommandHandler(context: Context) -> Bool {
    guard   let fromMemberId = context.fromId,
        let fromChatId = context.chatId
        else { return false }
    
    guard (context.privateChat || context.isAdminOrCreator(user: fromMemberId, in: fromChatId)) else {
        context.bot.sendMessageAsync(chat: fromChatId, text: "This command is only available to admins and creators ☹️.", replyTo: context.message?.message_id)
        return false
    }
    
    let arguments = context.args.scanWords()
    guard arguments.count == 2 else {
        context.bot.sendMessageAsync(chat: fromChatId, text: "Please provide two arguments. Format: [Trigger] [Correction]", replyTo: context.message?.message_id)
        return false
    }
    
    do {
        try RuleBook.shared.add(ruleWithTrigger: arguments.first!, correction: arguments.last!, for: fromChatId)
    } catch RuleBookError.ruleAlreadyExists {
        context.bot.sendMessageAsync(chat: fromChatId, text: "Can't add this rule 😕. There is already a rule with this trigger!", replyTo: context.message?.message_id)
        return true
    } catch {
        return true
    }
    
    context.bot.sendMessageAsync(chat: fromChatId, text: "🎉 Rule added 🎉 \n        `\(arguments.first!)` ---> `\(arguments.last!)`", replyTo: context.message?.message_id, markdown: true)
    return true
}
