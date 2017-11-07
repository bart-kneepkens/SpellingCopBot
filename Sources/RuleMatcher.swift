//
//  RuleMatcher.swift
//  miakoBot
//
//  Created by Bart Kneepkens on 06/11/2017.
//

import Foundation

extension String{
    func match(with rules: [Trigger: Correction], onCompletion: ([(Range<String.Index> , (Trigger, Correction))]) -> Void) {
        let words = self
            .components(separatedBy: .punctuationCharacters).joined().components(separatedBy: .whitespacesAndNewlines)
            .map { component -> String in
                return component
                    .lowercased()
                    .trimmed(set: CharacterSet.illegalCharacters)
                    .trimmed(set: CharacterSet.whitespacesAndNewlines)
        }.sorted(by: { $0.0.characters.count > $0.1.characters.count })
    
        let triggeredRulesArray = rules.filter { rule -> Bool in
            return words.contains(where: { text -> Bool in
                text.lowercased() == rule.key.lowercased()
            })
        }.sorted(by: { $0.0.key.characters.count > $0.1.key.characters.count })
        
        var endBoss : [(Range<String.Index> , (Trigger, Correction))] = []
        
        var selfText = self
        
        triggeredRulesArray.forEach { rule in
//            var difference = 0
//            if let lastrange = endBoss.last?.0 {
//                selfText = self.substring(from: lastrange.upperBound)
//                difference = lastrange.upperBound.encodedOffset
//            }
            
            guard var range = selfText.range(of: rule.key) ?? selfText.range(of: rule.key.lowercased()) else { return }
//            range.lowerBound = range.lowerBound.
//            guard !endBoss.contains(where: { tuple -> Bool in
//                range.overlaps(tuple.0)
//            }) else { return }
            endBoss.append((range, (rule.key, rule.value)))
        }
        
        guard !endBoss.isEmpty else { return }
        
        endBoss.sort { (lhs, rhs) -> Bool in
            return lhs.1.0.count > rhs.1.0.count
        }
        
        onCompletion(endBoss)
        
//        // Wishing Swift 4 would be able to build Foundation on linux, so a dictionary.filter could actually return a dictionary.
//        var triggeredRules: [Trigger: Correction] = [:]
//        triggeredRulesArray.forEach { ruleTuple in
//            triggeredRules[ruleTuple.key] = ruleTuple.value
//        }
//
//        guard !triggeredRules.isEmpty else { return }
//
//        onCompletion(triggeredRules)
    }
}
