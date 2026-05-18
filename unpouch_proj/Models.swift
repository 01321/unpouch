import Foundation

struct Pouch: Codable, Identifiable {
    let id = UUID()
    let date: Date
    let strength: Int // mg
}

struct Settings: Codable {
    var dailyLimit: Int = 10 // Number of pouches
    var resetHour: Int = 1
    var language: String = "en" // "en", "pl", "de"
    var currentStrength: Int = 10 // Default strength in mg
}
