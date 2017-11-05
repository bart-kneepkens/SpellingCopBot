//
//  BroadCastCommandHandler.swift
//  miakoBot
//
//  Created by Bart Kneepkens on 05/11/2017.
//

import Foundation
import TelegramBot

/// Handles a 'broadcast message' command.
///
/// - Parameter context: The context containing information on the command call
/// - Returns: `true` if the command matcher should stop, `false` if the command matcher should try other paths (From TelegramBot)
func broadcastCommandHandler(context: Context) -> Bool {
    guard
        let fromMemberId = context.fromId,
        let fromChatId = context.chatId
    else { return false }
    
    guard
        let godIdString = ProcessInfo.processInfo.environment["godId"],
        let chatIdString = ProcessInfo.processInfo.environment["chatId"]
    else { return false }
    
    guard
        let godId = Int64(godIdString),
        let chatId = Int64(chatIdString)
    else { return false }
    
    guard
        fromMemberId == godId,
        fromChatId == godId
    else { return false }
    
    let text = context.args.scanRestOfString()
    context.bot.sendMessageAsync(chatId, text)
    return true
}
