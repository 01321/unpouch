import WidgetKit
import SwiftUI

struct PouchEntry: TimelineEntry {
    let date: Date
    let count: Int
}

struct SimplePouchProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> PouchEntry {
        PouchEntry(date: Date(), count: 0)
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> PouchEntry {
        PouchEntry(date: Date(), count: 5) // Przykładowa wartość dla podglądu
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<PouchEntry> {
        // Pobierz aktualną liczbę pouchy z wspólnego źródła danych
        let sharedDefaults = UserDefaults(suiteName: "group.twoj.nazwa.aplikacji")
        let count = sharedDefaults?.integer(forKey: "pouchCount") ?? 0
        
        let entry = PouchEntry(date: Date(), count: count)
        return Timeline(entries: [entry], policy: .atEnd)
    }
}

struct PouchWidgetEntryView: View {
    var entry: PouchEntry
    
    var body: some View {
        Link(destination: AddPouchIntent()) { // Kliknięcie uruchamia intent
            VStack(spacing: 8) {
                Image(systemName: "bag.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.accentColor)
                
                Text("\(entry.count)")
                    .font(.system(size: 40, weight: .bold))
                
                Text("Pouchy")
                    .font(.caption)
            }
            .containerBackground(.fill.tertiary, for: .widget)
        }
    }
}

@main
struct PouchWidget: Widget {
    let kind: String = "PouchWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: SimplePouchProvider()) { entry in
            PouchWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Licznik Pouchy")
        .description("Widget pozwalający szybko dodać poucha z ekranu blokady.")
        .supportedFamilies([.systemSmall]) // Rozmiar widgeta
    }
}
