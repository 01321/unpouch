import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var showingSettings = false
    @State private var showingStats = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header Stats
                VStack(spacing: 5) {
                    Text("today")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    let stats = dataStore.getTodayStats()
                    Text("\(stats.count)")
                        .font(.system(size: 60, weight: .bold))
                    
                    Text("\(stats.totalMg) mg")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    // Limit Status
                    let status = dataStore.getLimitStatus()
                    Text(statusText(for: status))
                        .font(.headline)
                        .foregroundColor(statusColor(for: status))
                        .padding(.top, 5)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Controls
                VStack(spacing: 20) {
                    // Strength Selector
                    HStack {
                        Text("strength:")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Menu {
                            ForEach(stride(from: 0, through: 100, by: 10), id: \.self) { strength in
                                Button(action: {
                                    // Update logic handled in DataStore if needed, 
                                    // but here we just use it for adding
                                }) {
                                    HStack {
                                        Text("\(strength) mg")
                                        if strength == dataStore.settings.currentStrength {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Text("\(dataStore.settings.currentStrength) mg")
                                    .fontWeight(.semibold)
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                        }
                    }
                    
                    // Add/Remove Buttons
                    HStack(spacing: 30) {
                        // Remove Button
                        Button(action: {
                            dataStore.removeLastPouch()
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.red.opacity(0.8))
                        }
                        .disabled(dataStore.pouches.isEmpty)
                        
                        // Add Button
                        Button(action: {
                            dataStore.addPouch(strength: dataStore.settings.currentStrength)
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.white)
                                .shadow(radius: 5)
                        }
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.blue]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())
                        .shadow(color: Color.blue.opacity(0.4), radius: 10, x: 0, y: 5)
                    }
                    .padding(.bottom, 40)
                }
                
                // Stats Button
                Button(action: {
                    showingStats = true
                }) {
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                        Text("view_stats")
                    }
                    .font(.headline)
                    .foregroundColor(.blue)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("unpouch.")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .environmentObject(dataStore)
            }
            .fullScreenCover(isPresented: $showingStats) {
                StatsView()
                    .environmentObject(dataStore)
            }
        }
    }
    
    func statusText(for status: String) -> String {
        switch status {
        case "limit_reached": return NSLocalizedString("limit_reached", comment: "")
        case "slightly_over": return NSLocalizedString("slightly_over", comment: "")
        case "over": return NSLocalizedString("over_limit", comment: "")
        case "slightly_under": return NSLocalizedString("slightly_under", comment: "")
        case "under": return NSLocalizedString("under_limit", comment: "")
        default: return ""
        }
    }
    
    func statusColor(for status: String) -> Color {
        switch status {
        case "limit_reached": return .orange
        case "slightly_over": return .orange
        case "over": return .red
        case "slightly_under": return .yellow
        case "under": return .green
        default: return .gray
        }
    }
}

// Extension to handle currentStrength in Settings since we moved it
extension Settings {
    var currentStrength: Int {
        get { UserDefaults.standard.integer(forKey: "currentStrength") != 0 ? UserDefaults.standard.integer(forKey: "currentStrength") : 10 }
        set { UserDefaults.standard.set(newValue, forKey: "currentStrength") }
    }
}
