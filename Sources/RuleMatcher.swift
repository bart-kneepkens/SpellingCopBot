//
//  RuleMatcher.swift
//  miakoBot
//
//  Created by Bart Kneepkens on 06/11/2017.
//

import Foundation

extension String{
    
    /// Matches itself with a set of rules and executes a closure on completion.
    ///
    /// - Parameters:
    ///   - rules: The rules that should be matched
    ///   - onCompletion: The code block that should be executed if at least one match is found. The parameter contains a collection of rules that were triggered, sorted by trigger length.
    func match(with rules: [Trigger: Correction], onCompletion: ([(Trigger, Correction)]) -> Void) {
        let words = self
            .components(separatedBy: .whitespacesAndNewlines)
            .map { component -> String in
                return component
                    .lowercased()
                    .trimmed(set: CharacterSet.illegalCharacters)
                    .trimmed(set: CharacterSet.whitespacesAndNewlines)
                    .trimmed(set: CharacterSet.punctuationCharacters)
        }
    
        let triggeredRules = rules.filter { rule -> Bool in
            return words.contains(where: { text -> Bool in
                text.lowercased().contains(rule.key.lowercased())
            })
        }.sorted(by: { $0.0.key.count > $0.1.key.count })
        
        guard !triggeredRules.isEmpty else { return }

        onCompletion(triggeredRules)
    }
}
