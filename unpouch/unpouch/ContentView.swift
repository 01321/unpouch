import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var showingStats = false
    @State private var showingSettings = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Header: Logo i Ustawienia
                HStack {
                    Text("unpouch.")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                Spacer()
                
                // Sekcja "Today"
                VStack(spacing: 8) {
                    Text(NSLocalizedString("today", comment: ""))
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    let stats = dataStore.getTodayStats()
                    
                    Text("\(stats.count)")
                        .font(.system(size: 60, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("\(stats.totalMg) mg")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 10)
                
                // Status limitu
                let status = dataStore.getLimitStatus()
                Text(status.text)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(status.color.opacity(0.15))
                    .foregroundColor(status.color)
                    .cornerRadius(20)
                
                Spacer()
                
                // Kontrolki
                VStack(spacing: 25) {
                    // Wybór mocy
                    HStack {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(.blue)
                        
                        Picker("", selection: $dataStore.settings.currentStrength) {
                            ForEach(Array(stride(from: 0, through: 100, by: 10)), id: \.self) { strength in
                                Text("\(strength) mg").tag(strength)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        .font(.headline)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Przyciski akcji
                    HStack(spacing: 20) {
                        Button(action: { dataStore.removeLastPouch() }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.red.opacity(0.8))
                        }
                        .disabled(dataStore.pouches.isEmpty)
                        
                        Button(action: {
                            dataStore.addPouch(strength: dataStore.settings.currentStrength)
                        }) {
                            Text("+")
                                .font(.system(size: 50, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 160, height: 160)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.blue]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(Circle())
                                .shadow(color: .blue.opacity(0.4), radius: 15, x: 0, y: 10)
                        }
                        
                        Color.clear.frame(width: 40, height: 40)
                    }
                }
                
                Spacer()
                
                Button(action: { showingStats = true }) {
                    Text(NSLocalizedString("view_stats", comment: ""))
                        .font(.headline)
                        .foregroundColor(.blue)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                }
                .padding(.bottom, 30)
            }
            .navigationDestination(isPresented: $showingStats) {
                StatsView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
        .accentColor(.blue)
    }
}
