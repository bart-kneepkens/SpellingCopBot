//
//  RuleBook.swift
//  miakoBot
//
//  Created by Bart Kneepkens on 05/11/2017.
//

import Foundation

enum RuleBookError: Error {
    case ruleAlreadyExists
    case ruleDoesNotExist
}

class RuleBook {
    private init(){}
    static let shared = RuleBook()
    private var allRules: [Chat: [Trigger: Correction]] = [:]
    
    func loadRulesIfNeeded(for chat: Chat) {
        guard rules(for: chat) == nil, let loadedRules = RulesPersistence.shared.readRules(for: chat) else { return }
        allRules[chat] = loadedRules
    }
    
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
    
    func remove(ruleWith trigger: Trigger, for chat: Chat) throws {
        guard var rulesForChat = rules(for: chat),
            !rulesForChat.isEmpty,
            rulesForChat[trigger] != nil
            else { throw RuleBookError.ruleDoesNotExist }
        
        rulesForChat.removeValue(forKey: trigger)
        allRules[chat] = rulesForChat
        persistRules(for: chat)
    }
    
    func rules(for chat: Chat) -> [Trigger: Correction]? {
        return allRules[chat]
    }
    
    fileprivate func persistRules(for chat: Chat) {
        DispatchQueue.main.async {
            guard let rulesForChat = self.rules(for: chat) else { return }
            RulesPersistence.shared.save(rules: rulesForChat, for: chat)
        }
    }
}
