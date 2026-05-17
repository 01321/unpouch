//
//  ContentView.swift
//  unpouch
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var showingSettings = false
    @State private var showingStrengthPicker = false
    
    let availableStrengths = Array(stride(from: 0, through: 100, by: 10))
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.white]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Today's Summary
                    VStack(spacing: 8) {
                        Text("TODAY")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.gray)
                        
                        Text("\(dataStore.totalPouchesToday)")
                            .font(.system(size: 72, weight: .bold, design: .rounded))
                            .foregroundColor(dataStore.isOverLimit ? .red : .blue)
                        
                        Text("\(dataStore.totalMgToday) mg")
                            .font(.system(size: 32, weight: .semibold, design: .rounded))
                            .foregroundColor(.gray)
                        
                        if dataStore.totalMgToday > 0 {
                            let difference = dataStore.totalMgToday - dataStore.settings.dailyLimitMg
                            let statusText = difference > 0 
                                ? "+\(difference) mg over limit" 
                                : "\(abs(difference)) mg under limit"
                            
                            Text(statusText)
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(difference > 0 ? .red : .green)
                        }
                    }
                    .padding(.top, 20)
                    
                    Spacer()
                    
                    // Main Action Area
                    VStack(spacing: 20) {
                        // Strength Selector
                        Button(action: {
                            showingStrengthPicker.toggle()
                        }) {
                            HStack {
                                Image(systemName: "bolt.fill")
                                    .foregroundColor(.white)
                                Text("\(dataStore.settings.selectedStrengthMg) mg")
                                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.blue.opacity(0.7))
                            .cornerRadius(25)
                        }
                        .confirmationDialog("Select Strength", isPresented: $showingStrengthPicker) {
                            ForEach(availableStrengths, id: \.self) { strength in
                                Button("\(strength) mg") {
                                    dataStore.updateSelectedStrength(strength)
                                }
                            }
                        }
                        
                        // Add Pouch Button (Large)
                        Button(action: {
                            dataStore.addEntry(strengthMg: dataStore.settings.selectedStrengthMg)
                        }) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.blue.opacity(0.9)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 220, height: 220)
                                    .shadow(color: Color.blue.opacity(0.4), radius: 15, x: 0, y: 8)
                                
                                VStack(spacing: 8) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 50))
                                        .foregroundColor(.white)
                                    
                                    Text("ADD POUCH")
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .scaleEffect(/*@START_MENU_TOKEN@*//*@END_MENU_TOKEN@*/)
                        
                        // Remove Button (Smaller)
                        Button(action: {
                            dataStore.removeLastEntry()
                        }) {
                            HStack {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 20))
                                Text("Remove Last")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                            }
                            .foregroundColor(.gray)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(20)
                        }
                        .disabled(dataStore.entries.isEmpty)
                        .opacity(dataStore.entries.isEmpty ? 0.5 : 1.0)
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.gray)
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .environmentObject(dataStore)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(DataStore())
}
