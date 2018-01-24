import Foundation
import TelegramBot
import Dispatch

typealias Trigger = String
typealias Correction = String
typealias Chat = Int64

// Dirty, dirty hack. telegram-bot-swift has an issue which makes the app un-responding after a while of inactivity.
// This way, it will stay alive.
let timer = DispatchSource.makeTimerSource()
var do_not_touch: Bool = false
fileprivate func keepMeAlive() {
    timer.scheduleRepeating(deadline: .now(), interval: .milliseconds(10))
    timer.setEventHandler(handler: {
        do_not_touch = !do_not_touch
    })
    timer.resume()
}

keepMeAlive()

MiakoBot().start()
