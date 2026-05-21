import WidgetKit
import AppIntents
import Foundation

// Struktury muszą być dostępne w module widgetu - kopie z Models.swift
struct Pouch: Codable, Identifiable {
    let id = UUID()
    let date: Date
    let strength: Int
}

// Definicja intencji dodawania poucha
struct AddPouchIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Pouch"
    static var description = IntentDescription("Adds one pouch to the counter, just like the Add Pouch button in the main app.")
    static var openAppWhenRun: Bool = true
    static var isDiscoverable: Bool = false
    
    @Parameter(title: "Strength", default: 10)
    var strength: Int
    
    func perform() async throws -> some IntentResult {
        // Użyj App Group do współdzielenia danych między aplikacją a widgetem
        guard let sharedDefaults = UserDefaults(suiteName: "group.unpouch.shared") else {
            return .result()
        }
        
        // Pobierz aktualne dane
        let savedPouches = sharedDefaults.data(forKey: "saved_pouches")
        var pouches: [Pouch] = []
        
        if let savedPouches = savedPouches,
           let decodedPouches = try? JSONDecoder().decode([Pouch].self, from: savedPouches) {
            pouches = decodedPouches
        }
        
        // Pobierz ustawienia aby uzyskać currentStrength
        var currentStrength = 10
        if let savedSettings = sharedDefaults.data(forKey: "saved_settings"),
           let decodedSettings = try? JSONDecoder().decode(Settings.self, from: savedSettings) {
            currentStrength = decodedSettings.currentStrength
        }
        
        // Dodaj nowego poucha z aktualną mocą
        let newPouch = Pouch(date: Date(), strength: currentStrength)
        pouches.append(newPouch)
        
        // Zapisz z powrotem
        if let encodedPouches = try? JSONEncoder().encode(pouches) {
            sharedDefaults.set(encodedPouches, forKey: "saved_pouches")
        }
        
        // Wymuś odświeżenie widgetu poprzez zmianę daty
        let now = Date()
        sharedDefaults.set(now.timeIntervalSince1970, forKey: "last_pouch_added_timestamp")
        
        return .result()
    }
}
