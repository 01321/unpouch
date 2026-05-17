import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header Stats
                VStack(spacing: 8) {
                    Text("TODAY")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.gray)
                    
                    let stats = dataStore.getTodayStats()
                    
                    Text("\(stats.count)")
                        .font(.system(size: 60, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("\(stats.totalMg) mg")
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundColor(.blue)
                    
                    // Limit indicator
                    if stats.totalMg > dataStore.settings.dailyLimit {
                        Text("⚠️ Over limit!")
                            .font(.headline)
                            .foregroundColor(.red)
                    } else {
                        Text("✅ Within limit")
                            .font(.headline)
                            .foregroundColor(.green)
                    }
                }
                .padding(.top, 20)
                
                Spacer()
                
                // Controls
                VStack(spacing: 20) {
                    // Strength selector
                    HStack {
                        Text("Current Strength:")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Button(action: {
                            showingStrengthPicker = true
                        }) {
                            Text("\(dataStore.currentStrength) mg")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.blue.opacity(0.8))
                                .cornerRadius(10)
                        }
                    }
                    
                    // Main Add Button
                    Button(action: {
                        dataStore.addPouch(strength: dataStore.currentStrength)
                    }) {
                        ZStack {
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.blue]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .cornerRadius(25)
                            .shadow(color: .blue.opacity(0.4), radius: 10, x: 0, y: 5)
                            
                            VStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 50))
                                Text("ADD POUCH")
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(.white)
                        }
                        .frame(height: 180)
                        .padding(.horizontal, 40)
                    }
                    
                    // Remove Button
                    Button(action: {
                        dataStore.removeLastPouch()
                    }) {
                        HStack {
                            Image(systemName: "minus.circle.fill")
                            Text("Remove Last")
                        }
                        .font(.headline)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(15)
                    }
                }
                
                Spacer()
            }
            .navigationTitle("unpouch.")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingStrengthPicker) {
                StrengthPickerView()
            }
        }
    }
    
    @State private var showingStrengthPicker = false
}

struct StrengthPickerView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) var dismiss
    
    let strengths = Array(stride(from: 0, through: 100, by: 10))
    
    var body: some View {
        NavigationView {
            List(strengths, id: \.self) { strength in
                Button(action: {
                    dataStore.currentStrength = strength
                    dismiss()
                }) {
                    HStack {
                        Text("\(strength) mg")
                            .font(.title2)
                        Spacer()
                        if strength == dataStore.currentStrength {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Select Strength")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(DataStore())
}
