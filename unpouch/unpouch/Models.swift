import Foundation

struct Pouch: Codable, Equatable {
    let id: UUID
    let date: Date
    let strength: Int
    
    init(id: UUID = UUID(), date: Date, strength: Int) {
        self.id = id
        self.date = date
        self.strength = strength
    }
}

struct Settings: Codable {
    var dailyLimit: Int = 5
    var resetHour: Int = 1
    var language: String = "en"
}
