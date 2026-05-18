import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var showStrengthPicker = false
    @State private var showStatsView = false
    @State private var showSettingsView = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    Text("unpouch.")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(action: { showSettingsView = true }) {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                // Today's Stats
                VStack(alignment: .leading, spacing: 10) {
                    Text("Today")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    let todayPouches = dataStore.pouches.filter { Calendar.current.isDateInToday($0.date) }
                    let totalNicotine = Double(todayPouches.reduce(0) { $0 + $1.strength }) / 1000.0
                    
                    HStack {
                        Text("\(todayPouches.count) pouches")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Text("\(String(format: "%.2f", totalNicotine))g nicotine")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(15)
                .padding(.horizontal)
                
                // Limit Status
                VStack(alignment: .leading, spacing: 10) {
                    let todayCount = dataStore.pouches.filter { Calendar.current.isDateInToday($0.date) }.count
                    let limit = dataStore.settings.dailyLimit
                    
                    let statusText: String
                    let statusEmoji: String
                    
                    if todayCount < limit {
                        statusText = "Under limit"
                        statusEmoji = "✅"
                    } else if todayCount == limit {
                        statusText = "At limit"
                        statusEmoji = "⚠️"
                    } else {
                        statusText = "Over limit"
                        statusEmoji = "❌"
                    }
                    
                    Text("\(statusText) \(statusEmoji)")
                        .font(.title3)
                        .fontWeight(.medium)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(15)
                .padding(.horizontal)
                
                Spacer()
                
                // Add Pouch Button
                Button(action: { showStrengthPicker = true }) {
                    Text("Add Pouch")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(getThemeColor())
                        .cornerRadius(15)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
                
                // Navigation Link for Stats (swipe left to access)
                NavigationLink(destination: StatsView(), isActive: $showStatsView) {
                    EmptyView()
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .sheet(isPresented: $showStrengthPicker) {
                StrengthPickerView(showPicker: $showStrengthPicker)
            }
            .sheet(isPresented: $showSettingsView) {
                SettingsView()
            }
            .gesture(
                DragGesture()
                    .onEnded { value in
                        if value.translation.width < -100 {
                            // Swipe left to open stats
                            showStatsView = true
                        }
                    }
            )
        }
    }
    
    func getThemeColor() -> Color {
        switch dataStore.settings.themeColor {
        case "red": return .red
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        default: return .blue
        }
    }
}

struct StrengthPickerView: View {
    @EnvironmentObject var dataStore: DataStore
    @Binding var showPicker: Bool
    @State private var customStrength: String = ""
    @State private var showCustomInput = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Select Strength")) {
                    ForEach(dataStore.getAvailableStrengths(), id: \.self) { strength in
                        Button(action: {
                            dataStore.addPouch(strength: strength)
                            showPicker = false
                        }) {
                            HStack {
                                Text("\(strength)mg")
                                Spacer()
                                if strength == dataStore.settings.defaultStrength {
                                    Text("Default")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                            }
                        }
                    }
                    
                    Button(action: { showCustomInput = true }) {
                        HStack {
                            Text("Custom...")
                                .foregroundColor(.blue)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Choose Strength")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showPicker = false
                    }
                }
            }
            .alert("Custom Strength", isPresented: $showCustomInput) {
                TextField("Enter mg (e.g., 25)", text: $customStrength)
                    .keyboardType(.numberPad)
                Button("Cancel", role: .cancel) {}
                Button("Add") {
                    if let strength = Int(customStrength), strength > 0 {
                        dataStore.addCustomStrength(strength)
                        dataStore.addPouch(strength: strength)
                        showPicker = false
                    }
                }
            } message: {
                Text("Enter a custom strength in mg")
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(DataStore())
}
