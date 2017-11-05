import Foundation
import TelegramBot
import SwiftyJSON
import Dispatch

typealias Trigger = String
typealias Correction = String
typealias Chat = Int64

fileprivate let token = readToken(from: "MIAKO_BOT_TOKEN")
fileprivate let bot = TelegramBot(token: token)
fileprivate let router = Router(bot: bot)

router["add_rule"] = addRuleCommandHandler

router["remove_rule"] = removeRuleCommandHandler

router["list"] = listCommandHandler

router["yell"] = broadcastCommandHandler

// Dirty, dirty hack. telegram-bot-swift has an issue which makes the app un-responding after a while of inactivity.
// This way, it will stay alive.
let timer = DispatchSource.makeTimerSource()
fileprivate func keepMeAlive() {
    timer.scheduleRepeating(deadline: .now(), interval: .seconds(10))
    timer.setEventHandler(handler: {})
    timer.resume()
}

keepMeAlive()

let _ = MiakoBot()

fatalError("Server stopped due to error: \(String(describing: bot.lastError))")
