import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var showingStats = false
    
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
                    // Header Stats
                    VStack(spacing: 5) {
                        Text("today")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.gray)
                        
                        let stats = dataStore.getTodayStats()
                        
                        Text("\(stats.count)")
                            .font(.system(size: 60, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("\(stats.totalMg) mg")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(.gray)
                        
                        // Limit Status
                        HStack {
                            Image(systemName: statusIcon)
                                .foregroundColor(statusColor)
                            Text(statusText)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(statusColor)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(statusColor.opacity(0.1))
                        .cornerRadius(20)
                    }
                    .padding(.top, 20)
                    
                    Spacer()
                    
                    // Strength Selector
                    HStack {
                        Text("strength:")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.gray)
                        
                        Menu {
                            ForEach(Array(stride(from: 0, through: 100, by: 10)), id: \.self) { strength in
                                Button(action: {
                                    withAnimation {
                                        // Just update the current selection logic if needed
                                        // For now, we rely on the button label showing current
                                    }
                                }) {
                                    HStack {
                                        Text("\(strength) mg")
                                        if strength == currentStrength {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Text("\(currentStrength) mg")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .cornerRadius(10)
                        }
                    }
                    .padding(.bottom, 10)
                    
                    // Add Pouch Button
                    Button(action: {
                        dataStore.addPouch(strength: currentStrength)
                    }) {
                        HStack {
                            Image(systemName: "plus")
                                .font(.system(size: 30, weight: .bold))
                            Text("add_pouch")
                                .font(.system(size: 24, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(width: 280, height: 80)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.7)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(40)
                        .shadow(color: Color.blue.opacity(0.4), radius: 10, x: 0, y: 5)
                    }
                    
                    // Remove Button
                    Button(action: {
                        dataStore.removeLastPouch()
                    }) {
                        HStack {
                            Image(systemName: "minus")
                            Text("remove_last")
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.red)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(20)
                    }
                    .disabled(dataStore.pouches.isEmpty)
                    .opacity(dataStore.pouches.isEmpty ? 0.5 : 1.0)
                    
                    // Stats Button
                    Button(action: {
                        showingStats = true
                    }) {
                        HStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                            Text("view_stats")
                        }
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(25)
                    }
                    .padding(.bottom, 20)
                    
                    Spacer()
                }
                
                // Settings Icon (Top Right)
                NavigationLink(destination: SettingsView()) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.gray)
                        .padding(20)
                }
                .position(x: UIScreen.main.bounds.width - 40, y: 60)
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .sheet(isPresented: $showingStats) {
                StatsView()
            }
        }
    }
    
    private var currentStrength: Int {
        // Simple logic: default to 10 or last used? 
        // Since we don't store 'last used strength' separately in settings per request, 
        // we might just default to 10 or allow the user to tap the menu to change it visually.
        // To make the button label dynamic without a separate state, we can use a local @State 
        // but that resets on view reload. 
        // Let's assume a simple default of 10mg for the button label if not tracking last used.
        // Or better, let's add a @State in ContentView to track selected strength for the session.
        return 10 // Placeholder, see note below
    }
    
    private var statusIcon: String {
        let status = dataStore.getLimitStatus()
        switch status {
        case "slightly_over": return "exclamationmark.triangle.fill"
        case "over_limit": return "xmark.circle.fill"
        case "slightly_under": return "arrow.up.right.circle.fill"
        case "limit_reached": return "checkmark.circle.fill"
        default: return "checkmark.seal.fill"
        }
    }
    
    private var statusColor: Color {
        let status = dataStore.getLimitStatus()
        switch status {
        case "slightly_over": return .orange
        case "over_limit": return .red
        case "slightly_under": return .blue
        case "limit_reached": return .green
        default: return .green
        }
    }
    
    private var statusText: String {
        let status = dataStore.getLimitStatus()
        switch status {
        case "slightly_over": return "slightly_over"
        case "over_limit": return "over_limit"
        case "slightly_under": return "slightly_under"
        case "limit_reached": return "limit_reached"
        default: return "under_limit"
        }
    }
}

// We need a state variable for the selected strength in the view
extension ContentView {
    struct ContentViewWithState: View {
        @EnvironmentObject var dataStore: DataStore
        @State private var showingStats = false
        @State private var selectedStrength: Int = 10
        
        var body: some View {
            // ... (This would be the actual implementation if we refactored the struct)
            // Since we can't easily split the struct above without rewriting, 
            // we will rely on the user copying the logic or we fix the single struct.
            // For the generated file, I will rewrite the whole ContentView properly below.
            EmptyView()
        }
    }
}

// REWRITTEN CONTENTVIEW TO INCLUDE STATE FOR STRENGTH
struct ContentViewFinal: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var showingStats = false
    @State private var selectedStrength: Int = 10
    
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
                    // Header Stats
                    VStack(spacing: 5) {
                        Text("today")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.gray)
                        
                        let stats = dataStore.getTodayStats()
                        
                        Text("\(stats.count)")
                            .font(.system(size: 60, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("\(stats.totalMg) mg")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(.gray)
                        
                        // Limit Status
                        HStack {
                            Image(systemName: statusIcon)
                                .foregroundColor(statusColor)
                            Text(statusText)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(statusColor)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(statusColor.opacity(0.1))
                        .cornerRadius(20)
                    }
                    .padding(.top, 20)
                    
                    Spacer()
                    
                    // Strength Selector
                    HStack {
                        Text("strength:")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.gray)
                        
                        Menu {
                            ForEach(Array(stride(from: 0, through: 100, by: 10)), id: \.self) { strength in
                                Button(action: {
                                    selectedStrength = strength
                                }) {
                                    HStack {
                                        Text("\(strength) mg")
                                        if strength == selectedStrength {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Text("\(selectedStrength) mg")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .cornerRadius(10)
                        }
                    }
                    .padding(.bottom, 10)
                    
                    // Add Pouch Button
                    Button(action: {
                        dataStore.addPouch(strength: selectedStrength)
                    }) {
                        HStack {
                            Image(systemName: "plus")
                                .font(.system(size: 30, weight: .bold))
                            Text("add_pouch")
                                .font(.system(size: 24, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(width: 280, height: 80)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.7)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(40)
                        .shadow(color: Color.blue.opacity(0.4), radius: 10, x: 0, y: 5)
                    }
                    
                    // Remove Button
                    Button(action: {
                        dataStore.removeLastPouch()
                    }) {
                        HStack {
                            Image(systemName: "minus")
                            Text("remove_last")
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.red)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(20)
                    }
                    .disabled(dataStore.pouches.isEmpty)
                    .opacity(dataStore.pouches.isEmpty ? 0.5 : 1.0)
                    
                    // Stats Button
                    Button(action: {
                        showingStats = true
                    }) {
                        HStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                            Text("view_stats")
                        }
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(25)
                    }
                    .padding(.bottom, 20)
                    
                    Spacer()
                }
                
                // Settings Icon (Top Right)
                NavigationLink(destination: SettingsView()) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.gray)
                        .padding(20)
                }
                .position(x: UIScreen.main.bounds.width - 40, y: 60)
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .sheet(isPresented: $showingStats) {
                StatsView()
            }
        }
    }
    
    private var statusIcon: String {
        let status = dataStore.getLimitStatus()
        switch status {
        case "slightly_over": return "exclamationmark.triangle.fill"
        case "over_limit": return "xmark.circle.fill"
        case "slightly_under": return "arrow.up.right.circle.fill"
        case "limit_reached": return "checkmark.circle.fill"
        default: return "checkmark.seal.fill"
        }
    }
    
    private var statusColor: Color {
        let status = dataStore.getLimitStatus()
        switch status {
        case "slightly_over": return .orange
        case "over_limit": return .red
        case "slightly_under": return .blue
        case "limit_reached": return .green
        default: return .green
        }
    }
    
    private var statusText: String {
        let status = dataStore.getLimitStatus()
        switch status {
        case "slightly_over": return "slightly_over"
        case "over_limit": return "over_limit"
        case "slightly_under": return "slightly_under"
        case "limit_reached": return "limit_reached"
        default: return "under_limit"
        }
    }
}

// Use this as the main entry point for ContentView
typealias ContentView = ContentViewFinal
