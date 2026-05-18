import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Default Strength")) {
                    Picker("Default Strength", selection: $dataStore.settings.defaultStrength) {
                        ForEach(dataStore.getAvailableStrengths(), id: \.self) { strength in
                            Text("\(strength)mg").tag(strength)
                        }
                    }
                }
                
                Section(header: Text("Daily Limit")) {
                    Stepper(value: $dataStore.settings.dailyLimit, in: 5...50, step: 5) {
                        Text("\(dataStore.settings.dailyLimit) pouches")
                    }
                }
                
                Section(header: Text("Language")) {
                    Picker("Language", selection: $dataStore.settings.languageCode) {
                        ForEach(languages, id: \.code) { language in
                            Text(language.name).tag(language.code)
                        }
                    }
                    .onChange(of: dataStore.settings.languageCode) { _ in
                        dataStore.saveSettings()
                    }
                }
                
                Section(header: Text("Theme Color")) {
                    Picker("Theme Color", selection: $dataStore.settings.themeColor) {
                        ForEach(colorOptions, id: \.code) { colorOption in
                            HStack {
                                Circle()
                                    .fill(colorOption.color)
                                    .frame(width: 20, height: 20)
                                Text(colorOption.name)
                            }
                            .tag(colorOption.code)
                        }
                    }
                }
                
                Section(header: Text("Custom Strengths")) {
                    ForEach(dataStore.customStrengths, id: \.self) { strength in
                        HStack {
                            Text("\(strength)mg")
                            Spacer()
                            Button("Delete", role: .destructive) {
                                dataStore.customStrengths.removeAll { $0 == strength }
                            }
                        }
                    }
                    
                    Button(action: addCustomStrength) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Custom Strength")
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    func addCustomStrength() {
        // This would ideally show an alert to input the strength
        // For simplicity, we'll just add a default custom value
        dataStore.addCustomStrength(15)
    }
}

#Preview {
    SettingsView()
        .environmentObject(DataStore())
}
