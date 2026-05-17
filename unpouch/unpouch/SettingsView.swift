import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) var dismiss
    
    @State private var dailyLimit: Int = 10
    @State private var resetHour: Int = 1
    @State private var selectedLanguage: String = "en"
    
    let languages = [
        ("en", "English"),
        ("pl", "Polski"),
        ("de", "Deutsch")
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("daily_limit_setting")) {
                    Stepper(value: $dailyLimit, in: 1...50) {
                        HStack {
                            Text("limit_value")
                            Text("\(dailyLimit)")
                                .fontWeight(.bold)
                        }
                    }
                }
                
                Section(header: Text("reset_time_setting")) {
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
                            Text("reset_time_label")
                            Spacer()
                            Text(String(format: "%02d:00", resetHour))
                                .foregroundColor(.gray)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Section(header: Text("language_setting")) {
                    Picker("language", selection: $selectedLanguage) {
                        ForEach(languages, id: \.0) { code, name in
                            Text(name).tag(code)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
            .navigationTitle("settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("done") {
                        saveSettings()
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
            .onAppear {
                dailyLimit = dataStore.settings.dailyLimit
                resetHour = dataStore.settings.resetHour
                selectedLanguage = dataStore.settings.language
            }
        }
    }
    
    private func saveSettings() {
        dataStore.updateSettings(
            dailyLimit: dailyLimit,
            resetHour: resetHour,
            language: selectedLanguage
        )
    }
}
