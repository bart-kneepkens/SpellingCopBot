//
//  RuleMatcher.swift
//  miakoBot
//
//  Created by Bart Kneepkens on 06/11/2017.
//

import Foundation

extension String{
    func match(with rules: [Trigger: Correction], onCompletion: ([Trigger: Correction]) -> Void) {
        let words = self
            .components(separatedBy: " ")
            .map { component -> String in
                return component
                    .lowercased()
                    .trimmed(set: CharacterSet.illegalCharacters)
                    .trimmed(set: CharacterSet.whitespacesAndNewlines)
        }
    
        let triggeredRulesArray = rules.filter { rule -> Bool in
            return words.contains(where: { text -> Bool in
                text.lowercased().contains(rule.key.lowercased())
            })
        }
        
        // Wishing Swift 4 would be able to build Foundation on linux, so a dictionary.filter could actually return a dictionary.
        var triggeredRules: [Trigger: Correction] = [:]
        triggeredRulesArray.forEach { ruleTuple in
            triggeredRules[ruleTuple.key] = ruleTuple.value
        }
        
        guard !triggeredRules.isEmpty else { return }

        onCompletion(triggeredRules)
    }
}
