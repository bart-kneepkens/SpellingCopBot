//
//  RuleBook.swift
//  miakoBot
//
//  Created by Bart Kneepkens on 05/11/2017.
//

import Foundation
import Dispatch

enum RuleBookError: Error {
    /// The `RuleBook` already contains a rule with the specified trigger for the specified chat.
    case ruleAlreadyExists
    /// The `RuleBook` does not contain a rule with the specified trigger for the specified chat.
    case ruleDoesNotExist
}

/// `RuleBook` keeps track of rules for every chat. Its rules can be directly modified and persistence to the persistence files
/// will happen automatically at the appropriate times.
class RuleBook {
    private init() {}
    static let shared = RuleBook()
    private var allRules: [Chat: [Trigger: Correction]] = [:]
    
    /// Loads rules from the persistence files into the rulebook memory, but only if they have not been loaded into memory before.
    ///
    /// - Parameter chat: The chat identifier for which the rules should be loaded
    func loadRulesIfNeeded(for chat: Chat) {
        guard rules(for: chat) == nil, let loadedRules = RulesPersistence.shared.readRules(for: chat) else { return }
        allRules[chat] = loadedRules
    }
    
    /// Adds a new rule to the rulebook.
    ///
    /// - Parameters:
    ///   - trigger: The new rule's trigger word
    ///   - correction: The new rule's correction word
    ///   - chat: The chat identifier for which the rule should be added
    /// - Throws: An error of type `RuleBookError.ruleAlreadyExists`
    func add(ruleWithTrigger trigger: Trigger, correction: Correction, for chat: Chat) throws {
     var rulesForChat = rules(for: chat)
        if rulesForChat != nil {
            guard rulesForChat![trigger] == nil else { throw RuleBookError.ruleAlreadyExists }
        } else {
            rulesForChat = [:]
        }
        
        rulesForChat![trigger] = correction
        allRules[chat] = rulesForChat!
        persistRules(for: chat)
    }
    
    /// Removes a rule from the rulebook.
    ///
    /// - Parameters:
    ///   - trigger: The trigger for which the rule should be deleted
    ///   - chat: The chat identifier for which the rule should be removed
    /// - Throws: An error of type `RuleBookError.ruleDoesNotExist`
    func remove(ruleWith trigger: Trigger, for chat: Chat) throws {
        guard var rulesForChat = rules(for: chat),
            !rulesForChat.isEmpty,
            rulesForChat[trigger] != nil
            else { throw RuleBookError.ruleDoesNotExist }
        
        rulesForChat.removeValue(forKey: trigger)
        allRules[chat] = rulesForChat
        persistRules(for: chat)
    }
    
    /// Gets all rules for a certain chat.
    ///
    /// - Parameter chat: The chat identifier for which the rule should be removed
    /// - Returns: An optional dictionary containing the rules
    func rules(for chat: Chat) -> [Trigger: Correction]? {
        return allRules[chat]
    }
}

// MARK: - Private helpers
extension RuleBook {
    
    /// Persists the rules for a certain chat to the persistence files.
    ///
    /// - Parameter chat: The chat identifier for which the rule should be removed
    fileprivate func persistRules(for chat: Chat) {
        DispatchQueue.main.async {
            guard let rulesForChat = self.rules(for: chat) else { return }
            RulesPersistence.shared.save(rules: rulesForChat, for: chat)
        }
    }
}
