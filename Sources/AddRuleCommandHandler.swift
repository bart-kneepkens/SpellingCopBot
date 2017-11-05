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
        context.bot.sendMessageAsync(fromChatId, "This command is only available to admins and creators ☹️")
        return false
    }
    
    let arguments = context.args.scanWords()
    guard arguments.count == 2 else {
        context.bot.sendMessageAsync(fromChatId, "Please provide two arguments. [Trigger] [Correction] ☹️")
        return false
    }
    
    do {
        try RuleBook.shared.add(ruleWithTrigger: arguments.first!, correction: arguments.last!, for: fromChatId)
    } catch RuleBookError.ruleAlreadyExists {
        context.bot.sendMessageAsync(fromChatId, "There is already a rule with this trigger! 🔫")
        return true
    } catch {
        return true
    }
    
    context.bot.sendMessageAsync(fromChatId, "Rule added 🎊 : \(arguments.first!) -> \(arguments.last!)")
    return true
}
