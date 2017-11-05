//
//  Context+Extras.swift
//  miakoBot
//
//  Created by Bart Kneepkens on 05/11/2017.
//

import Foundation
import TelegramBot

extension Context {
    func isAdmin(userId user: Int64, in chat: Chat) -> Bool {
        guard let chatMember = self.bot.getChatMemberSync(chat_id: chat, user_id: user) else { return false }
        return chatMember.status == .administrator || chatMember.status == .creator
    }
}
