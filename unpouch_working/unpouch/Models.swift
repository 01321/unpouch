import Foundation
import SwiftUI

struct Pouch: Codable, Identifiable {
    let id = UUID()
    let date: Date
    let strength: Int // mg
}

extension Date {
    func timeAgoString() -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day, .weekOfYear, .month, .year], from: self, to: now)
        
        if let years = components.year, years > 0 {
            return String(format: NSLocalizedString("time_ago_years", comment: ""), years)
        }
        if let months = components.month, months > 0 {
            return String(format: NSLocalizedString("time_ago_months", comment: ""), months)
        }
        if let weeks = components.weekOfYear, weeks > 0 {
            return String(format: NSLocalizedString("time_ago_weeks", comment: ""), weeks)
        }
        if let days = components.day, days > 0 {
            return String(format: NSLocalizedString("time_ago_days", comment: ""), days)
        }
        if let hours = components.hour, hours > 0 {
            return String(format: NSLocalizedString("time_ago_hours", comment: ""), hours)
        }
        if let minutes = components.minute, minutes > 0 {
            return String(format: NSLocalizedString("time_ago_minutes", comment: ""), minutes)
        }
        return NSLocalizedString("time_ago_now", comment: "")
    }
    
    func formattedTimeAgo() -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.hour, .minute], from: self, to: now)
        
        if let hours = components.hour, let minutes = components.minute {
            if hours > 0 {
                return String(format: NSLocalizedString("time_detailed_hm", comment: ""), hours, minutes)
            } else {
                return String(format: NSLocalizedString("time_detailed_m", comment: ""), minutes)
            }
        }
        return NSLocalizedString("just_now", comment: "")
    }
}

struct Settings: Codable {
    var dailyLimit: Int = 10 // Number of pouches
    var resetHour: Int = 1
    var language: String = "en" // "en", "pl", "de"
    var currentStrength: Int = 10 // Default strength in mg
    var customStrengths: [Int] = [] // Custom strengths added by user
    var accentColor: String = "blue" // "blue", "red", "green", "purple", "orange", "pink"
    
    // Planner settings
    var plannerDailyLimit: Int = 8 // Default pouches per day for planner
    var sleepStartHour: Double = 23.0 // Default sleep start time (23:00)
    var sleepEndHour: Double = 7.0 // Default sleep end time (7:00)
    
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
    
    func usedStrengths(from pouches: [Pouch], maxCount: Int = 10) -> [Int] {
        // Return most recently used strengths up to maxCount
        // Sort by usage frequency (most used first), then by value
        var strengthUsage: [Int: Int] = [:]
        
        // Count occurrences of each strength in pouches
        for pouch in pouches {
            strengthUsage[pouch.strength, default: 0] += 1
        }
        
        // Get all available strengths
        var allStrengths = availableStrengths
        
        // Sort by usage count (descending), then by strength value (ascending)
        allStrengths.sort { a, b in
            let countA = strengthUsage[a] ?? 0
            let countB = strengthUsage[b] ?? 0
            
            if countA != countB {
                return countA > countB // Most used first
            }
            return a < b // Then by value ascending
        }
        
        return Array(allStrengths.prefix(maxCount))
    }
}
