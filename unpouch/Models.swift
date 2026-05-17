import Foundation

struct Pouch: Codable, Equatable {
    let date: Date
    let strength: Int // in mg
}

struct Settings: Codable {
    var dailyLimit: Int = 50 // default 50mg
    var resetHour: Int = 6   // default 6 AM
    var resetMinute: Int = 0
}
