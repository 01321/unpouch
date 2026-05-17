import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) var dismiss
    
    @State private var dailyLimit: Int = 5
    @State private var resetHour: Int = 1
    @State private var selectedLanguage: String = "en"
    
    let languages = [
        "en": "English",
        "pl": "Polski",
        "de": "Deutsch"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("daily_limit")) {
                    Stepper(value: $dailyLimit, in: 1...50) {
                        Text("\(dailyLimit) pouches")
                    }
                }
                
                Section(header: Text("reset_time")) {
                    Menu {
                        ForEach(0..<24, id: \.self) { hour in
                            Button(action: {
                                resetHour = hour
                            }) {
                                HStack {
                                    Text(String(format: "%02d:00", hour))
                                    if hour == resetHour {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(String(format: "%02d:00", resetHour))
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section(header: Text("language")) {
                    Picker("language", selection: $selectedLanguage) {
                        ForEach(languages.keys.sorted(), id: \.self) { key in
                            Text(languages[key] ?? key).tag(key)
                        }
                    }
                }
            }
            .navigationTitle("settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("done") {
                        saveSettings()
                        dismiss()
                    }
                }
            }
            .onAppear {
                dailyLimit = dataStore.settings.dailyLimit
                resetHour = dataStore.settings.resetHour
                selectedLanguage = dataStore.settings.language
            }
        }
    }
    
    func saveSettings() {
        dataStore.updateSettings(dailyLimit: dailyLimit, resetHour: resetHour, language: selectedLanguage)
    }
}
