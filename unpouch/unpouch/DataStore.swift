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
            return "over_limit"
        } else {
            if count == limit - 1 {
                return "slightly_under"
            }
            return "under_limit"
        }
    }
    
    func getPouchesForPeriod(_ period: StatsPeriod) -> [Pouch] {
        let now = Date()
        let calendar = Calendar.current
        let startDate: Date
        
        switch period {
        case .day24:
            startDate = calendar.date(byAdding: .hour, value: -24, to: now)!
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: now)!
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: now)!
        case .months2:
            startDate = calendar.date(byAdding: .month, value: -2, to: now)!
        case .months6:
            startDate = calendar.date(byAdding: .month, value: -6, to: now)!
        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: now)!
        case .years2:
            startDate = calendar.date(byAdding: .year, value: -2, to: now)!
        }
        
        return pouches.filter { $0.date >= startDate }.sorted { $0.date < $1.date }
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
    case day24 = "24h"
    case week = "1w"
    case month = "1m"
    case months2 = "2m"
    case months6 = "6m"
    case year = "1y"
    case years2 = "2y"
    
    var localizableKey: String {
        return self.rawValue
    }
}
