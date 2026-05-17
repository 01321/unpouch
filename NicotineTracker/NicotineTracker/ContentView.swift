//
//  ContentView.swift
//  NicotineTracker
//
//  Created by Assistant on 2024.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var store = DataStore()
    @State private var showingStrengthPicker = false
    @State private var selectedStrength: Int = 10
    @State private var showingSettings = false
    
    let strengths = Array(stride(from: 0, through: 100, by: 10))
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Summary Section
                VStack(spacing: 10) {
                    HStack {
                        VStack {
                            Text("Dzisiaj")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("\(store.todayTotalCount)")
                                .font(.system(size: 48, weight: .bold))
                            Text("saszetek")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Divider()
                            .frame(height: 60)
                        
                        VStack {
                            Text("Łącznie")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("\(store.todayTotalMg) mg")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(store.isOverLimit ? .red : .green)
                            Text("nikotyny")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    
                    // Limit indicator
                    HStack {
                        Image(systemName: store.isOverLimit ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                            .foregroundColor(store.isOverLimit ? .red : .green)
                        Text(store.isOverLimit ? "Przekroczono limit!" : "W limicie")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        Text("Limit: \(store.settings.dailyLimitMg) mg")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 20) {
                    HStack(spacing: 20) {
                        // Remove button (smaller)
                        Button(action: {
                            store.removeLastEntry()
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.red)
                        }
                        .disabled(store.todayTotalCount == 0)
                        .opacity(store.todayTotalCount == 0 ? 0.5 : 1.0)
                        
                        // Add button (large)
                        Button(action: {
                            showingStrengthPicker = true
                        }) {
                            VStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 80))
                                Text("Dodaj saszetkę")
                                    .font(.headline)
                            }
                            .foregroundColor(.blue)
                        }
                        
                        // Settings button (smaller)
                        NavigationLink(destination: SettingsView(store: store)) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.bottom, 40)
                
                Spacer()
            }
            .navigationTitle("Nicotine Tracker")
            .confirmationDialog(
                "Wybierz moc saszetki",
                isPresented: $showingStrengthPicker,
                titleVisibility: .visible
            ) {
                ForEach(strengths, id: \.self) { strength in
                    Button("\(strength) mg") {
                        selectedStrength = strength
                        store.addEntry(strengthMg: strength)
                    }
                }
                Button("Anuluj", role: .cancel) {}
            }
        }
    }
}

#Preview {
    ContentView()
}
