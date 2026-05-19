import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) var dismiss
    
    @State private var dailyLimit: Int = 10
    @State private var resetHour: Int = 1
    @State private var selectedLanguage: String = "en"
    @State private var showResetPicker = false
    @State private var showColorPicker = false
    @State private var selectedAccentColor: String = "blue"
    
    let languages = ["en", "pl", "de"]
    let languageNames = ["English", "Polski", "Deutsch"]
    
    let colorOptions: [(name: String, code: String, color: Color)] = [
        ("blue", "blue", .blue),
        ("red", "red", .red),
        ("green", "green", .green),
        ("purple", "purple", .purple),
        ("orange", "orange", .orange),
        ("pink", "pink", .pink)
    ]
    
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
                    .onChange(of: selectedLanguage) { _ in
                        saveSettings()
                    }
                }
                
                Section(header: Text("accent_color_header")) {
                    VStack(spacing: 12) {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(colorOptions, id: \.code) { colorOption in
                                Button(action: {
                                    withAnimation {
                                        selectedAccentColor = colorOption.code
                                        dataStore.updateAccentColor(colorOption.code)
                                    }
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(colorOption.color)
                                            .frame(width: 50, height: 50)
                                        
                                        if dataStore.settings.accentColor == colorOption.code {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.white)
                                                .fontWeight(.bold)
                                        }
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("danger_zone_header")) {
                    Button(action: {
                        dataStore.clearAllData()
                    }) {
                        HStack {
                            Image(systemName: "trash.fill")
                                .foregroundColor(.red)
                            Text("clear_all_data")
                                .foregroundColor(.red)
                        }
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
                selectedAccentColor = dataStore.settings.accentColor
            }
        }
    }
    
    private func saveSettings() {
        dataStore.updateSettings(dailyLimit: dailyLimit, resetHour: resetHour, language: selectedLanguage)
        
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
