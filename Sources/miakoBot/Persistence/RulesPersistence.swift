//
//  RulesPersistence.swift
//  miakoBot
//
//  Created by Bart Kneepkens on 04/11/2017.
//

import Foundation
import SwiftyJSON

fileprivate let fOpenModeWritePlus = "w+"
fileprivate let fOpenModeRead = "r"
fileprivate let readChunkSize = 1024
fileprivate let accessModeReadOK: Int32 = 0x04

/// `RulesPersistence` saves and reads rules to and from the persistence files.
class RulesPersistence {
    
    private init() {}
    static let shared = RulesPersistence()
    
    /// Saves rules to a chat's persistence file.
    ///
    /// - Parameters:
    ///   - rules: The rules that should be saved to the persistent file
    ///   - chat: The chat identifier for which the rules should be saved to the persistent file
    func save(rules: [Trigger: Correction], for chat: Chat) {
        var encodedRules: [Trigger: Correction] = [:]
        
        rules.forEach { pair in
            encodedRules[encode(pair.key) ?? pair.key] = encode(pair.value) ?? pair.value
        }
        
        let encodedRulesJSON = JSON(encodedRules)
        guard let jsonString = encodedRulesJSON.rawString() else { return }
        guard let filePointer = fopen(path(for: chat), fOpenModeWritePlus) else { return }
        defer { fclose(filePointer) }
        var jsonStringAsBytes: [UInt8] = Array(jsonString.utf8)
        _ = fwrite(&jsonStringAsBytes, 1, jsonStringAsBytes.count, filePointer)
    }
    
    /// Reads rules from a chat's persistence file.
    ///
    /// - Parameter chat: The chat identifier from which the rules should be read
    /// - Returns: The rules that have been read for this chat's persistent file, `nil` if the file does not exist or it could
    /// not be read propery
    func readRules(for chat: Chat) -> [Trigger: Correction]? {
        guard access(path(for: chat), accessModeReadOK) == 0 else { return nil }
        guard let filePointer = fopen(path(for: chat), fOpenModeRead) else { return nil }
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: readChunkSize)
        defer { buffer.deallocate(capacity: readChunkSize) }
        var outputString: String = ""
        
        repeat {
            let count = fread(buffer, 1, readChunkSize, filePointer)
            guard ferror(filePointer) == 0 else { return nil }
            
            (0 ..< count).forEach { index in
                outputString.append(Character(UnicodeScalar(buffer[index])))
            }
        } while feof(filePointer) == 0
        
        guard !outputString.isEmpty else { return nil }
        let readStringAsJSON = JSON.parse(string: outputString)
        guard let readCorrections = readStringAsJSON.dictionaryObject as? [Trigger: Correction] else { return nil }
        var decodedCorrections: [Trigger: Correction] = [:]
        
        readCorrections.forEach { pair in
            decodedCorrections[decode(pair.key) ?? pair.key] = decode(pair.value) ?? pair.value
        }
        return decodedCorrections
    }
    
    func migrateChat(from chat: Chat, to newId: Chat) -> Bool {
        guard access(path(for: chat), accessModeReadOK) == 0 else { return false }
        if rename(path(for: chat), path(for: newId)) == 0 {
            remove(path(for: chat))
            return true
        }
        return false
    }
}

// MARK: - Private helpers
extension RulesPersistence {
    
    /// Returns the filepath for a chat's persistent file.
    ///
    /// - Parameter chat: The chat identifier from which the path should be created
    /// - Returns: The filepath for the chat's persistent file
    fileprivate func path(for chat: Chat) -> String {
        return "/var/lib/dcb/\(chat)"
    }
}

// MARK: - Encoding and decoding
extension RulesPersistence {
    
    /// Encodes text to unlossy ascii and returns it in utf8.
    ///
    /// - Parameter text: The text to be encoded
    /// - Returns: The encoded text
    fileprivate func encode(_ text: String) -> String? {
        guard let data = text.data(using: .nonLossyASCII, allowLossyConversion: true) else { return nil }
        return String(data: data, encoding: .utf8)!
    }
    
    /// Decodes text to utf8 and returns it in unlossy ascii.
    ///
    /// - Parameter text: The text to be decoded
    /// - Returns: The decoded text
    fileprivate func decode(_ text: String) -> String? {
        guard let data = text.data(using: .utf8) else { return nil }
        return String(data: data, encoding: .nonLossyASCII)
    }
}
