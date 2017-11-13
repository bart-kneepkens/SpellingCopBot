//
//  Update+Extras.swift
//  miakoBot
//
//  Created by Bart Kneepkens on 12/11/2017.
//

import Foundation
import TelegramBot

extension Update {
    var containsCommand: Bool {
        guard let text = self.message?.text else { return false }
        guard text.hasPrefix("/") else { return false }
        let messageComponents = text
            .trimmed(set: CharacterSet.alphanumerics.inverted)
            .components(separatedBy: .whitespaces)
        guard let firstComponent = messageComponents.first else { return false }
        return CommandName.all.map({$0.rawValue}).contains(where: { firstComponent.contains($0) })
    }
}
