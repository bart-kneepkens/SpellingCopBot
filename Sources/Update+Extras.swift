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
        guard text.starts(with: "/") else { return false }
        let messageComponents = text
            .trimmed(set: CharacterSet.alphanumerics.inverted)
            .components(separatedBy: .whitespaces)
        guard var firstComponent = messageComponents.first else { return false }
        if let atSignIndex = firstComponent.index(of: "@") {
            firstComponent = firstComponent.substring(to: atSignIndex)
        }
        return CommandName.all.map({$0.rawValue}).contains(firstComponent)
    }
}
