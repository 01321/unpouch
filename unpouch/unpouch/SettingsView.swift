import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(NSLocalizedString("daily_limit", comment: ""))) {
                    Stepper(value: $dataStore.settings.dailyLimitCount, in: 1...50) {
                        Text("\(dataStore.settings.dailyLimitCount) \(NSLocalizedString("pouches", comment: ""))")
                    }
                }
                
                Section(header: Text(NSLocalizedString("reset_time", comment: ""))) {
                    Picker(NSLocalizedString("hour", comment: ""), selection: $dataStore.settings.resetHour) {
                        ForEach(0..<24) { hour in
                            Text(String(format: "%02d:00", hour)).tag(hour)
                        }
                    }
                    .pickerStyle(.wheel)
                    .labelsHidden()
                    .frame(height: 120)
                }
                
                Section(header: Text(NSLocalizedString("language", comment: ""))) {
                    Picker(NSLocalizedString("language", comment: ""), selection: $dataStore.settings.languageCode) {
                        ForEach(Settings.Languages.allCases) { lang in
                            Text(lang.displayName).tag(lang.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .navigationTitle(NSLocalizedString("settings", comment: ""))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("done", comment: "")) {
                        dismiss()
                    }
                }
            }
            .onChange(of: dataStore.settings) { _, _ in
                dataStore.save()
            }
        }
    }
}
