import Foundation
import Combine

class DataStore: ObservableObject {
    // Published properties will automatically notify views of changes
    @Published var pouches: [Pouch] = []
    @Published var settings: Settings = Settings()
    @Published var currentStrength: Int = 10 // Default strength
    
    private let pouchesKey = "saved_pouches"
    private let settingsKey = "saved_settings"
    private let strengthKey = "saved_strength"
    
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
    
    func updateSettings(dailyLimit: Int, resetHour: Int, resetMinute: Int) {
        settings.dailyLimit = dailyLimit
        settings.resetHour = resetHour
        settings.resetMinute = resetMinute
        save()
    }
    
    func getTodayStats() -> (count: Int, totalMg: Int) {
        let now = Date()
        let calendar = Calendar.current
        
        // Find the last reset time
        var lastResetComponents = calendar.dateComponents([.year, .month, .day], from: now)
        lastResetComponents.hour = settings.resetHour
        lastResetComponents.minute = settings.resetMinute
        lastResetComponents.second = 0
        
        guard var lastResetDate = calendar.date(from: lastResetComponents) else {
            return (0, 0)
        }
        
        // If the reset time for today hasn't happened yet, use yesterday's reset
        if now < lastResetDate {
            lastResetDate = calendar.date(byAdding: .day, value: -1, to: lastResetDate)!
        }
        
        let todaysPouches = pouches.filter { $0.date >= lastResetDate }
        
        let count = todaysPouches.count
        let totalMg = todaysPouches.reduce(0) { $0 + $1.strength }
        
        return (count, totalMg)
    }
    
    func save() {
        if let encodedPouches = try? JSONEncoder().encode(pouches) {
            UserDefaults.standard.set(encodedPouches, forKey: pouchesKey)
        }
        if let encodedSettings = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encodedSettings, forKey: settingsKey)
        }
        UserDefaults.standard.set(currentStrength, forKey: strengthKey)
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
        
        currentStrength = UserDefaults.standard.integer(forKey: strengthKey)
        if currentStrength == 0 {
            currentStrength = 10 // Default if not set
        }
    }
}
