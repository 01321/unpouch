import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) var dismiss
    
    @State private var dailyLimit: Int = 50
    @State private var resetHour: Int = 6
    @State private var resetMinute: Int = 0
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Daily Limit")) {
                    Stepper(value: $dailyLimit, in: 0...200, step: 5) {
                        Text("\(dailyLimit) mg")
                    }
                }
                
                Section(header: Text("Reset Time")) {
                    Picker("Hour", selection: $resetHour) {
                        ForEach(0..<24) { hour in
                            Text(String(format: "%02d", hour)).tag(hour)
                        }
                    }
                    .pickerStyle(.wheel)
                    
                    Picker("Minute", selection: $resetMinute) {
                        ForEach(0..<60, id: \.self) { minute in
                            Text(String(format: "%02d", minute)).tag(minute)
                        }
                    }
                    .pickerStyle(.wheel)
                }
                
                Section(footer: Text("Settings are saved automatically.")) {
                    EmptyView()
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        saveSettings()
                        dismiss()
                    }
                }
            }
            .onAppear {
                dailyLimit = dataStore.settings.dailyLimit
                resetHour = dataStore.settings.resetHour
                resetMinute = dataStore.settings.resetMinute
            }
        }
    }
    
    private func saveSettings() {
        dataStore.updateSettings(dailyLimit: dailyLimit, resetHour: resetHour, resetMinute: resetMinute)
    }
}

#Preview {
    SettingsView()
        .environmentObject(DataStore())
}
