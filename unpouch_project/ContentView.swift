import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var showSettings = false
    @State private var showStats = false
    @State private var showStrengthPicker = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Top Stats Section
                VStack(spacing: 10) {
                    Text("today")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    let stats = dataStore.getTodayStats()
                    
                    Text("\(stats.count)")
                        .font(.system(size: 60, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("\(stats.totalMg) mg")
                        .font(.title)
                        .fontWeight(.medium)
                        .foregroundColor(.gray)
                    
                    // Limit Status
                    LimitStatusView(count: stats.count, limit: dataStore.settings.dailyLimit)
                }
                .padding(.top, 20)
                
                Spacer()
                
                // Controls Section
                VStack(spacing: 20) {
                    // Strength Selector Button
                    Button(action: {
                        showStrengthPicker = true
                    }) {
                        HStack {
                            Image(systemName: "bolt.fill")
                            Text("\(dataStore.settings.currentStrength) mg")
                                .fontWeight(.semibold)
                        }
                        .font(.headline)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(15)
                    }
                    .sheet(isPresented: $showStrengthPicker) {
                        StrengthPickerView()
                            .environmentObject(dataStore)
                    }
                    
                    // Main Add Button
                    Button(action: {
                        dataStore.addPouch(strength: dataStore.settings.currentStrength)
                    }) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.blue.opacity(0.8), Color.cyan.opacity(0.9)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 220, height: 220)
                                .shadow(color: .blue.opacity(0.4), radius: 15, x: 0, y: 10)
                            
                            VStack(spacing: 5) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 50))
                                Text("add_pouch")
                                    .font(.title3)
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(.white)
                        }
                    }
                    
                    // Remove Button
                    Button(action: {
                        dataStore.removeLastPouch()
                    }) {
                        HStack {
                            Image(systemName: "minus.circle.fill")
                            Text("remove_last")
                        }
                        .font(.headline)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                
                Spacer()
                
                // Stats Entry Button
                NavigationLink(destination: {
                    StatsView()
                        .environmentObject(dataStore)
                }) {
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                        Text("view_stats")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(15)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .navigationTitle("unpouch.")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(dataStore)
            }
        }
    }
}

struct LimitStatusView: View {
    let count: Int
    let limit: Int
    
    var statusText: String {
        let diff = count - limit
        if diff == 0 {
            return "limit_exact"
        } else if diff > 0 {
            if diff == 1 {
                return "limit_slightly_over"
            } else {
                return "limit_over"
            }
        } else {
            if diff == -1 {
                return "limit_slightly_under"
            } else {
                return "limit_under"
            }
        }
    }
    
    var statusColor: Color {
        let diff = count - limit
        if diff > 1 { return .red }
        if diff == 1 { return .orange }
        if diff == 0 { return .green }
        if diff == -1 { return .blue }
        return .gray
    }
    
    var body: some View {
        Text(statusText)
            .font(.headline)
            .foregroundColor(statusColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(statusColor.opacity(0.1))
            .cornerRadius(20)
    }
}

struct StrengthPickerView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) var dismiss
    
    let strengths = Array(stride(from: 0, through: 100, by: 10))
    
    var body: some View {
        NavigationView {
            List(strengths, id: \.self) { strength in
                Button(action: {
                    dataStore.settings.currentStrength = strength
                    dataStore.save()
                    dismiss()
                }) {
                    HStack {
                        Text("\(strength) mg")
                        Spacer()
                        if dataStore.settings.currentStrength == strength {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("select_strength")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(DataStore())
}
