import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) var dismiss
    
    @State private var dailyLimit: Int = 10
    @State private var resetHour: Int = 1
    @State private var selectedLanguage: String = "en"
    @State private var showResetPicker = false
    
    let languages = ["en", "pl", "de"]
    let languageNames = ["English", "Polski", "Deutsch"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("daily_limit_header")) {
                    Stepper(value: $dailyLimit, in: 1...50) {
                        HStack {
                            Text("daily_limit_value")
                            Spacer()
                            Text("\(dailyLimit)")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section(header: Text("reset_time_header")) {
                    Button(action: { showResetPicker = true }) {
                        HStack {
                            Text("reset_time")
                            Spacer()
                            Text(String(format: "%02d:00", resetHour))
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .confirmationDialog("select_reset_time", isPresented: $showResetPicker) {
                        ForEach(0..<24, id: \.self) { hour in
                            Button(String(format: "%02d:00", hour)) {
                                resetHour = hour
                            }
                        }
                    }
                }
                
                Section(header: Text("language_header")) {
                    Picker("language", selection: $selectedLanguage) {
                        ForEach(0..<languages.count, id: \.self) { index in
                            Text(languageNames[index]).tag(languages[index])
                        }
                    }
                    .onChange(of: selectedLanguage) { newLanguage in
                        saveSettings()
                    }
                }
            }
            .navigationTitle("settings")
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
        dataStore.updateSettings(dailyLimit: dailyLimit, resetHour: resetHour, language: selectedLanguage)
        
        // Force update of the app's locale
        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            UserDefaults.standard.set([selectedLanguage], forKey: "AppleLanguages")
            UserDefaults.standard.synchronize()
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(DataStore())
}
