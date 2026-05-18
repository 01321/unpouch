import Foundation
import SwiftUI

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
    var customStrengths: [Int] = [] // Custom strengths added by user
    var accentColor: String = "blue" // "blue", "red", "green", "purple", "orange", "pink"
    
    var resolvedAccentColor: Color {
        switch accentColor {
        case "red": return .red
        case "green": return .green
        case "purple": return .purple
        case "orange": return .orange
        case "pink": return .pink
        default: return .blue
        }
    }
    
    var availableStrengths: [Int] {
        let baseStrengths = Array(stride(from: 10, through: 100, by: 10))
        var allStrengths = Set(baseStrengths + customStrengths)
        allStrengths.remove(0) // Remove 0mg if present
        return Array(allStrengths).sorted()
    }
    
    func usedStrengths(maxCount: Int = 10) -> [Int] {
        // Return most recently used strengths up to maxCount
        // For simplicity, we'll just return the first maxCount from availableStrengths
        // A more sophisticated implementation would track usage frequency
        return Array(availableStrengths.prefix(maxCount))
    }
}
