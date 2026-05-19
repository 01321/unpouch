import Foundation
import Combine

class DataStore: ObservableObject {
    @Published var pouches: [Pouch] = []
    @Published var settings: Settings = Settings()
    
    private let pouchesKey = "saved_pouches"
    private let settingsKey = "saved_settings"
    private let sharedDefaults = UserDefaults(suiteName: "group.unpouch.shared")
    
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
    
    func updateAccentColor(_ color: String) {
        objectWillChange.send()
        settings.accentColor = color
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
            
        case .week1:
            startDate = calendar.date(byAdding: .day, value: -7, to: now)!
            for i in 0..<7 {
                guard let bucketStart = calendar.date(byAdding: .day, value: i, to: startDate) else { continue }
                guard let bucketEnd = calendar.date(byAdding: .day, value: 1, to: bucketStart) else { continue }
                let bucketPouches = pouches.filter { $0.date >= bucketStart && $0.date < bucketEnd }
                result.append((bucketStart, bucketPouches.count, bucketPouches.reduce(0) { $0 + $1.strength }))
            }
            return result
            
        case .week2:
            startDate = calendar.date(byAdding: .day, value: -14, to: now)!
            for i in 0..<14 {
                guard let bucketStart = calendar.date(byAdding: .day, value: i, to: startDate) else { continue }
                guard let bucketEnd = calendar.date(byAdding: .day, value: 1, to: bucketStart) else { continue }
                let bucketPouches = pouches.filter { $0.date >= bucketStart && $0.date < bucketEnd }
                result.append((bucketStart, bucketPouches.count, bucketPouches.reduce(0) { $0 + $1.strength }))
            }
            return result

        case .month1:
            startDate = calendar.date(byAdding: .month, value: -1, to: now)!
            for i in 0..<30 {
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

        case .year1:
            startDate = calendar.date(byAdding: .year, value: -1, to: now)!
            for i in 0..<12 {
                guard let bucketStart = calendar.date(byAdding: .month, value: i, to: startDate) else { continue }
                guard let bucketEnd = calendar.date(byAdding: .month, value: 1, to: bucketStart) else { continue }
                let bucketPouches = pouches.filter { $0.date >= bucketStart && $0.date < bucketEnd }
                result.append((bucketStart, bucketPouches.count, bucketPouches.reduce(0) { $0 + $1.strength }))
            }
            return result
        }
    }
    
    func save() {
        // Zapisz do lokalnych UserDefaults
        if let encodedPouches = try? JSONEncoder().encode(pouches) {
            UserDefaults.standard.set(encodedPouches, forKey: pouchesKey)
        }
        if let encodedSettings = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encodedSettings, forKey: settingsKey)
        }
        
        // Zapisz też do shared UserDefaults dla widgetu
        if let encodedPouches = try? JSONEncoder().encode(pouches) {
            sharedDefaults?.set(encodedPouches, forKey: pouchesKey)
        }
        if let encodedSettings = try? JSONEncoder().encode(settings) {
            sharedDefaults?.set(encodedSettings, forKey: settingsKey)
        }
    }
    
    func load() {
        // Najpierw spróbuj załadować z shared UserDefaults (jeśli widget już coś zapisał)
        if let savedPouches = sharedDefaults?.data(forKey: pouchesKey),
           let decodedPouches = try? JSONDecoder().decode([Pouch].self, from: savedPouches) {
            pouches = decodedPouches
        } else if let savedPouches = UserDefaults.standard.data(forKey: pouchesKey),
                  let decodedPouches = try? JSONDecoder().decode([Pouch].self, from: savedPouches) {
            pouches = decodedPouches
        }
        
        if let savedSettings = sharedDefaults?.data(forKey: settingsKey),
           let decodedSettings = try? JSONDecoder().decode(Settings.self, from: savedSettings) {
            settings = decodedSettings
        } else if let savedSettings = UserDefaults.standard.data(forKey: settingsKey),
                  let decodedSettings = try? JSONDecoder().decode(Settings.self, from: savedSettings) {
            settings = decodedSettings
        }
    }
    
    func generateTestData() {
        let calendar = Calendar.current
        let now = Date()
        var testPouches: [Pouch] = []
        
        // Generate data for the last 6 months
        for dayOffset in 0..<180 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            
            // Random number of pouches per day (0-15), limit max 15 per day
            let pouchesPerDay = Int.random(in: 0...15)
            
            for _ in 0..<pouchesPerDay {
                // Random strength between 10 and 50 mg
                let strength = [10, 15, 20, 25, 30, 40, 50].randomElement() ?? 20
                
                // Random hour within the day
                let hour = Int.random(in: 8...22)
                let minute = Int.random(in: 0...59)
                
                var pouchDateComponents = calendar.dateComponents([.year, .month, .day], from: date)
                pouchDateComponents.hour = hour
                pouchDateComponents.minute = minute
                pouchDateComponents.second = Int.random(in: 0...59)
                
                if let pouchDate = calendar.date(from: pouchDateComponents) {
                    let pouch = Pouch(date: pouchDate, strength: strength)
                    testPouches.append(pouch)
                }
            }
        }
        
        // Sort by date
        testPouches.sort { $0.date < $1.date }
        pouches = testPouches
        save()
    }
}

enum StatsPeriod: String, CaseIterable, Identifiable {
    case day24 = "24H"
    case week1 = "1W"
    case week2 = "2W"
    case month1 = "1M"
    case month2 = "2M"
    case month6 = "6M"
    case year1 = "1Y"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .day24: return "24h"
        case .week1: return "1W"
        case .week2: return "2W"
        case .month1: return "1M"
        case .month2: return "2M"
        case .month6: return "6M"
        case .year1: return "1Y"
        }
    }
    
    var localizedName: String {
        switch self {
        case .day24: return "24h"
        case .week1: return "1W"
        case .week2: return "2W"
        case .month1: return "1M"
        case .month2: return "2M"
        case .month6: return "6M"
        case .year1: return "1Y"
        }
    }
}
