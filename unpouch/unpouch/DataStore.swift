import Foundation
import Combine

class DataStore: ObservableObject {
    @Published var pouches: [Pouch] = []
    @Published var settings: Settings = Settings()
    
    private let pouchesKey = "saved_pouches_v3"
    private let settingsKey = "saved_settings_v3"
    
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
    
    func updateSettings(limit: Int, resetHour: Int, language: String) {
        settings.dailyLimitCount = limit
        settings.resetHour = resetHour
        settings.languageCode = language
        save()
    }
    
    func getTodayStats() -> (count: Int, totalMg: Int) {
        let now = Date()
        let calendar = Calendar.current
        
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = settings.resetHour
        components.minute = 0
        components.second = 0
        
        guard var lastResetDate = calendar.date(from: components) else {
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
    
    func getLimitStatus() -> (text: String, color: Color) {
        let count = getTodayStats().count
        let limit = settings.dailyLimitCount
        
        if count == limit {
            return (NSLocalizedString("limit_exact", comment: ""), .orange)
        } else if count > limit {
            if count == limit + 1 {
                return (NSLocalizedString("limit_slightly_over", comment: ""), .orange)
            }
            return (NSLocalizedString("limit_over", comment: ""), .red)
        } else {
            if count == limit - 1 {
                return (NSLocalizedString("limit_slightly_under", comment: ""), .yellow)
            }
            return (NSLocalizedString("limit_under", comment: ""), .green)
        }
    }
    
    func getStatsForPeriod(_ period: StatsPeriod) -> [(date: Date, count: Int)] {
        let now = Date()
        let calendar = Calendar.current
        var result: [(Date, Int)] = []
        
        let filteredPouches = pouches.filter { pouch in
            calendar.isDate(pouch.date, in: period.dateRange(to: now), at: .start)
        }
        
        let dates = period.generateDates(to: now, calendar: calendar)
        
        for date in dates {
            let count = filteredPouches.filter { pouch in
                period.isDate(pouch.date, inSameUnitAs: date, calendar: calendar)
            }.count
            result.append((date, count))
        }
        
        return result
    }
    
    func save() {
        if let encoded = try? JSONEncoder().encode(pouches) {
            UserDefaults.standard.set(encoded, forKey: pouchesKey)
        }
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: settingsKey)
        }
    }
    
    func load() {
        if let data = UserDefaults.standard.data(forKey: pouchesKey),
           let decoded = try? JSONDecoder().decode([Pouch].self, from: data) {
            pouches = decoded
        }
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode(Settings.self, from: data) {
            settings = decoded
        }
    }
}
