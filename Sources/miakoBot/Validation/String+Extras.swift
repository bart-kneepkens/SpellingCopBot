//
//  String+Extras.swift
//  miakoBot
//
//  Created by Bart Kneepkens on 09/11/2017.
//

import Foundation
import Rexy

extension String {
    var isUsernameTag: Bool {
        do {
            let expression = try Regex("@([A-Za-z0-9\\-\\_]+)")
            return self =~ expression
        } catch {
            print(error)
        }
        return false
    }
    
    var isUrl: Bool {
        do {
            let expression = try Regex("((\\w)*|([0-9]*)|([-|_])*)+([\\.|/]((\\w)*|([0-9]*)|([-|_])*))+")
            return self =~ expression
        } catch {
            print(error)
        }
        return false
    }
}
