import Foundation

struct Pouch: Identifiable, Codable {
    let id: UUID
    var timestamp: Date
    var strength: Int
    
    init(id: UUID = UUID(), timestamp: Date = Date(), strength: Int) {
        self.id = id
        self.timestamp = timestamp
        self.strength = strength
    }
}

class DataStore: ObservableObject {
    @Published var pouches: [Pouch] = []
    @Published var settings: AppSettings = AppSettings()
    
    private let pouchesKey = "pouches"
    private let settingsKey = "settings"
    
    init() {
        loadPouches()
        loadSettings()
    }
    
    func addPouch(strength: Int) {
        let pouch = Pouch(strength: strength)
        pouches.insert(pouch, at: 0)
        savePouches()
    }
    
    func deletePouch(at offsets: IndexSet) {
        pouches.remove(atOffsets: offsets)
        savePouches()
    }
    
    func deleteAllPouches() {
        pouches.removeAll()
        savePouches()
    }
    
    private func savePouches() {
        if let encoded = try? JSONEncoder().encode(pouches) {
            UserDefaults.standard.set(encoded, forKey: pouchesKey)
        }
    }
    
    private func loadPouches() {
        if let data = UserDefaults.standard.data(forKey: pouchesKey),
           let decoded = try? JSONDecoder().decode([Pouch].self, from: data) {
            pouches = decoded
        }
    }
    
    func saveSettings() {
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: settingsKey)
        }
        
        // Apply language change immediately
        if let languageCode = settings.languageCode, !languageCode.isEmpty {
            UserDefaults.standard.set([languageCode], forKey: "AppleLanguages")
            UserDefaults.standard.synchronize()
        }
    }
    
    private func loadSettings() {
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            settings = decoded
        }
        
        // Apply saved language on startup
        if !settings.languageCode.isEmpty {
            UserDefaults.standard.set([settings.languageCode], forKey: "AppleLanguages")
            UserDefaults.standard.synchronize()
        }
    }
    
    func getTodayPouches() -> [Pouch] {
        let calendar = Calendar.current
        let now = Date()
        return pouches.filter { calendar.isDateInToday($0.timestamp) }
    }
    
    func getStatsForPeriod(_ period: StatsPeriod) -> [(date: Date, count: Int)] {
        let calendar = Calendar.current
        let now = Date()
        var components = DateComponents()
        
        switch period {
        case .day24:
            components.hour = -24
        case .week1:
            components.day = -7
        case .month1:
            components.month = -1
        case .year1:
            components.year = -1
        case .all:
            guard let firstPouch = pouches.min(by: { $0.timestamp < $1.timestamp }) else {
                return []
            }
            let interval = now.timeIntervalSince(firstPouch.timestamp)
            let days = Int(interval / 86400) + 1
            components.day = -days
        }
        
        let startDate = period == .all && !pouches.isEmpty 
            ? calendar.startOfDay(for: pouches.min(by: { $0.timestamp < $1.timestamp })!.timestamp)
            : calendar.date(byAdding: components, to: now)!
        
        var result: [(date: Date, count: Int)] = []
        var currentDate = calendar.startOfDay(for: startDate)
        
        while currentDate <= now {
            let dayPouches = pouches.filter { calendar.isDate($0.timestamp, inSameDayAs: currentDate) }
            result.append((date: currentDate, count: dayPouches.count))
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        return result
    }
    
    func getHourlyStatsForLast24Hours() -> [(hour: Int, count: Int)] {
        let calendar = Calendar.current
        let now = Date()
        var result: [(hour: Int, count: Int)] = []
        
        for hourOffset in (0..<24).reversed() {
            guard let date = calendar.date(byAdding: .hour, value: -hourOffset, to: now) else { continue }
            let hour = calendar.component(.hour, from: date)
            let hourStart = calendar.startOfDay(for: date).addingTimeInterval(TimeInterval(hour * 3600))
            let hourEnd = hourStart.addingTimeInterval(3600)
            
            let count = pouches.filter { $0.timestamp >= hourStart && $0.timestamp < hourEnd }.count
            result.append((hour: hour, count: count))
        }
        
        return result
    }
    
    func getUsedStrengths() -> [Int] {
        var counts: [Int: Int] = [:]
        for pouch in pouches {
            counts[pouch.strength, default: 0] += 1
        }
        
        // Sort by usage count descending, then by strength ascending
        let sorted = counts.sorted { (a, b) in
            if a.value != b.value {
                return a.value > b.value
            }
            return a.key < b.key
        }
        
        return sorted.map { $0.key }
    }
    
    func addCustomStrength(_ strength: Int) {
        if !settings.customStrengths.contains(strength) {
            settings.customStrengths.append(strength)
            settings.customStrengths.sort()
            saveSettings()
        }
    }
    
    func removeCustomStrength(_ strength: Int) {
        settings.customStrengths.removeAll { $0 == strength }
        saveSettings()
    }
}

struct AppSettings: Codable {
    var dailyLimit: Int = 10
    var languageCode: String = ""
    var themeColor: String = "blue"
    var customStrengths: [Int] = []
}

enum StatsPeriod: String, CaseIterable, Identifiable {
    case day24 = "24h"
    case week1 = "1W"
    case month1 = "1M"
    case year1 = "1Y"
    case all = "All"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .day24: return "24h"
        case .week1: return "1W"
        case .month1: return "1M"
        case .year1: return "1Y"
        case .all: return "All"
        }
    }
}
