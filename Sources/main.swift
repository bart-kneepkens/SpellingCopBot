import Foundation
import TelegramBot
import Dispatch

typealias Trigger = String
typealias Correction = String
typealias Chat = Int64

// Dirty, dirty hack. telegram-bot-swift has an issue which makes the app un-responding after a while of inactivity.
// This way, it will stay alive.
let timer = DispatchSource.makeTimerSource()
fileprivate func keepMeAlive() {
    timer.scheduleRepeating(deadline: .now(), interval: .seconds(1))
    timer.setEventHandler(handler: {})
    timer.resume()
}

keepMeAlive()

MiakoBot().start()
