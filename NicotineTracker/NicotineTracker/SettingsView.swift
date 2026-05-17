//
//  SettingsView.swift
//  NicotineTracker
//
//  Created by Assistant on 2024.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: DataStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var resetHour: Int = 6
    @State private var dailyLimitMg: Int = 100
    
    let hours = Array(0...23)
    
    var body: some View {
        Form {
            Section(header: Text("Reset licznika")) {
                Picker("Godzina resetu", selection: $resetHour) {
                    ForEach(hours, id: \.self) { hour in
                        Text("\(hour):00").tag(hour)
                    }
                }
                .pickerStyle(.wheel)
                
                Text("Licznik będzie resetowany codziennie o \(resetHour):00")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section(header: Text("Dzienny limit")) {
                Stepper(value: $dailyLimitMg, in: 0...500, step: 10) {
                    HStack {
                        Text("Limit dzienny:")
                        Spacer()
                        Text("\(dailyLimitMg) mg")
                            .fontWeight(.semibold)
                    }
                }
                
                Text("Ostrzeżenie pojawi się, gdy przekroczysz tę wartość")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section {
                Button("Zapisz ustawienia") {
                    store.updateSettings(resetHour: resetHour, dailyLimitMg: dailyLimitMg)
                    dismiss()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Ustawienia")
        .onAppear {
            resetHour = store.settings.resetHour
            dailyLimitMg = store.settings.dailyLimitMg
        }
    }
}

#Preview {
    NavigationView {
        SettingsView(store: DataStore())
    }
}
