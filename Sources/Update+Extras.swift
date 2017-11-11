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
        let messageComponents = self.message?.text?
            .trimmed(set: CharacterSet.alphanumerics.inverted)
            .components(separatedBy: .whitespaces)
        guard let firstComponent = messageComponents?.first else { return false }
        return CommandName.all.map({$0.rawValue}).contains(firstComponent)
    }
}
