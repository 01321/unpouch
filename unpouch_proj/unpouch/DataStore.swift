import SwiftUI
import Combine

class DataStore: ObservableObject {
    @Published var pouches: [Pouch] = [] {
        didSet { savePouches() }
    }
    
    @Published var settings: AppSettings = AppSettings() {
        didSet { saveSettings() }
    }
    
    @Published var customStrengths: [Int] = [] {
        didSet { saveCustomStrengths() }
    }
    
    private let pouchesKey = "saved_pouches"
    private let settingsKey = "app_settings"
    private let customStrengthsKey = "custom_strengths"
    
    init() {
        loadPouches()
        loadSettings()
        loadCustomStrengths()
    }
    
    func addPouch(strength: Int? = nil, date: Date = Date()) {
        let finalStrength = strength ?? settings.defaultStrength
        let pouch = Pouch(id: UUID(), strength: finalStrength, date: date)
        pouches.append(pouch)
    }
    
    func removePouch(at offsets: IndexSet, for period: StatsPeriod) {
        pouches.remove(atOffsets: offsets)
    }
    
    func getStatsForPeriod(_ period: StatsPeriod) -> [Double] {
        let now = Date()
        let calendar = Calendar.current
        var startDate: Date
        
        switch period {
        case .day24:
            startDate = calendar.date(byAdding: .hour, value: -24, to: now)!
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: now)!
        case .month:
            startDate = calendar.date(byAdding: .day, value: -30, to: now)!
        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: now)!
        case .all:
            startDate = Date.distantPast
        }
        
        let filteredPouches = pouches.filter { $0.date >= startDate }
        
        var stats: [Double] = []
        
        switch period {
        case .day24:
            for hour in 0..<24 {
                let hourStart = calendar.date(byAdding: .hour, value: -(23 - hour), to: startDate)!
                let hourEnd = calendar.date(byAdding: .hour, value: 1, to: hourStart)!
                let count = Double(filteredPouches.filter { $0.date >= hourStart && $0.date < hourEnd }.count)
                stats.append(count)
            }
        case .week:
            for day in 0..<7 {
                let dayStart = calendar.date(byAdding: .day, value: -(6 - day), to: startDate)!
                let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
                let count = Double(filteredPouches.filter { $0.date >= dayStart && $0.date < dayEnd }.count)
                stats.append(count)
            }
        case .month:
            for day in 0..<30 {
                let dayStart = calendar.date(byAdding: .day, value: -(29 - day), to: startDate)!
                let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
                let count = Double(filteredPouches.filter { $0.date >= dayStart && $0.date < dayEnd }.count)
                stats.append(count)
            }
        case .year:
            for month in 0..<12 {
                let monthStart = calendar.date(byAdding: .month, value: -(11 - month), to: startDate)!
                let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart)!
                let count = Double(filteredPouches.filter { $0.date >= monthStart && $0.date < monthEnd }.count)
                stats.append(count)
            }
        case .all:
            let total = Double(filteredPouches.count)
            stats.append(total)
        }
        
        return stats
    }
    
    func getTotalNicotineForPeriod(_ period: StatsPeriod) -> Double {
        let now = Date()
        let calendar = Calendar.current
        var startDate: Date
        
        switch period {
        case .day24:
            startDate = calendar.date(byAdding: .hour, value: -24, to: now)!
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: now)!
        case .month:
            startDate = calendar.date(byAdding: .day, value: -30, to: now)!
        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: now)!
        case .all:
            startDate = Date.distantPast
        }
        
        let filteredPouches = pouches.filter { $0.date >= startDate }
        let totalMg = Double(filteredPouches.reduce(0) { $0 + $1.strength })
        return totalMg / 1000.0 // Convert to grams
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
    
    private func saveSettings() {
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: settingsKey)
        }
        
        // Apply language settings immediately
        if let index = languages.firstIndex(where: { $0.code == settings.languageCode }) {
            let lang = languages[index]
            UserDefaults.standard.set([lang.code], forKey: "AppleLanguages")
            UserDefaults.standard.synchronize()
        }
    }
    
    private func loadSettings() {
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            settings = decoded
        }
    }
    
    private func saveCustomStrengths() {
        UserDefaults.standard.set(customStrengths, forKey: customStrengthsKey)
    }
    
    private func loadCustomStrengths() {
        if let saved = UserDefaults.standard.array(forKey: customStrengthsKey) as? [Int] {
            customStrengths = saved
        }
    }
    
    func addCustomStrength(_ strength: Int) {
        if !customStrengths.contains(strength) {
            customStrengths.append(strength)
            customStrengths.sort()
        }
    }
    
    func removeCustomStrength(_ strength: Int) {
        customStrengths.removeAll { $0 == strength }
    }
    
    func getAvailableStrengths() -> [Int] {
        var allStrengths = [10, 20, 30, 40, 50, 60, 70, 80, 90, 100]
        
        // Add custom strengths
        for strength in customStrengths {
            if !allStrengths.contains(strength) {
                allStrengths.append(strength)
            }
        }
        
        allStrengths.sort()
        
        // Keep track of usage count for each strength
        var usageCount: [Int: Int] = [:]
        for pouch in pouches {
            usageCount[pouch.strength, default: 0] += 1
        }
        
        // If we have more than 10 options, remove the ones with lowest usage (that are custom or not default)
        if allStrengths.count > 10 {
            // Sort by usage count (ascending), but prioritize keeping defaults if usage is equal
            let sorted = allStrengths.sorted { (a, b) -> Bool in
                let countA = usageCount[a] ?? 0
                let countB = usageCount[b] ?? 0
                
                if countA == countB {
                    // If usage is equal, prefer defaults (10-100 step 10)
                    let isDefaultA = (10...100).contains(a) && a % 10 == 0
                    let isDefaultB = (10...100).contains(b) && b % 10 == 0
                    return !isDefaultA && isDefaultB // Non-defaults come first for removal
                }
                return countA < countB
            }
            
            // Keep top 10 most used
            allStrengths = Array(sorted.suffix(10)).sorted()
        }
        
        return allStrengths
    }
}

// MARK: - Models

struct Pouch: Codable, Identifiable {
    var id: UUID
    var strength: Int // in mg
    var date: Date
    
    init(id: UUID = UUID(), strength: Int, date: Date = Date()) {
        self.id = id
        self.strength = strength
        self.date = date
    }
}

struct AppSettings: Codable {
    var defaultStrength: Int = 10
    var dailyLimit: Int = 20
    var languageCode: String = "en"
    var themeColor: String = "blue"
}

enum StatsPeriod: String, CaseIterable, Identifiable {
    case day24 = "24h"
    case week = "1W"
    case month = "1M"
    case year = "1Y"
    case all = "All"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .day24: return "24h"
        case .week: return "1W"
        case .month: return "1M"
        case .year: return "1Y"
        case .all: return "All"
        }
    }
}

struct Language: Identifiable {
    let id = UUID()
    let name: String
    let code: String
}

let languages: [Language] = [
    Language(name: "English", code: "en"),
    Language(name: "Polski", code: "pl"),
    Language(name: "Deutsch", code: "de"),
    Language(name: "Français", code: "fr"),
    Language(name: "Español", code: "es")
]

struct ColorOption: Identifiable {
    let id = UUID()
    let name: String
    let code: String
    let color: Color
}

let colorOptions: [ColorOption] = [
    ColorOption(name: "Blue", code: "blue", color: .blue),
    ColorOption(name: "Red", code: "red", color: .red),
    ColorOption(name: "Green", code: "green", color: .green),
    ColorOption(name: "Orange", code: "orange", color: .orange),
    ColorOption(name: "Purple", code: "purple", color: .purple),
    ColorOption(name: "Pink", code: "pink", color: .pink)
]
