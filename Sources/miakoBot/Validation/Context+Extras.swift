//
//  Context+Extras.swift
//  miakoBot
//
//  Created by Bart Kneepkens on 05/11/2017.
//

import Foundation
import TelegramBot

extension Context {
    /// Determines if a user is either an admin or creator in a chat.
    ///
    /// - Parameters:
    ///   - user: The user identifier
    ///   - chat: The chat identifier
    /// - Returns: `true` if the user is an admin or creator in the specified chat,
    ///            `false` if the user is not an admin or creator in the specified chat
    func isAdminOrCreator(user: Int64, in chat: Chat) -> Bool {
        guard let chatMember = self.bot.getChatMemberSync(chat_id: chat, user_id: user) else { return false }
        return chatMember.status == .administrator || chatMember.status == .creator
    }
}
