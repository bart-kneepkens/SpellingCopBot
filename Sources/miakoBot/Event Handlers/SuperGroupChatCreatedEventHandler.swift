//
//  SuperGroupChatCreatedEventHandler.swift
//  miakoBot
//
//  Created by Bart Kneepkens on 13/11/2017.
//

import Foundation
import TelegramBot

func upgradeToSuperGroupIfNeeded(update: Update) {
    guard let oldId = update.message?.chat.id, let newId = update.message?.migrate_to_chat_id else { return }
    RuleBook.shared.migrate(chat: oldId, to: newId)
}
