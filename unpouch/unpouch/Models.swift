import Foundation

struct Pouch: Identifiable, Codable {
    var id = UUID()
    var date: Date
    var strength: Int // w mg
}

struct Settings: Codable {
    var dailyLimitCount: Int = 10
    var resetHour: Int = 1
    var languageCode: String = "en"
    var currentStrength: Int = 10
    
    enum Languages: String, CaseIterable, Identifiable {
        case english = "en"
        case polish = "pl"
        case german = "de"
        
        var id: String { rawValue }
        var displayName: String {
            switch self {
            case .english: return "English"
            case .polish: return "Polski"
            case .german: return "Deutsch"
            }
        }
    }
}

enum StatsPeriod: String, CaseIterable, Identifiable {
    case day24 = "24h"
    case week = "1w"
    case month = "1m"
    case twoMonths = "2m"
    case sixMonths = "6m"
    case year = "1y"
    case twoYears = "2y"
    
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .day24: return "24h"
        case .week: return "1 Week"
        case .month: return "1 Month"
        case .twoMonths: return "2 Months"
        case .sixMonths: return "6 Months"
        case .year: return "1 Year"
        case .twoYears: return "2 Years"
        }
    }
    
    func dateRange(to now: Date) -> ClosedRange<Date> {
        let calendar = Calendar.current
        switch self {
        case .day24: return calendar.date(byAdding: .hour, value: -24, to: now)!...now
        case .week: return calendar.date(byAdding: .day, value: -7, to: now)!...now
        case .month: return calendar.date(byAdding: .month, value: -1, to: now)!...now
        case .twoMonths: return calendar.date(byAdding: .month, value: -2, to: now)!...now
        case .sixMonths: return calendar.date(byAdding: .month, value: -6, to: now)!...now
        case .year: return calendar.date(byAdding: .year, value: -1, to: now)!...now
        case .twoYears: return calendar.date(byAdding: .year, value: -2, to: now)!...now
        }
    }
    
    func generateDates(to now: Date, calendar: Calendar) -> [Date] {
        var dates: [Date] = []
        var currentDate = dateRange(to: now).lowerBound
        
        while currentDate <= now {
            dates.append(currentDate)
            switch self {
            case .day24, .week:
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            case .month, .twoMonths, .sixMonths, .year, .twoYears:
                currentDate = calendar.date(byAdding: .month, value: 1, to: currentDate)!
            }
        }
        return dates
    }
    
    func isDate(_ date: Date, inSameUnitAs target: Date, calendar: Calendar) -> Bool {
        switch self {
        case .day24, .week:
            return calendar.isDate(date, inSameDayAs: target)
        case .month, .twoMonths, .sixMonths, .year, .twoYears:
            let comp1 = calendar.dateComponents([.year, .month], from: date)
            let comp2 = calendar.dateComponents([.year, .month], from: target)
            return comp1.year == comp2.year && comp1.month == comp2.month
        }
    }
}
