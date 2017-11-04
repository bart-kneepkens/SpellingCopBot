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
fileprivate let accessModeR_OK: Int32 = 0x04

class RulesPersistence {
    
    private init(){}
    static let shared = RulesPersistence()
    
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
        let _ = fwrite(&jsonStringAsBytes, 1, jsonStringAsBytes.count, filePointer)
    }
    
    func readRules(for chat: Chat) -> [Trigger: Correction]? {
        guard access(path(for: chat), accessModeR_OK) == 0 else { return nil }
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
}

extension RulesPersistence {
    fileprivate func path(for chat: Chat) -> String {
        return "/var/lib/dcb/\(chat)"
    }
}

extension RulesPersistence {
    fileprivate func encode(_ s: String) -> String? {
        guard let data = s.data(using: .nonLossyASCII, allowLossyConversion: true) else { return nil }
        return String(data: data, encoding: .utf8)!
    }
    
    fileprivate func decode(_ s: String) -> String? {
        guard let data = s.data(using: .utf8) else { return nil }
        return String(data: data, encoding: .nonLossyASCII)
    }
}
