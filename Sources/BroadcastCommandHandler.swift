//
//  BroadCastCommandHandler.swift
//  miakoBot
//
//  Created by Bart Kneepkens on 05/11/2017.
//

import Foundation
import TelegramBot

func broadcastCommandHandler(context: Context) -> Bool {
    guard   let fromMemberId = context.fromId,
        let fromChatId = context.chatId
        else { return true }
    
    guard let godIdString = ProcessInfo.processInfo.environment["godId"],
        let chatIdString = ProcessInfo.processInfo.environment["chatId"]
        else { return true }
    
    let godId = Int64(godIdString)
    let chatId = Int64(chatIdString)
    
    guard fromMemberId == godId, fromChatId == godId else { return false }
    
    let text = context.args.scanRestOfString()
    
    context.bot.sendMessageAsync(chatId!, text)
    
    return true
}
