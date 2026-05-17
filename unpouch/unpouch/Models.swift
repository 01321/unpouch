import Foundation

struct Pouch: Codable, Identifiable {
    let id = UUID()
    let date: Date
    let strength: Int // mg
}

struct Settings: Codable {
    var dailyLimit: Int // number of pouches
    var resetHour: Int
    var language: String // "en", "pl", "de"
    
    init() {
        self.dailyLimit = 10
        self.resetHour = 1 // 1:00 AM default
        self.language = "en"
    }
}
