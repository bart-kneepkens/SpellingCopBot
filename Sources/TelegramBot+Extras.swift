//
//  TelegramBot+Extras.swift
//  miakoBot
//
//  Created by Bart Kneepkens on 05/11/2017.
//

import Foundation
import TelegramBot
import Dispatch

extension TelegramBot {
    
    /// Sends a message without notification, with Markdown parsemode, on the main dispatchQueue.
    ///
    /// - Parameters:
    ///   - chat: The chat identifier to which the message should be sent
    ///   - text: The text that should be in the body of the message
    ///   - replyTo: The message identifier to which the message should reply
    func sendMessageAsync(chat: ChatId, text: String, replyTo: Int?, markdown: Bool = false) {
        self.sendMessageAsync(chat,
                              text,
                              parse_mode: markdown ? "Markdown" : nil,
                              disable_web_page_preview: nil,
                              disable_notification: true,
                              reply_to_message_id: replyTo,
                              reply_markup:nil,
                              queue: DispatchQueue.main,
                              completion: nil)
    }
}
