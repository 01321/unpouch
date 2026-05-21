import WidgetKit
import SwiftUI

struct PouchEntry: TimelineEntry {
    let date: Date
    let count: Int
    let totalMg: Int
}

struct SimplePouchProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> PouchEntry {
        PouchEntry(date: Date(), count: 0, totalMg: 0)
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> PouchEntry {
        return await timeline(for: configuration, in: context).entries.first ?? PouchEntry(date: Date(), count: 0, totalMg: 0)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<PouchEntry> {
        guard let sharedDefaults = UserDefaults(suiteName: "group.unpouch.shared") else {
            let entry = PouchEntry(date: Date(), count: 0, totalMg: 0)
            return Timeline(entries: [entry], policy: .atEnd)
        }
        
        let savedPouches = sharedDefaults.data(forKey: "saved_pouches")
        var pouches: [Pouch] = []
        
        if let savedPouches = savedPouches,
           let decodedPouches = try? JSONDecoder().decode([Pouch].self, from: savedPouches) {
            pouches = decodedPouches
        }
        
        // Oblicz statystyki z dzisiaj (podobnie jak w DataStore)
        let now = Date()
        let calendar = Calendar.current
        
        // Pobierz resetHour z settings
        let savedSettings = sharedDefaults.data(forKey: "saved_settings")
        var resetHour = 1 // default
        if let savedSettings = savedSettings,
           let decodedSettings = try? JSONDecoder().decode(Settings.self, from: savedSettings) {
            resetHour = decodedSettings.resetHour
        }
        
        var lastResetComponents = calendar.dateComponents([.year, .month, .day], from: now)
        lastResetComponents.hour = resetHour
        lastResetComponents.minute = 0
        lastResetComponents.second = 0
        
        guard var lastResetDate = calendar.date(from: lastResetComponents) else {
            let entry = PouchEntry(date: Date(), count: 0, totalMg: 0)
            return Timeline(entries: [entry], policy: .atEnd)
        }
        
        if now < lastResetDate {
            lastResetDate = calendar.date(byAdding: .day, value: -1, to: lastResetDate)!
        }
        
        let todaysPouches = pouches.filter { $0.date >= lastResetDate }
        let count = todaysPouches.count
        let totalMg = todaysPouches.reduce(0) { $0 + $1.strength }
        
        let entry = PouchEntry(date: Date(), count: count, totalMg: totalMg)
        
        // Ustaw odświeżanie co minutę aby widget aktualizował się na bieżąco
        // lub gdy dodany zostanie nowy pouch (poprzez zmianę last_pouch_added_timestamp)
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 1, to: now) ?? Date().addingTimeInterval(60)
        return Timeline(entries: [entry], policy: .after(nextRefresh))
    }
}

struct PouchWidgetEntryView: View {
    var entry: PouchEntry
    var family: WidgetFamily
    
    var body: some View {
        Button(action: {
            Task {
                do {
                    try await AddPouchIntent().perform()
                } catch {
                    print("Failed to add pouch: \(error)")
                }
            }
        }) {
            if family == .accessoryCircular {
                // Mały okrągły widget na ekranie blokady
                VStack(spacing: 0) {
                    Text("\(entry.count)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                    Text("pouches")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary)
                }
            } else {
                // Standardowy widget na pulpicie
                VStack(spacing: 8) {
                    Image(systemName: "bag.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.accentColor)
                    
                    Text("\(entry.count)")
                        .font(.system(size: 40, weight: .bold))
                    
                    Text("\(entry.totalMg) mg")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .containerBackground(.fill.tertiary, for: .widget)
            }
        }
    }
}

// Struktury muszą być dostępne w module widgetu
struct Settings: Codable {
    var dailyLimit: Int = 10
    var resetHour: Int = 1
    var language: String = "en"
    var currentStrength: Int = 10
    var customStrengths: [Int] = []
    var accentColor: String = "blue"
}

struct PouchWidget: Widget {
    let kind: String = "PouchWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: SimplePouchProvider()) { entry in
            PouchWidgetEntryView(entry: entry, family: .accessoryCircular)
        }
        .configurationDisplayName("Pouch Counter")
        .description("Widget that shows your daily pouch count and allows adding a pouch with one tap.")
        .supportedFamilies([.accessoryCircular])
    }
}

// Drugi widget na pulpit (jeśli potrzebny)
struct PouchWidgetHome: Widget {
    let kind: String = "PouchWidgetHome"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: SimplePouchProvider()) { entry in
            PouchWidgetEntryView(entry: entry, family: .systemSmall)
        }
        .configurationDisplayName("Pouch Counter (Home)")
        .description("Widget that shows your daily pouch count on the home screen.")
        .supportedFamilies([.systemSmall])
    }
}
