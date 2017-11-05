//
//  ListCommandHandler.swift
//  miakoBot
//
//  Created by Bart Kneepkens on 05/11/2017.
//

import Foundation
import TelegramBot

func listCommandHandler(context: Context) -> Bool {
    guard let chat = context.chatId else { return false }
    
    let correctionsForChat = RuleBook.shared.rules(for: chat)
    
    if correctionsForChat != nil, !correctionsForChat!.isEmpty {
        
        var message: String = " 📏 *Rules for this chat:* 📏 "
        
        correctionsForChat!.forEach({ (trigger,correction) in
            message.append("\n")
            message.append("*\(trigger)* : \(correction)")
        })
        
        context.bot.sendMessageAsync(chat, message, parse_mode: "Markdown", disable_web_page_preview: false, disable_notification: true, reply_to_message_id: nil, reply_markup: nil, queue: DispatchQueue.main, completion: nil)
        
        return true
    }
    
    context.bot.sendMessageAsync(chat, "There are no rules set up for this chat.")
    
    return true
}
