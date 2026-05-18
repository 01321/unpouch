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
    
    func getStatsForPeriod(_ period: StatsPeriod) -> [(date: Date, count: Int, mg: Int)] {
        let now = Date()
        let calendar = Calendar.current
        var result: [(Date, Int, Int)] = []
        
        let startDate: Date
        
        switch period {
        case .day24:
            startDate = calendar.date(byAdding: .hour, value: -24, to: now)!
            for i in 0..<24 {
                guard let bucketStart = calendar.date(byAdding: .hour, value: i, to: startDate) else { continue }
                guard let bucketEnd = calendar.date(byAdding: .hour, value: 1, to: bucketStart) else { continue }
                let bucketPouches = pouches.filter { $0.date >= bucketStart && $0.date < bucketEnd }
                result.append((bucketStart, bucketPouches.count, bucketPouches.reduce(0) { $0 + $1.strength }))
            }
            return result
            
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: now)!
            for i in 0..<7 {
                guard let bucketStart = calendar.date(byAdding: .day, value: i, to: startDate) else { continue }
                guard let bucketEnd = calendar.date(byAdding: .day, value: 1, to: bucketStart) else { continue }
                let bucketPouches = pouches.filter { $0.date >= bucketStart && $0.date < bucketEnd }
                result.append((bucketStart, bucketPouches.count, bucketPouches.reduce(0) { $0 + $1.strength }))
            }
            return result
            
        case .month2:
            startDate = calendar.date(byAdding: .month, value: -2, to: now)!
            for i in 0..<60 {
                guard let bucketStart = calendar.date(byAdding: .day, value: i, to: startDate) else { continue }
                guard let bucketEnd = calendar.date(byAdding: .day, value: 1, to: bucketStart) else { continue }
                let bucketPouches = pouches.filter { $0.date >= bucketStart && $0.date < bucketEnd }
                result.append((bucketStart, bucketPouches.count, bucketPouches.reduce(0) { $0 + $1.strength }))
            }
            return result

        case .month6:
            startDate = calendar.date(byAdding: .month, value: -6, to: now)!
             for i in 0..<180 { 
                guard let bucketStart = calendar.date(byAdding: .day, value: i, to: startDate) else { continue }
                guard let bucketEnd = calendar.date(byAdding: .day, value: 1, to: bucketStart) else { continue }
                let bucketPouches = pouches.filter { $0.date >= bucketStart && $0.date < bucketEnd }
                result.append((bucketStart, bucketPouches.count, bucketPouches.reduce(0) { $0 + $1.strength }))
            }
            return result

        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: now)!
            for i in 0..<12 {
                guard let bucketStart = calendar.date(byAdding: .month, value: i, to: startDate) else { continue }
                guard let bucketEnd = calendar.date(byAdding: .month, value: 1, to: bucketStart) else { continue }
                let bucketPouches = pouches.filter { $0.date >= bucketStart && $0.date < bucketEnd }
                result.append((bucketStart, bucketPouches.count, bucketPouches.reduce(0) { $0 + $1.strength }))
            }
            return result

        case .year2:
            startDate = calendar.date(byAdding: .year, value: -2, to: now)!
            for i in 0..<24 {
                guard let bucketStart = calendar.date(byAdding: .month, value: i, to: startDate) else { continue }
                guard let bucketEnd = calendar.date(byAdding: .month, value: 1, to: bucketStart) else { continue }
                let bucketPouches = pouches.filter { $0.date >= bucketStart && $0.date < bucketEnd }
                result.append((bucketStart, bucketPouches.count, bucketPouches.reduce(0) { $0 + $1.strength }))
            }
            return result
        }
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

enum StatsPeriod: String, CaseIterable, Identifiable {
    case day24 = "24H"
    case week = "1W"
    case month2 = "2M"
    case month6 = "6M"
    case year = "1Y"
    case year2 = "2Y"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .day24: return "24h_period"
        case .week: return "week_period"
        case .month2: return "2m_period"
        case .month6: return "6m_period"
        case .year: return "year_period"
        case .year2: return "2y_period"
        }
    }
}
