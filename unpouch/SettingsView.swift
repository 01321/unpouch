//
//  SettingsView.swift
//  unpouch
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) var dismiss
    
    @State private var dailyLimitMg: Int = 40
    @State private var resetHour: Int = 6
    @State private var resetMinute: Int = 0
    
    let availableHours = Array(0...23)
    let availableMinutes = Array(stride(from: 0, through: 55, by: 5))
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Daily Limit")) {
                    Stepper(value: $dailyLimitMg, in: 0...500, step: 5) {
                        HStack {
                            Text("Daily Limit")
                            Spacer()
                            Text("\(dailyLimitMg) mg")
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Section(header: Text("Reset Time")) {
                    HStack {
                        Text("Reset at")
                        Spacer()
                        Picker("Hour", selection: $resetHour) {
                            ForEach(availableHours, id: \.self) { hour in
                                Text(String(format: "%02d", hour)).tag(hour)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 80)
                        
                        Text(":")
                        
                        Picker("Minute", selection: $resetMinute) {
                            ForEach(availableMinutes, id: \.self) { minute in
                                Text(String(format: "%02d", minute)).tag(minute)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 80)
                    }
                }
                
                Section {
                    Text("Settings are saved automatically.")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        saveSettings()
                        dismiss()
                    }
                }
            }
            .onAppear {
                dailyLimitMg = dataStore.settings.dailyLimitMg
                resetHour = dataStore.settings.resetHour
                resetMinute = dataStore.settings.resetMinute
            }
        }
    }
    
    private func saveSettings() {
        dataStore.updateSettings(
            dailyLimitMg: dailyLimitMg,
            resetHour: resetHour,
            resetMinute: resetMinute
        )
    }
}

#Preview {
    SettingsView()
        .environmentObject(DataStore())
}
