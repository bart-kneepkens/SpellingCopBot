//
//  RemoveRuleHandler.swift
//  miakoBot
//
//  Created by Bart Kneepkens on 05/11/2017.
//

import Foundation
import TelegramBot

/// Handles a 'remove rule' command.
///
/// - Parameter context: The context containing information on the command call
/// - Returns: `true` if the command matcher should stop, `false` if the command matcher should try other paths (From TelegramBot)
func removeRuleCommandHandler(context: Context) -> Bool {
    guard   let fromMemberId = context.fromId,
        let fromChatId = context.chatId
        else { return false }
    
    guard (context.privateChat || context.isAdminOrCreator(user: fromMemberId, in: fromChatId)) else {
        context.bot.sendMessageAsync(chat: fromChatId, text: "This command is only available to admins and creators ☹️", replyTo: context.message?.message_id)
        return false
    }
    
    let arguments = context.args.scanWords()
    guard arguments.count == 1 else {
        context.bot.sendMessageAsync(chat: fromChatId, text: "Please provide an argument. Format: [Trigger] ", replyTo: context.message?.message_id)
        return false
    }
    
    do {
        try RuleBook.shared.remove(ruleWith: arguments.first!, for: fromChatId)
    } catch RuleBookError.ruleDoesNotExist {
        context.bot.sendMessageAsync(chat: fromChatId, text: "I'm dividing by zero 💥! There is no such rule to remove.", replyTo: context.message?.message_id)
        return true
    } catch {
        return true 
    }
    
    context.bot.sendMessageAsync(chat: fromChatId, text: "Rule removed. \n`\(arguments.first!)` ---> 🗑", replyTo: context.message?.message_id, markdown: true)
    return true
}
