import WidgetKit
import AppIntents

// Definicja intencji
struct AddPouchIntent: AppIntent {
    static var title: LocalizedStringResource = "Dodaj Pouch"
    static var description = IntentDescription("Dodaje jeden pouch do licznika.")
    static var openAppWhenRun: Bool = true // Opcjonalnie otwiera aplikację po wykonaniu

    func perform() async throws -> some IntentResult {
        // TUTAJ MUSISZ UMIEŚCIĆ LOGIKĘ DODAWANIA
        // Ponieważ widget działa w innym procesie, musisz zapisać dane w miejscu wspólnym,
        // np. UserDefaults z App Group lub bezpośrednio w modelu, jeśli jest to możliwe.
        
        // Przykład z UserDefaults (wymaga włączenia App Groups w Signing & Capabilities):
        let sharedDefaults = UserDefaults(suiteName: "group.twoj.nazwa.aplikacji")
        let currentCount = sharedDefaults?.integer(forKey: "pouchCount") ?? 0
        sharedDefaults?.set(currentCount + 1, forKey: "pouchCount")
        
        // Jeśli używasz własnego modelu (np. StatsModel), musisz go załadować i zapisać tutaj.
        // Przykład dla prostego modelu w pamięci (wymaga reloadowania w main app):
        // StatsModel.shared.addPouch()

        return .result()
    }
    
    // Statyczne podgląd dla widgeta (opcjonalne)
    static var parameterSummary: some ParameterSummary {
        Summary("Dodaj \(\.$pouchAmount) pouchy")
    }
}
