import Foundation
import Combine

class DataStore: ObservableObject {
    @Published var pouches: [Pouch] = []
    @Published var settings: Settings = Settings()
    
    private let pouchesKey = "saved_pouches"
    private let settingsKey = "saved_settings"
    
    init() {
        load()
    }
    
    func addPouch(strength: Int) {
        let newPouch = Pouch(date: Date(), strength: strength)
        pouches.append(newPouch)
        save()
    }
    
    func removeLastPouch() {
        guard !pouches.isEmpty else { return }
        pouches.removeLast()
        save()
    }
    
    func updateSettings(dailyLimit: Int, resetHour: Int, language: String) {
        settings.dailyLimit = dailyLimit
        settings.resetHour = resetHour
        settings.language = language
        save()
    }
    
    func getTodayStats() -> (count: Int, totalMg: Int) {
        let now = Date()
        let calendar = Calendar.current
        
        var lastResetComponents = calendar.dateComponents([.year, .month, .day], from: now)
        lastResetComponents.hour = settings.resetHour
        lastResetComponents.minute = 0
        lastResetComponents.second = 0
        
        guard var lastResetDate = calendar.date(from: lastResetComponents) else {
            return (0, 0)
        }
        
        if now < lastResetDate {
            lastResetDate = calendar.date(byAdding: .day, value: -1, to: lastResetDate)!
        }
        
        let todaysPouches = pouches.filter { $0.date >= lastResetDate }
        
        let count = todaysPouches.count
        let totalMg = todaysPouches.reduce(0) { $0 + $1.strength }
        
        return (count, totalMg)
    }
    
    func getLimitStatus() -> String {
        let (count, _) = getTodayStats()
        let limit = settings.dailyLimit
        
        if count == limit {
            return "limit_reached"
        } else if count > limit {
            if count == limit + 1 {
                return "slightly_over"
            }
            return "over"
        } else {
            if count == limit - 1 && limit > 0 {
                return "slightly_under"
            }
            return "under"
        }
    }
    
    func getPouchesForPeriod(_ period: StatsPeriod) -> [Pouch] {
        let now = Date()
        let calendar = Calendar.current
        
        var startDate: Date?
        switch period {
        case .day:
            startDate = calendar.date(byAdding: .hour, value: -24, to: now)
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: now)
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: now)
        case .twoMonths:
            startDate = calendar.date(byAdding: .month, value: -2, to: now)
        case .sixMonths:
            startDate = calendar.date(byAdding: .month, value: -6, to: now)
        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: now)
        case .twoYears:
            startDate = calendar.date(byAdding: .year, value: -2, to: now)
        }
        
        guard let start = startDate else { return [] }
        return pouches.filter { $0.date >= start && $0.date <= now }
    }
    
    func save() {
        if let encodedPouches = try? JSONEncoder().encode(pouches) {
            UserDefaults.standard.set(encodedPouches, forKey: pouchesKey)
        }
        if let encodedSettings = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encodedSettings, forKey: settingsKey)
        }
    }
    
    func load() {
        if let savedPouches = UserDefaults.standard.data(forKey: pouchesKey),
           let decodedPouches = try? JSONDecoder().decode([Pouch].self, from: savedPouches) {
            pouches = decodedPouches
        }
        
        if let savedSettings = UserDefaults.standard.data(forKey: settingsKey),
           let decodedSettings = try? JSONDecoder().decode(Settings.self, from: savedSettings) {
            settings = decodedSettings
        }
    }
}

enum StatsPeriod: String, CaseIterable {
    case day = "24h"
    case week = "1w"
    case month = "1m"
    case twoMonths = "2m"
    case sixMonths = "6m"
    case year = "1y"
    case twoYears = "2y"
    
    var localizedName: String {
        switch self {
        case .day: return NSLocalizedString("24_hours", comment: "")
        case .week: return NSLocalizedString("1_week", comment: "")
        case .month: return NSLocalizedString("1_month", comment: "")
        case .twoMonths: return NSLocalizedString("2_months", comment: "")
        case .sixMonths: return NSLocalizedString("6_months", comment: "")
        case .year: return NSLocalizedString("1_year", comment: "")
        case .twoYears: return NSLocalizedString("2_years", comment: "")
        }
    }
}
