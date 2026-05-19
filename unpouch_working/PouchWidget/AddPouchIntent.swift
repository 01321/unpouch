import WidgetKit
import AppIntents
import Foundation

// Definicja intencji dodawania poucha
struct AddPouchIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Pouch"
    static var description = IntentDescription("Adds one pouch to the counter, just like the Add Pouch button in the main app.")
    static var openAppWhenRun: Bool = false
    
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
        
        // Dodaj nowego poucha
        let newPouch = Pouch(date: Date(), strength: strength)
        pouches.append(newPouch)
        
        // Zapisz z powrotem
        if let encodedPouches = try? JSONEncoder().encode(pouches) {
            sharedDefaults.set(encodedPouches, forKey: "saved_pouches")
        }
        
        // Odśwież widget
        WidgetCenter.shared.reloadTimelines(ofKind: "PouchWidget")
        
        return .result()
    }
}

// Struktury muszą być dostępne w module widgetu - kopie z Models.swift
struct Pouch: Codable, Identifiable {
    let id = UUID()
    let date: Date
    let strength: Int
}
