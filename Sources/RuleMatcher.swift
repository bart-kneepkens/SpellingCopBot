//
//  RuleMatcher.swift
//  miakoBot
//
//  Created by Bart Kneepkens on 06/11/2017.
//

import Foundation

extension String{
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
    
        let triggeredRulesArray = rules.filter { rule -> Bool in
            return words.contains(where: { text -> Bool in
                text.lowercased().contains(rule.key.lowercased())
            })
        }.sorted(by: { $0.0.key.count > $0.1.key.count })
        
        guard !triggeredRulesArray.isEmpty else { return }

        onCompletion(triggeredRulesArray)
    }
}
